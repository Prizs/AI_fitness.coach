import json
import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

router = APIRouter()
load_dotenv(Path(__file__).resolve().parents[3] / ".env")

GEMINI_TIMEOUT_SEC = 15.0
MAX_HISTORY_TURNS = 20


class ChatTurn(BaseModel):
    role: str = Field(..., pattern="^(user|assistant)$")
    content: str = Field(..., max_length=4000)


class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    history: list[ChatTurn] = Field(default_factory=list, max_length=MAX_HISTORY_TURNS)
    user_goal: str | None = Field(default=None, max_length=120)
    user_level: str | None = Field(default=None, max_length=40)
    allergies: str | None = Field(default=None, max_length=1000)
    injuries: str | None = Field(default=None, max_length=1000)
    motor_disability: str | None = Field(default=None, max_length=1000)
    areas_to_avoid: str | None = Field(default=None, max_length=500)
    rpe_feedback: int | None = Field(default=None, ge=1, le=10)


def _normalize_exercises(raw_exercises) -> list[dict]:
    exercises: list[dict] = []
    if not isinstance(raw_exercises, list):
        return exercises
    for exercise in raw_exercises:
        if not isinstance(exercise, dict):
            continue
        exercises.append(
            {
                "name": str(exercise.get("name") or "Ejercicio"),
                "sets": exercise.get("sets") or 3,
                "reps": str(exercise.get("reps") or "10"),
                "animation_key": str(exercise.get("animation_key") or "generic-exercise"),
                "primary_muscle": str(exercise.get("primary_muscle") or "General"),
                "secondary_muscle": str(exercise.get("secondary_muscle") or "Secundario"),
            }
        )
    return exercises


def _normalize_structured_plan(raw_plan) -> dict | None:
    if not isinstance(raw_plan, dict):
        return None
    exercises = _normalize_exercises(raw_plan.get("exercises"))
    if not exercises:
        return None
    nutrition = raw_plan.get("nutrition")
    if isinstance(nutrition, dict):
        nutrition = {str(k): str(v) for k, v in nutrition.items()}
    else:
        nutrition = {}
    return {
        "day": str(raw_plan.get("day") or "Sesion"),
        "title": str(raw_plan.get("title") or "Sesion"),
        "exercises": exercises,
        "nutrition": nutrition,
    }


def _profile_context(payload: ChatMessage) -> str:
    return (
        f"Meta: {payload.user_goal or 'Rendimiento general'}. "
        f"Nivel: {payload.user_level or 'Intermedio'}. "
        f"Alergias: {payload.allergies or 'Ninguna'}. "
        f"Lesiones: {payload.injuries or 'Ninguna'}. "
        f"Discapacidad motora: {payload.motor_disability or 'Ninguna'}. "
        f"Zonas a evitar: {payload.areas_to_avoid or 'Ninguna'}. "
        f"RPE reportado: {payload.rpe_feedback if payload.rpe_feedback is not None else 'no indicado'}."
    )


def _conversation_history(history: list[ChatTurn]) -> str:
    if not history:
        return "(sin historial previo)"
    lines = []
    for turn in history[-MAX_HISTORY_TURNS:]:
        speaker = "Usuario" if turn.role == "user" else "Coach"
        lines.append(f"{speaker}: {turn.content}")
    return "\n".join(lines)


def _call_gemini_coach(payload: ChatMessage) -> dict:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY no esta configurada.")

    import google.generativeai as genai

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel("gemini-2.5-flash")

    prompt = (
        "Eres un Coach de Fitness y Nutricion. Responde en espanol, de forma tecnica y motivadora.\n"
        "Respeta estrictamente las lesiones, alergias, discapacidad motora y zonas a evitar indicadas: "
        "no propongas ejercicios ni alimentos que las contradigan y aclaralo si aplica.\n"
        "Retorna EXCLUSIVAMENTE un objeto JSON valido con esta estructura:\n"
        "{\n"
        '  "reply": "Respuesta conversacional en texto",\n'
        '  "category": "Categoria del enfoque",\n'
        '  "duration_weeks": 4,\n'
        '  "rest_between_sets_sec": 60,\n'
        '  "progression_rule": "Regla de progresion concreta",\n'
        '  "has_plan": true,\n'
        '  "structured_plan": {\n'
        '     "day": "Lunes",\n'
        '     "title": "Nombre de la sesion",\n'
        '     "exercises": [{"name": "...", "sets": 3, "reps": "12", "animation_key": "squat", "primary_muscle": "...", "secondary_muscle": "..."}],\n'
        '     "nutrition": {"desayuno": "...", "almuerzo": "...", "cena": "..."}\n'
        "  }\n"
        "}\n"
        "Si no corresponde generar una rutina, usa has_plan=false y structured_plan=null. "
        "No diagnostiques ni prescribas tratamientos medicos.\n"
        f"Datos del usuario: {_profile_context(payload)}\n"
        f"Historial de la conversacion:\n{_conversation_history(payload.history)}\n"
        f"Pregunta actual del usuario: {payload.message}\n"
        "Devuelve SOLO JSON."
    )

    response = model.generate_content(
        prompt,
        request_options={"timeout": GEMINI_TIMEOUT_SEC},
    )
    raw = (
        response.text.strip()
        .removeprefix("```json")
        .removeprefix("```")
        .removesuffix("```")
        .strip()
    )
    data = json.loads(raw)
    if not isinstance(data, dict) or not data.get("reply"):
        raise ValueError("Respuesta de Gemini sin campo reply.")

    structured_plan = _normalize_structured_plan(data.get("structured_plan"))
    has_plan = bool(data.get("has_plan")) and structured_plan is not None
    return {
        "provider": "gemini",
        "reply": str(data.get("reply")),
        "category": str(data.get("category") or "Acondicionamiento general"),
        "duration_weeks": int(data.get("duration_weeks") or 4),
        "rest_between_sets_sec": int(data.get("rest_between_sets_sec") or 60),
        "progression_rule": str(
            data.get("progression_rule")
            or "Aumenta la carga solo si completas las series con RPE <= 7."
        ),
        "has_plan": has_plan,
        "structured_plan": structured_plan if has_plan else None,
    }


RATE_LIMIT_ERRORS = ("ResourceExhausted", "TooManyRequests", "QuotaExceeded")
TIMEOUT_ERRORS = ("DeadlineExceeded", "TimeoutError", "ReadTimeout", "ConnectTimeout")


@router.post("/chat")
def chat_with_coach(payload: ChatMessage):
    try:
        return _call_gemini_coach(payload)
    except Exception as error:  # noqa: BLE001 - se reporta al cliente
        print("Coach IA error:", error.__class__.__name__, error)
        if error.__class__.__name__ in RATE_LIMIT_ERRORS:
            raise HTTPException(
                status_code=429,
                detail=(
                    "El Coach IA alcanzo el limite de uso temporal del proveedor. "
                    "Espera unos segundos y vuelve a intentarlo."
                ),
            )
        if error.__class__.__name__ in TIMEOUT_ERRORS:
            raise HTTPException(
                status_code=504,
                detail="El Coach IA tardo demasiado en responder. Intenta de nuevo.",
            )
        raise HTTPException(
            status_code=503,
            detail=(
                "El Coach IA no esta disponible en este momento. "
                "Intenta de nuevo en unos segundos."
            ),
        )