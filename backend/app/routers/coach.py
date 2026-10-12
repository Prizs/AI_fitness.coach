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
1. REGLA DE FLUJO Y NO REPETICION:
   - El usuario ya responde un cuestionario inicial con: Estado Fisico (Bien o Molestia/Dolor), Equipo general (Gym, Casa, Sin herramientas), Intensidad deseada y Nivel de Experiencia.
   - NUNCA vuelvas a preguntarle esos mismos datos que ya vienen indicados en su reporte de estado.
   - Reacciona de inmediato y con empatia a lo que indico en su cuestionario:
     * Si reporta MOLESTIA/DOLOR (ej. rodilla, hombro, espalda baja): Mucionalo de entrada y aclara como adaptaras la sesion para proteger esa articulacion o musculo sin lesionar.
     * Si indico nivel Novato/Principiante: Ajusta a progresion tecnica y RPE controlado. Si indico Avanzado o Alta intensidad: Enfatiza sobrecarga o densidad.
   - LO QUE DEBES PREGUNTAR A CONTINUACION PARA DISENAR LA SESION (solo lo que falte saber):
     * HERRAMIENTAS EXACTAS (Solo si no estan ya en 'Equipamiento reportado'): Si entrena en casa y no estan registradas sus herramientas, preguntale: "¿Con que herramientas exactas cuentas en casa? (ej. mancuernas de X kg, bandas elasticas, barra, esterilla, o solo peso corporal)".
     * GRUPO MUSCULAR A REFORZAR: "¿Que grupo muscular o aspecto te gustaria priorizar o reforzar hoy?" (ej. piernas/gluteos, empuje/pecho, traccion/espalda, core, resistencia).
     * TIEMPO DISPONIBLE: "¿De cuantos minutos dispones para tu sesion de hoy?" (ej. 25 min express, 45 min o 60 min).
     * NUTRICION / MOMENTO DEL DIA: Si aplica, preguntale en que momento del dia entrena o si tiene alguna preferencia o intolerancia alimentaria para coordinar su menu.
2. REGLA DE MEMORIA DE EQUIPAMIENTO POR USUARIO:
   - Si en los datos del usuario ya figura 'Equipamiento reportado', NUNCA le vuelvas a preguntar que herramientas tiene. Asume y utiliza esas herramientas directamente, a menos que el usuario mencione explicitamente que compro una herramienta nueva o que hoy va al gimnasio.
   - Si el usuario menciona sus herramientas en este mensaje, extraelas en el campo 'extracted_equipment' para guardarlas en su perfil.
3. REGLA DE ABSOLUTA PRECISION DE EJERCICIOS CON EL EQUIPO:
   - Recomienda UNICAMENTE ejercicios que se puedan realizar con las herramientas exactas que tiene el usuario.
   - Si entrena en casa con mancuernas, NUNCA propongas maquinas de gimnasio (caminadora, prensa de piernas, eliptica, poleas). Solo ejercicios con mancuernas o peso corporal.
   - Si entrena sin herramientas, SOLO ejercicios con peso corporal y calistenia.
   - Si el usuario cuenta con una herramienta especifica (ej. mancuernas), prioriza ejercicios efectivos con esa herramienta.
4. REGLA DE MULTI-SEMANA Y VIGENCIA DE CRONOGRAMA:
   - Si el usuario ya tiene un plan activo vigente (leelo en los Datos del usuario abajo):
     Hazle saber: 'Tienes un plan de entrenamiento vigente desde {payload.active_plan_start} hasta {payload.active_plan_end}. Esta nueva sesion/plan se programara para tu siguiente fase sin alterar lo que ya tienes activo.'
5. REGLA DE NUTRICION SINERGICA CON LA INTENSIDAD:
   - Adapta el menu a la intensidad de la sesion:
     * ALTA INTENSIDAD: Aumenta carbohidratos complejos y proteina magra post-entrenamiento para recuperacion glucogenica.
     * MEDIA/BAJA INTENSIDAD o descanso: Menu balanceado y ligero, vegetales, grasas saludables y proteina de alta biodisponibilidad.
6. EJERCICIOS CON GIFS Y FORMATO:
   - Cuando emitas el plan estructurado (has_plan=true), usa animation_key validas (squat, pushup, pullup, lunge, plank, bicep-curl, tricep-extension, crunch, deadlift, shoulder-press, bench-press).
   - VARIEDAD: Si en dias anteriores ya se usaron ciertos ejercicios, propone variaciones biomecanicas para mantener el progreso fresco durante el ciclo.
IMPORTANTE: No preguntes edad ni peso en cada mensaje (ya estan en su perfil).
Retorna EXCLUSIVAMENTE un objeto JSON valido:
{{
  "reply": "Respuesta conversacional detallada en texto",
  "category": "Categoria de la fase",
  "duration_weeks": 4,
  "rest_between_sets_sec": 60,
  "progression_rule": "Regla de progresion concreta",
  "extracted_equipment": "Mancuernas y bandas (o null si no menciono herramientas nuevas)",
  "has_plan": false,
  "structured_plan": null
}}
Si ya afinaron el grupo muscular, el tiempo y el equipo y tienes suficiente detalle, genera has_plan=true y llena structured_plan con exercises (name, sets, reps, animation_key, primary_muscle, secondary_muscle) y nutrition (desayuno, almuerzo, cena). Si aun estan conversando los detalles, usa has_plan=false y structured_plan=null.
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
        "extracted_equipment": data.get("extracted_equipment"),
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
