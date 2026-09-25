import json
import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.services.supabase_service import get_supabase_admin_client

router = APIRouter()
load_dotenv(Path(__file__).resolve().parents[3] / ".env")

GEMINI_TIMEOUT_SEC = 20.0


class PlanRequest(BaseModel):
    goal: str = Field(..., min_length=2, max_length=120)
    level: str = Field(..., min_length=2, max_length=40)
    days_per_week: int = Field(..., ge=1, le=7)
    age: int = Field(..., ge=12, le=100)
    weight: float = Field(..., gt=0, le=300)
    health_notes: str | None = Field(default=None, max_length=1000)
    food_allergies: str | None = Field(default=None, max_length=1000)
    current_injuries: str | None = Field(default=None, max_length=1000)
    motor_disability: str | None = Field(default=None, max_length=1000)
    areas_to_avoid: str | None = Field(default=None, max_length=500)
    learning_consent: bool = False


class PlanFeedback(BaseModel):
    plan_provider: str = Field(..., max_length=30)
    rating: int = Field(..., ge=1, le=5)
    restriction_category: str | None = Field(default=None, max_length=40)
    safe_outcome: bool = False
    learning_consent: bool = False


def _fallback_plan(payload: PlanRequest) -> dict:
    avoids_lower = (payload.areas_to_avoid or "").lower()
    injuries_lower = (payload.current_injuries or "").lower()
    avoid_lower_body = any(term in f"{avoids_lower} {injuries_lower}" for term in ("tobillo", "rodilla", "cadera", "pierna"))
    sessions = [
        {"day": "Día 1", "title": "Fuerza total", "exercises": [
            {"name": "Press de pecho en pared", "sets": 3, "reps": "10", "animation_key": "wall-chest-press"},
            {"name": "Flexiones inclinadas", "sets": 3, "reps": "8-12", "animation_key": "incline-push-up"},
        ]},
        {"day": "Día 2", "title": "Movilidad y core", "exercises": [
            {"name": "Press de hombros sentado", "sets": 3, "reps": "10", "animation_key": "seated-shoulder-press"},
            {"name": "Plancha frontal", "sets": 3, "reps": "20-30 s", "animation_key": "front-plank"},
        ]},
    ]
    return {
        "provider": "fallback",
        "goal": payload.goal,
        "level": payload.level,
        "sessions": sessions[: max(1, min(payload.days_per_week, len(sessions)))],
        "nutrition": [
            {"title": "Desayuno", "items": ["Avena con yogur natural", "Fruta fresca", "Agua"]},
            {"title": "Almuerzo", "items": ["Proteína magra", "Arroz o tubérculo", "Ensalada variada"]},
            {"title": "Cena", "items": ["Proteína ligera", "Verduras", "Porción moderada de carbohidrato"]},
            {"title": "Merienda", "items": ["Fruta", "Yogur natural sin ingredientes alergénicos declarados"]},
        ],
        "constraints_applied": {
            "food_allergies": payload.food_allergies,
            "current_injuries": payload.current_injuries,
            "motor_disability": payload.motor_disability,
            "areas_to_avoid": payload.areas_to_avoid,
            "lower_body_restricted": avoid_lower_body,
        },
        "safety_note": "Plan general orientativo. Suspende si aparece dolor y consulta a un profesional de salud.",
    }


def _normalize_meals(raw_nutrition) -> list[dict]:
    """Convierte cualquier forma de respuesta de nutricion en una lista de comidas.

    El contrato que consume Flutter es: [{"title": str, "items": [str, ...]}].
    """
    meals: list[dict] = []
    if isinstance(raw_nutrition, list):
        for entry in raw_nutrition:
            if isinstance(entry, dict):
                title = entry.get("title") or entry.get("meal") or entry.get("name") or "Comida"
                items = entry.get("items") or entry.get("description") or entry.get("foods")
                if isinstance(items, str):
                    items = [items]
                if not isinstance(items, list):
                    items = []
                meals.append({"title": str(title), "items": [str(i) for i in items]})
            elif isinstance(entry, str):
                meals.append({"title": "Comida", "items": [entry]})
    elif isinstance(raw_nutrition, dict):
        for title, value in raw_nutrition.items():
            if isinstance(value, list):
                items = [str(v) for v in value]
            elif value is None:
                items = []
            else:
                items = [str(value)]
            meals.append({"title": str(title), "items": items})
    return meals


def _normalize_sessions(raw_sessions) -> list[dict]:
    """Garantiza que sessions sea una lista de dias con ejercicios bien formados."""
    sessions: list[dict] = []
    if not isinstance(raw_sessions, list):
        return sessions
    for index, entry in enumerate(raw_sessions, start=1):
        if not isinstance(entry, dict):
            continue
        exercises = entry.get("exercises")
        normalized_exercises: list[dict] = []
        if isinstance(exercises, list):
            for exercise in exercises:
                if not isinstance(exercise, dict):
                    continue
                normalized_exercises.append(
                    {
                        "name": str(exercise.get("name") or exercise.get("exercise") or "Ejercicio"),
                        "sets": exercise.get("sets") or exercise.get("series") or 3,
                        "reps": str(exercise.get("reps") or exercise.get("repetitions") or "10"),
                        "animation_key": str(exercise.get("animation_key") or "generic-exercise"),
                        "primary_muscle": str(exercise.get("primary_muscle") or "General"),
                        "secondary_muscle": str(exercise.get("secondary_muscle") or "Secundario"),
                    }
                )
        sessions.append(
            {
                "day": str(entry.get("day") or f"Dia {index}"),
                "title": str(entry.get("title") or entry.get("focus") or "Sesion"),
                "exercises": normalized_exercises,
            }
        )
    return sessions


def _ai_plan(payload: PlanRequest) -> dict | None:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return None
    try:
        import google.generativeai as genai

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-2.5-flash")
        prompt = f"""Genera un plan fitness y nutricional seguro en JSON valido.
Objetivo: {payload.goal}; nivel: {payload.level}; dias: {payload.days_per_week}; edad: {payload.age}; peso: {payload.weight}; notas: {payload.health_notes or 'ninguna'}; alergias alimentarias: {payload.food_allergies or 'ninguna'}; lesiones: {payload.current_injuries or 'ninguna'}; discapacidad motora: {payload.motor_disability or 'ninguna'}; zonas a evitar: {payload.areas_to_avoid or 'ninguna'}.
Devuelve exactamente provider, goal, level, sessions, nutrition y safety_note.
"sessions" DEBE ser una lista de objetos con las claves day, title y exercises (lista de objetos con name, sets, reps, animation_key, primary_muscle, secondary_muscle).
"nutrition" DEBE ser una lista de objetos con las claves title e items (lista de textos).
No diagnostiques ni prescribas tratamientos."""
        response = model.generate_content(
            prompt,
            request_options={"timeout": GEMINI_TIMEOUT_SEC},
        )
        text = response.text.strip().removeprefix("```json").removesuffix("```").strip()
        plan = json.loads(text)
        sessions = _normalize_sessions(plan.get("sessions"))
        meals = _normalize_meals(plan.get("nutrition"))
        if not sessions or not meals:
            return None
        plan["provider"] = "gemini"
        plan["sessions"] = sessions
        plan["nutrition"] = meals
        plan["safety_note"] = plan.get("safety_note") or (
            "Plan general orientativo. Suspende si aparece dolor y consulta a un profesional de salud."
        )
        return plan
    except Exception:
        return None


@router.post("/generate")
def generate_plan(payload: PlanRequest):
    return _ai_plan(payload) or _fallback_plan(payload)


@router.post("/feedback")
def record_feedback(payload: PlanFeedback):
    if payload.learning_consent:
        get_supabase_admin_client().table("aprendizaje_plan_anonimo").insert(
            {
                "proveedor": payload.plan_provider,
                "categoria_restriccion": payload.restriction_category,
                "calificacion": payload.rating,
                "resultado_seguro": payload.safe_outcome,
            }
        ).execute()
    return {
        "recorded": payload.learning_consent,
        "scope": "anonymous_aggregate" if payload.learning_consent else "disabled",
        "message": "Solo se guardan señales agregadas y no diagnósticos ni texto médico personal.",
    }