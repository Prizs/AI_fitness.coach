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
    active_plan_start: str | None = Field(default=None, max_length=50)
    active_plan_end: str | None = Field(default=None, max_length=50)
    equipment_details: str | None = Field(default=None, max_length=200)


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
    plan_info = ""
    if payload.active_plan_start and payload.active_plan_end:
        plan_info = f" Plan actual vigente desde {payload.active_plan_start} hasta {payload.active_plan_end}."
    equip_info = f" Equipamiento reportado: {payload.equipment_details}." if payload.equipment_details else ""
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
        f"{plan_info}{equip_info}"
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
        f"""Eres un Coach de Fitness y Nutricion altamente interactivo, empatico, cientifico y analitico. Responde en espanol con tono motivador pero riguroso.
REGLAS OBLIGATORIAS DE DISENO Y ADAPTACION:
1. REGLA ESTRICTA DE EQUIPAMIENTO Y HERRAMIENTAS EN CASA:
   - Si el usuario entrena en casa o menciona herramientas especificas (ej. 'solo mancuernas', 'bandas elasticas', 'sin equipo', 'peso corporal'):
   - NUNCA recomiendes maquinas de gimnasio comercial (caminadora, prensa de piernas, maquina Smith, poleas o barras olimpicas) si el usuario entrena en casa.
   - Si el usuario tiene mancuernas, recomienda UNICAMENTE ejercicios con mancuernas o peso corporal (ej: Sentadilla Goblet con mancuerna, Press banca con mancuernas, Zancadas con mancuernas, Peso muerto rumano con mancuernas).
   - Si no tiene herramientas, recomienda 100% peso corporal y calistenia (Sentadillas bulgaras, Flexiones, Plancha, Puente de gluteos, Fondos en silla).
   - Si el usuario dice que tiene herramientas en casa pero no especifica cuales, preguntale de inmediato: '¿Con que herramientas exactas cuentas en casa (ej. mancuernas, bandas, barra, o solo peso corporal)?' y adapta al 100% los ejercicios a esa respuesta.
2. REGLA DE MULTI-SEMANA Y VIGENCIA DE CRONOGRAMA:
   - Si el usuario ya tiene un plan activo vigente (leelo en los Datos del usuario abajo):
     Hazle saber con claridad: 'Tienes un plan de entrenamiento vigente desde {payload.active_plan_start} hasta {payload.active_plan_end}. Diseñaremos esta nueva fase para la proxima semana que inicia despues de esa fecha.'
     Esto le permite programar su siguiente ciclo con anticipacion sin pisar el entrenamiento que esta ejecutando hoy.
3. REGLA DE NUTRICION SINERGICA CON LA INTENSIDAD:
   - Adapta el plan alimenticio a la intensidad de la sesion:
     * Si la sesion es de ALTA INTENSIDAD: Aumenta carbohidratos complejos (avena, arroz, patata) y proteina magra post-entrenamiento para reponer glucogeno y favorecer la sintesis proteica.
     * Si es de INTENSIDAD MEDIA/BAJA o descanso: Plantea un menu mas ligero, rico en vegetales, fibra, grasas saludables y proteina moderada.
4. REGLA DE EXPERIENCIA Y MOLESTIAS/DOLOR:
   - Si reporta MOLESTIA/DOLOR: Abordalo de inmediato; jamas ignores un dolor. Preguntale que movimiento especifico le causa dolor y excluye cualquier ejercicio que comprometa esa articulacion o musculo, o indica descanso si es agudo.
   - Si es principiante/novato: Explicale amablemente la razon de los ejercicios y por que empezamos con tecnica controlada.
5. EJERCICIOS CON GIFS:
   - Cuando emitas el plan estructurado (has_plan=true), usa animation_key validas (squat, pushup, pullup, lunge, plank, bicep-curl, tricep-extension, crunch, deadlift, shoulder-press, bench-press) para que la app muestre sus animaciones correspondientes.
IMPORTANTE: No preguntes edad ni peso en cada mensaje (ya estan en su perfil).
Retorna EXCLUSIVAMENTE un objeto JSON valido:
{{
  "reply": "Respuesta conversacional detallada en texto",
  "category": "Categoria de la fase",
  "duration_weeks": 4,
  "rest_between_sets_sec": 60,
  "progression_rule": "Regla de progresion concreta",
  "has_plan": true,
  "structured_plan": {{
     "day": "Lunes",
     "title": "Nombre de la sesion",
     "exercises": [{{"name": "...", "sets": 3, "reps": "12", "animation_key": "squat", "primary_muscle": "...", "secondary_muscle": "..."}}],
     "nutrition": {{"desayuno": "...", "almuerzo": "...", "cena": "..."}}
  }}
}}
Si aun estan dialogando para afinar el equipo exacto o evaluar una molestia, usa has_plan=false y structured_plan=null.
Datos del usuario: {_profile_context(payload)}
Historial de la conversacion:
{_conversation_history(payload.history)}
Mensaje actual del usuario: {payload.message}
Devuelve SOLO JSON."""
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
