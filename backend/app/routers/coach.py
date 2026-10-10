import json
from pathlib import Path

from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.services.ai_providers import (
    AllProvidersFailed,
    configured_providers,
    generate_json_text,
)

router = APIRouter()
load_dotenv(Path(__file__).resolve().parents[3] / ".env")

AI_TIMEOUT_SEC = 60.0
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
    age: int | None = Field(default=None, ge=12, le=100)
    weight: float | None = Field(default=None, gt=0, le=300)


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
        f"Edad: {payload.age if payload.age is not None else 'No indicada'}. "
        f"Peso: {payload.weight if payload.weight is not None else 'No indicado'} kg. "
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


def _call_ai_coach(payload: ChatMessage) -> dict:
    if not configured_providers():
        raise AllProvidersFailed({})

    prompt = (
        "Eres un Coach de Fitness y Nutricion altamente interactivo y empatico. Responde en espanol, de forma tecnica y motivadora.\n"
        "REGLA DE ORO: Si el usuario te pide una rutina de entrenamiento, GENERALO INMEDIATAMENTE. NO le preguntes como se siente, ni que equipo tiene, ni su nivel. "
        "Simplemente asume que esta bien y genera el 'structured_plan' (has_plan: true) con ejercicios que tengan sentido para su peticion. "
        "El sistema ya tiene una interfaz grafica (botones) que le preguntara al usuario si tiene dolor, equipo o intensidad JUSTO ANTES de guardarlo. Por lo tanto, tu unico trabajo es escupir el plan propuesto sin hacerle preguntas de vuelta.\n"
        "IMPORTANTE: El usuario ya proporciono su EDAD y PESO en su perfil (leelos en los Datos del usuario abajo). NO le preguntes su edad ni su peso.\n"
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

    result = generate_json_text(prompt, timeout=AI_TIMEOUT_SEC)
    data = json.loads(result.text)
    if not isinstance(data, dict) or not data.get("reply"):
        raise ValueError("Respuesta del proveedor de IA sin campo reply.")

    structured_plan = _normalize_structured_plan(data.get("structured_plan"))
    has_plan = bool(data.get("has_plan")) and structured_plan is not None
    return {
        "provider": result.provider,
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
        return _call_ai_coach(payload)
    except AllProvidersFailed as error:
        print("Coach IA: todos los proveedores fallaron:", error)
        raise HTTPException(
            status_code=503,
            detail=(
                "Ningun proveedor de IA pudo responder. Revisa las claves de IA "
                "en el servidor o intenta de nuevo en unos segundos."
            ),
        )
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
