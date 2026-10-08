import hashlib
import json
import time
from pathlib import Path

from dotenv import load_dotenv
from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.services.ai_providers import configured_providers, generate_json_text
from app.services.supabase_service import get_supabase_admin_client
from app.services.weekly_plan import build_weekly_plan

router = APIRouter()
load_dotenv(Path(__file__).resolve().parents[3] / ".env")

GEMINI_TIMEOUT_SEC = 20.0

# Cache de la semana: la app la pide al abrir, asi que se evita regenerarla.
WEEK_CACHE_TTL_SEC = 3600
WEEK_CACHE: dict[str, tuple[float, dict]] = {}


class WeeklyRequest(BaseModel):
    goal: str = Field(default="mejorar condicion fisica", max_length=120)
    level: str = Field(default="intermedio", max_length=40)
    experience_level: str = Field(default="Intermedio", max_length=40)
    intensity_preference: str = Field(default="Medio", max_length=40)
    equipment_available: bool = Field(default=True)
    age: int = Field(default=25, ge=12, le=100)
    weight: float = Field(default=70, gt=0, le=300)
    food_allergies: str | None = Field(default=None, max_length=1000)
    current_injuries: str | None = Field(default=None, max_length=1000)
    areas_to_avoid: str | None = Field(default=None, max_length=500)


class PlanRequest(BaseModel):
    goal: str = Field(..., min_length=2, max_length=120)
    level: str = Field(..., min_length=2, max_length=40)
    days_per_week: int = Field(..., ge=1, le=7)
    age: int = Field(..., ge=12, le=100)
    weight: float = Field(..., gt=0, le=300)
    height: float | None = Field(default=None, gt=0, le=260)
    sex: str | None = Field(default=None, max_length=20)
    health_notes: str | None = Field(default=None, max_length=1000)
    food_allergies: str | None = Field(default=None, max_length=1000)
    current_injuries: str | None = Field(default=None, max_length=1000)
    motor_disability: str | None = Field(default=None, max_length=1000)
    areas_to_avoid: str | None = Field(default=None, max_length=500)
    learning_consent: bool = False


# Dias de la semana en el orden que usa el telefono (DateTime.weekday).
WEEKDAY_NAMES = [
    "Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo",
]



class AlternativeRequest(BaseModel):
    current_exercise: str
    target_muscle: str
    goal: str = "mejorar condicion fisica"
    equipment_available: bool = True
\nclass PlanFeedback(BaseModel):
    plan_provider: str = Field(..., max_length=30)
    rating: int = Field(..., ge=1, le=5)
    restriction_category: str | None = Field(default=None, max_length=40)
    safe_outcome: bool = False
    learning_consent: bool = False


# Cache en memoria: evita volver a llamar a la IA cuando el mismo perfil pide
# el plan varias veces seguidas (por ejemplo al abrir Rutinas y Nutricion).
PLAN_CACHE_TTL_SEC = 1800
PLAN_CACHE_MAX_ENTRIES = 50
_PLAN_CACHE: dict[str, tuple[float, dict]] = {}


def _cache_key(payload: PlanRequest) -> str:
    data = payload.model_dump()
    data.pop("learning_consent", None)
    return hashlib.sha256(
        json.dumps(data, sort_keys=True).encode("utf-8")
    ).hexdigest()


def _cached_plan(key: str) -> dict | None:
    entry = _PLAN_CACHE.get(key)
    if entry is None:
        return None
    created_at, plan = entry
    if time.time() - created_at > PLAN_CACHE_TTL_SEC:
        _PLAN_CACHE.pop(key, None)
        return None
    return dict(plan)


def _store_plan(key: str, plan: dict) -> None:
    if len(_PLAN_CACHE) >= PLAN_CACHE_MAX_ENTRIES:
        oldest = min(_PLAN_CACHE.items(), key=lambda item: item[1][0])[0]
        _PLAN_CACHE.pop(oldest, None)
    _PLAN_CACHE[key] = (time.time(), plan)


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
    if not configured_providers():
        return None
    try:
        prompt = f"""Genera un plan fitness y nutricional seguro en JSON valido.
Objetivo: {payload.goal}; nivel: {payload.level}; dias: {payload.days_per_week}; edad: {payload.age}; peso: {payload.weight}; notas: {payload.health_notes or 'ninguna'}; alergias alimentarias: {payload.food_allergies or 'ninguna'}; lesiones: {payload.current_injuries or 'ninguna'}; discapacidad motora: {payload.motor_disability or 'ninguna'}; zonas a evitar: {payload.areas_to_avoid or 'ninguna'}.
Devuelve exactamente provider, goal, level, sessions, nutrition y safety_note.
"sessions" DEBE ser una lista de objetos con las claves day, title y exercises (lista de objetos con name, sets, reps, animation_key, primary_muscle, secondary_muscle).
"nutrition" DEBE ser una lista de objetos con las claves title e items (lista de textos).
No diagnostiques ni prescribas tratamientos."""
        result = generate_json_text(prompt, timeout=GEMINI_TIMEOUT_SEC)
        plan = json.loads(result.text)
        sessions = _normalize_sessions(plan.get("sessions"))
        meals = _normalize_meals(plan.get("nutrition"))
        if not sessions or not meals:
            return None
        plan["provider"] = result.provider
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
    key = _cache_key(payload)
    cached = _cached_plan(key)
    if cached is not None:
        cached["cached"] = True
        return cached

    plan = _ai_plan(payload) or _fallback_plan(payload)
    _store_plan(key, plan)
    return {**plan, "cached": False}


@router.post("/weekly")
def weekly_plan(payload: WeeklyRequest):
    """Devuelve la semana completa: 7 dias con rutina, nutricion y sinergia.

    Es lo que consume el telefono al abrir, para que Rutinas y Nutricion
    muestren el dia actual sin tener que esperar a una IA.
    """
    profile = payload.model_dump()
    key = _cache_key(payload)
    entry = WEEK_CACHE.get(key)
    if entry is not None and time.time() - entry[0] <= WEEK_CACHE_TTL_SEC:
        return {**entry[1], "cached": True}

    week = build_weekly_plan(profile)
    WEEK_CACHE[key] = (time.time(), week)
    return {**week, "cached": False}


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
@router.post("/alternative")
def alternative_exercise(payload: AlternativeRequest):
    from app.services.weekly_plan import get_alternative_exercise
    alt = get_alternative_exercise(payload)
    if alt:
        return alt
    raise HTTPException(status_code=500, detail="No se pudo encontrar una alternativa.")
