"""Cadena de proveedores de IA con failover.

Proveedores gratuitos (sin tarjeta de credito) y accesibles desde Venezuela:

1. Google Gemini  - `GEMINI_API_KEY`      (mayor calidad)
2. Groq           - `GROQ_API_KEY`        (30 RPM, 1000 RPD, muy rapido)
3. OpenRouter     - `OPENROUTER_API_KEY`  (modelos `:free`)
4. Mistral        - `MISTRAL_API_KEY`     (modo gratuito)

Solo se usan los proveedores cuyas claves esten configuradas en `.env`.
Si todos fallan se lanza `AllProvidersFailed` con el detalle de cada error,
de modo que la API pueda responder un error real y no una respuesta simulada.
"""

from __future__ import annotations

import os
from dataclasses import dataclass

import httpx

GEMINI_TIMEOUT_SEC = 20.0

OPENAI_COMPATIBLE_BASE_URLS = {
    "groq": "https://api.groq.com/openai/v1",
    "openrouter": "https://openrouter.ai/api/v1",
    "mistral": "https://api.mistral.ai/v1",
}

DEFAULT_MODELS = {
    "groq": "openai/gpt-oss-120b",
    "openrouter": "meta-llama/llama-3.3-70b-instruct:free",
    "mistral": "mistral-small-latest",
}

API_KEY_ENV = {
    "gemini": "GEMINI_API_KEY",
    "groq": "GROQ_API_KEY",
    "openrouter": "OPENROUTER_API_KEY",
    "mistral": "MISTRAL_API_KEY",
}

MODEL_ENV = {
    "groq": "GROQ_MODEL",
    "openrouter": "OPENROUTER_MODEL",
    "mistral": "MISTRAL_MODEL",
}

# Orden de intento: primero calidad, luego volumen.
PROVIDER_ORDER = ("gemini", "groq", "openrouter", "mistral")


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


def _model_for(provider: str) -> str:
    return (os.getenv(MODEL_ENV.get(provider, ""), "") or "").strip() or DEFAULT_MODELS[provider]


def _strip_code_fences(text: str) -> str:
    cleaned = text.strip()
    for fence in ("```json", "```"):
        if cleaned.startswith(fence):
            cleaned = cleaned[len(fence):]
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]
    return cleaned.strip()


def _call_gemini(prompt: str, timeout: float) -> str:
    import google.generativeai as genai

    genai.configure(api_key=os.getenv("GEMINI_API_KEY", ""))
    model = genai.GenerativeModel(
        (os.getenv("GEMINI_MODEL", "") or "").strip() or "gemini-2.5-flash"
    )
    response = model.generate_content(
        prompt,
        request_options={"timeout": timeout},
    )
    return _strip_code_fences(response.text or "")


def _call_openai_compatible(provider: str, prompt: str, timeout: float) -> str:
    api_key = os.getenv(API_KEY_ENV[provider], "")
    base_url = OPENAI_COMPATIBLE_BASE_URLS[provider]
    payload = {
        "model": _model_for(provider),
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.4,
    }
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    if provider == "openrouter":
        headers["HTTP-Referer"] = "https://aifitnesscoach.app"
        headers["X-Title"] = "AI Fitness Coach"

    with httpx.Client(timeout=timeout) as client:
        response = client.post(f"{base_url}/chat/completions", json=payload, headers=headers)
        if response.status_code >= 400:
            # Algunos proveedores rechazan `response_format`; reintentamos sin el.
            raise httpx.HTTPStatusError(
                f"{response.status_code}: {response.text[:200]}",
                request=response.request,
                response=response,
            )
        data = response.json()
    choices = data.get("choices") or []
    if not choices:
        raise ValueError("Respuesta sin 'choices'.")
    content = (choices[0].get("message") or {}).get("content")
    if not content:
        raise ValueError("Respuesta sin contenido.")
    return _strip_code_fences(content)


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
