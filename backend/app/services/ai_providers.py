"""Cadena de proveedores de IA con failover.

Proveedores gratuitos (sin tarjeta de credito). El orden de intento se define en
`PROVIDER_ORDER` y solo se usan los que tengan clave configurada en `.env`.

Verificado desde Venezuela el 2026-09-25:

- Google Gemini  - `GEMINI_API_KEY`     accesible, buena calidad, cuota corta.
- OpenRouter     - `OPENROUTER_API_KEY` accesible, ~17 modelos `:free`.
- Mistral        - `MISTRAL_API_KEY`    accesible, modo gratuito.
- Groq           - `GROQ_API_KEY`       devuelve HTTP 403 desde esta red.

Si todos fallan se lanza `AllProvidersFailed` con el detalle de cada error,
de modo que la API pueda responder un error real y no una respuesta simulada.
"""

from __future__ import annotations

import os
import re
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from dotenv import load_dotenv

import httpx

load_dotenv(Path(__file__).resolve().parents[3] / ".env")
load_dotenv()

GEMINI_TIMEOUT_SEC = 25.0

OPENAI_COMPATIBLE_BASE_URLS = {
    "groq": "https://api.groq.com/openai/v1",
    "openrouter": "https://openrouter.ai/api/v1",
    "mistral": "https://api.mistral.ai/v1",
}

DEFAULT_MODELS = {
    "groq": "openai/gpt-oss-120b",
    "openrouter": "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free",
    "mistral": "mistral-small-latest",
}

# Los modelos `:free` de OpenRouter comparten un pool de limite global
# (`upstream_provider_shared_pool`) muy congestionado, asi que fallan de forma
# intermitente con HTTP 429. Se prueban en orden hasta que uno responda.
MODEL_CANDIDATES = {
    "openrouter": (
        "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free",
        "nvidia/nemotron-3.5-super-vl:free",
        "cohere/north-mini-code:free",
    ),
}

API_KEY_ENV = {
    "gemini": "GEMINI_API_KEY",
    "groq": "GROQ_API_KEY",
    "openrouter": "OPENROUTER_API_KEY",
    "mistral": "MISTRAL_API_KEY",
}

MODEL_ENV = {
    "groq": "GROQ_MODEL",
    "openrouter": "OPENROUTER_MODELS",
    "mistral": "MISTRAL_MODEL",
}

# Orden de intento: primero calidad, luego volumen.
#
# Nota sobre Venezuela (verificado 2026-09-25 desde esta red):
#   - Groq responde HTTP 403 en `api.groq.com` incluso sin clave, lo que indica
#     un bloqueo por red/pais. Se deja al final y solo se usa si hay clave.
#   - OpenRouter, Mistral, Cohere y DeepSeek si responden y validan la clave.
#   - Gemini funciona, pero su cuota gratuita se agota con rapidez.
PROVIDER_ORDER = ("gemini", "openrouter", "mistral", "groq")


@dataclass(frozen=True)
class ProviderResult:
    provider: str
    text: str


class AllProvidersFailed(Exception):
    def __init__(self, errors: dict[str, str]) -> None:
        self.errors = errors
        super().__init__(
            "; ".join(f"{name}: {reason}" for name, reason in errors.items())
            or "No hay proveedores de IA configurados."
        )


def configured_providers() -> list[str]:
    return [name for name in PROVIDER_ORDER if (os.getenv(API_KEY_ENV[name]) or "").strip()]


def _model_candidates(provider: str) -> list[str]:
    """Modelos a probar para un proveedor, en orden de preferencia."""
    override = (os.getenv(MODEL_ENV.get(provider, ""), "") or "").strip()
    if override:
        return [model.strip() for model in override.split(",") if model.strip()]
    if provider in MODEL_CANDIDATES:
        return list(MODEL_CANDIDATES[provider])
    return [DEFAULT_MODELS[provider]]


def _strip_code_fences(text: str) -> str:
    if not text:
        return ""
    cleaned = text.strip()
    match = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", cleaned)
    if match:
        cleaned = match.group(1).strip()
    else:
        if cleaned.startswith("```json"):
            cleaned = cleaned[7:].strip()
        elif cleaned.startswith("```"):
            cleaned = cleaned[3:].strip()
        if cleaned.endswith("```"):
            cleaned = cleaned[:-3].strip()
    return cleaned


def _call_gemini(
    prompt: Any,
    timeout_or_key: float | str | None = None,
    model_override: str | None = None,
    *,
    timeout: float | None = None,
    api_key: str | None = None,
    **kwargs: Any,
) -> str:
    resolved_timeout = 15.0
    resolved_key = None

    if isinstance(timeout_or_key, (int, float)):
        resolved_timeout = float(timeout_or_key)
    elif isinstance(timeout_or_key, str) and timeout_or_key:
        resolved_key = timeout_or_key

    if timeout is not None:
        resolved_timeout = float(timeout)
    if api_key is not None:
        resolved_key = api_key

    key = (resolved_key or os.getenv("GEMINI_API_KEY", "")).strip()
    if not key:
        raise RuntimeError("GEMINI_API_KEY no configurada.")

    configured_model = (model_override or os.getenv("GEMINI_MODEL", "") or "").strip()
    raw_candidates = []
    if configured_model and not any(obsolete in configured_model for obsolete in ["2.5-flash", "2.0-flash"]):
        raw_candidates.append(configured_model)
    raw_candidates.extend([
        "gemini-3.5-flash-lite",
        "gemini-flash-lite-latest",
        "gemini-3.1-flash-lite",
        "gemini-2.5-flash-lite",
    ])
    candidates = list(dict.fromkeys(raw_candidates))

    if isinstance(prompt, list):
        formatted = []
        for item in prompt:
            if isinstance(item, dict) and "parts" in item:
                parts = item["parts"]
                clean_parts = [{"text": str(p)} if isinstance(p, str) else p for p in parts]
                formatted.append({"role": item.get("role", "user"), "parts": clean_parts})
            else:
                formatted.append({"parts": [{"text": str(item)}]})
        contents = formatted
    elif isinstance(prompt, dict):
        contents = [{"parts": [{"text": json.dumps(prompt, ensure_ascii=False)}]}]
    else:
        contents = [{"parts": [{"text": str(prompt)}]}]

    payload = {
        "contents": contents,
        "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.4,
        },
    }

    last_err: Exception | None = None
    per_model_timeout = min(max(resolved_timeout / len(candidates), 4.0), 8.0)

    for model_name in candidates:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={key}"
        try:
            with httpx.Client(timeout=per_model_timeout) as client:
                resp = client.post(url, json=payload)
                if resp.status_code == 200:
                    data = resp.json()
                    candidates_res = data.get("candidates") or []
                    if candidates_res:
                        parts = candidates_res[0].get("content", {}).get("parts", [])
                        if parts and "text" in parts[0]:
                            return _strip_code_fences(parts[0]["text"])
                else:
                    last_err = RuntimeError(f"Google Gemini HTTP {resp.status_code}: {resp.text[:120]}")
                    continue
        except Exception as e:
            last_err = e
            continue

    if last_err:
        raise last_err
    raise RuntimeError("No se pudo contactar a Gemini con ningún modelo.")


def _call_openai_compatible(provider: str, prompt: str, timeout: float) -> str:
    """Llama a un proveedor compatible con OpenAI probando sus modelos en orden."""
    api_key = os.getenv(API_KEY_ENV[provider], "")
    base_url = OPENAI_COMPATIBLE_BASE_URLS[provider]
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    if provider == "openrouter":
        headers["HTTP-Referer"] = "https://aifitnesscoach.app"
        headers["X-Title"] = "AI Fitness Coach"

    last_error: Exception | None = None
    per_model_timeout = min(max(timeout / 3, 3.0), 5.0)

    for model in _model_candidates(provider):
        payload = {
            "model": model,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.4,
        }
        try:
            with httpx.Client(timeout=per_model_timeout) as client:
                response = client.post(
                    f"{base_url}/chat/completions", json=payload, headers=headers
                )
                response.raise_for_status()
                data = response.json()
            choices = data.get("choices") or []
            if not choices:
                raise ValueError("Respuesta sin 'choices'.")
            content = (choices[0].get("message") or {}).get("content")
            if not content:
                raise ValueError("Respuesta sin contenido.")
            return _strip_code_fences(content)
        except Exception as error:  # noqa: BLE001 - se prueba el siguiente modelo
            last_error = error
            continue

    raise last_error or RuntimeError("Sin modelos configurados.")


def generate_json_text(prompt: str, *, timeout: float = GEMINI_TIMEOUT_SEC) -> ProviderResult:
    """Intenta cada proveedor configurado respetando un límite de tiempo acumulativo estricto."""
    import time
    deadline = time.time() + timeout
    errors: dict[str, str] = {}
    for provider in configured_providers():
        remaining = deadline - time.time()
        if remaining < 2.0:
            errors[provider] = "timeout acumulado excedido"
            break
        try:
            call_timeout = remaining
            if provider == "gemini":
                text = _call_gemini(prompt, call_timeout)
            else:
                text = _call_openai_compatible(provider, prompt, call_timeout)
            if text:
                return ProviderResult(provider=provider, text=text)
            errors[provider] = "respuesta vacia"
        except Exception as error:  # noqa: BLE001 - se acumula para informar al cliente
            errors[provider] = f"{error.__class__.__name__}: {str(error)[:160]}"
    raise AllProvidersFailed(errors)
