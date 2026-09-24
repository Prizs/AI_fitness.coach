import json
import os

from fastapi import APIRouter
from pydantic import BaseModel, Field

router = APIRouter()


class PlanRequest(BaseModel):
    goal: str = Field(..., min_length=2, max_length=120)
    level: str = Field(..., min_length=2, max_length=40)
    days_per_week: int = Field(..., ge=1, le=7)
    age: int = Field(..., ge=12, le=100)
    weight: float = Field(..., gt=0, le=300)
    health_notes: str | None = Field(default=None, max_length=1000)


def _fallback_plan(payload: PlanRequest) -> dict:
    sessions = [
        {"day": "Día 1", "title": "Fuerza total", "exercises": [
            {"name": "Sentadilla con peso corporal", "sets": 3, "reps": "10", "animation_key": "bodyweight-squat"},
            {"name": "Flexiones inclinadas", "sets": 3, "reps": "8-12", "animation_key": "incline-push-up"},
        ]},
        {"day": "Día 2", "title": "Movilidad y core", "exercises": [
            {"name": "Puente de glúteos", "sets": 3, "reps": "12", "animation_key": "glute-bridge"},
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
            {"title": "Merienda", "items": ["Fruta", "Yogur o frutos secos sin sal"]},
        ],
        "safety_note": "Plan general orientativo. Si tienes una condición médica, consulta a un profesional.",
    }


def _ai_plan(payload: PlanRequest) -> dict | None:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return None
    try:
        import google.generativeai as genai

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-1.5-flash")
        prompt = f"""Genera un plan fitness y nutricional seguro en JSON valido.
Objetivo: {payload.goal}; nivel: {payload.level}; dias: {payload.days_per_week}; edad: {payload.age}; peso: {payload.weight}; notas: {payload.health_notes or 'ninguna'}.
Devuelve exactamente provider, goal, level, sessions, nutrition y safety_note.
Cada ejercicio debe tener name, sets, reps y animation_key en kebab-case. No diagnostiques ni prescribas tratamientos."""
        response = model.generate_content(prompt)
        text = response.text.strip().removeprefix("```json").removesuffix("```").strip()
        plan = json.loads(text)
        plan["provider"] = "gemini"
        return plan
    except Exception:
        return None


@router.post("/generate")
def generate_plan(payload: PlanRequest):
    return _ai_plan(payload) or _fallback_plan(payload)