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
from dataclasses import dataclass

import httpx

GEMINI_TIMEOUT_SEC = 35.0

OPENAI_COMPATIBLE_BASE_URLS = {
    "groq": "https://api.groq.com/openai/v1",
    "openrouter": "https://openrouter.ai/api/v1",
    "mistral": "https://api.mistral.ai/v1",
}

DEFAULT_MODELS = {
    "groq": "openai/gpt-oss-120b",
    "openrouter": "google/gemma-4-31b-it:free",
    "mistral": "mistral-small-latest",
}

# Los modelos `:free` de OpenRouter comparten un pool de limite global
# (`upstream_provider_shared_pool`) muy congestionado, asi que fallan de forma
# intermitente con HTTP 429. Se prueban en orden hasta que uno responda.
MODEL_CANDIDATES = {
    "openrouter": (
        "nvidia/nemotron-3.5-lightning:free",
        "recursive/flint-v1.0:free",
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


def _call_gemini(prompt: str, timeout: float) -> str:
    import google.generativeai as genai

    genai.configure(api_key=os.getenv("GEMINI_API_KEY", ""))
    model = genai.GenerativeModel(
        (os.getenv("GEMINI_MODEL", "") or "").strip() or "gemini-2.5-flash",
        generation_config={"response_mime_type": "application/json"},
    )
    response = model.generate_content(
        prompt,
        request_options={"timeout": timeout},
    )
    return _strip_code_fences(response.text or "")


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
    per_model_timeout = min(max(timeout / 3, 4.0), 8.0)

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
    """Intenta cada proveedor configurado y devuelve el primer texto valido."""
    errors: dict[str, str] = {}
    for provider in configured_providers():
        try:
            if provider == "gemini":
                text = _call_gemini(prompt, timeout)
            else:
                text = _call_openai_compatible(provider, prompt, timeout)
            if text:
                return ProviderResult(provider=provider, text=text)
            errors[provider] = "respuesta vacia"
        except Exception as error:  # noqa: BLE001 - se acumula para informar al cliente
            errors[provider] = f"{error.__class__.__name__}: {str(error)[:160]}"
    raise AllProvidersFailed(errors)
