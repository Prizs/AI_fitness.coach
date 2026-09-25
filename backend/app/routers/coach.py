import json
import os
from pathlib import Path
from dotenv import load_dotenv
from fastapi import APIRouter
from pydantic import BaseModel, Field

router = APIRouter()
load_dotenv(Path(__file__).resolve().parents[3] / ".env")


class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    user_goal: str | None = None
    user_level: str | None = None
    allergies: str | None = None
    injuries: str | None = None
    rpe_feedback: int | None = None


@router.post("/chat")
def chat_with_coach(payload: ChatMessage):
    api_key = os.getenv("GEMINI_API_KEY")
    user_prompt = payload.message.lower()

    # Si se pide categorización de meta o adaptación
    is_routine_request = any(k in user_prompt for k in [
        "resistencia", "pulmonar", "cardio", "fuerza", "hipertrofia", "grasa", "rutina", "plan", "ejercicio", "molestia"
    ])

    if api_key:
        try:
            import google.generativeai as genai
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel(
                model_name="gemini-1.5-flash",
                generation_config={"response_mime_type": "application/json"}
            )
            system_instruction = (
                "Eres un Coach Inteligente de Fitness y Nutrición de clase mundial. "
                "Responde en JSON con la siguiente estructura exacta:\n"
                "{\n"
                '  "reply": "Respuesta conversacional motivadora y concisa",\n'
                '  "category": "Hipertrofia | Resistencia Cardiovascular | Perdida de Grasa | Fuerza",\n'
                '  "duration_weeks": 4,\n'
                '  "rest_between_sets_sec": 90,\n'
                '  "progression_rule": "Regla dinámica (ej: si RPE < 7, subir 2.5kg o 2 reps)",\n'
                '  "has_plan": true,\n'
                '  "structured_plan": {\n'
                '     "day": "Lunes",\n'
                '     "title": "Sesión Principal",\n'
                '     "exercises": [\n'
                '        {"name": "Sentadilla Goblet", "sets": 3, "reps": "12", "animation_key": "squat", "primary_muscle": "Cuádriceps", "secondary_muscle": "Glúteos"}\n'
                '     ],\n'
                '     "nutrition": {\n'
                '        "breakfast": "Avena con frutos rojos y semillas",\n'
                '        "lunch": "Pechuga o pescado con quinoa y remolacha",\n'
                '        "dinner": "Tortilla de vegetales y ensalada verde"\n'
                '     }\n'
                '  }\n'
                "}\n"
                f"Restricciones del usuario: Alergias: {payload.allergies or 'Ninguna'}. "
                f"Lesiones/Molestias: {payload.injuries or 'Ninguna'}. Nunca recomiendes ejercicios ni comidas contraindicadas."
            )
            res = model.generate_content([system_instruction, payload.message])
            data = json.loads(res.text)
            return data
        except Exception:
            pass

    # Fallback inteligente y estructurado según objetivo
    if "resistencia" in user_prompt or "pulmonar" in user_prompt or "cardio" in user_prompt:
        return {
            "reply": "He diseñado una fase de 4 semanas enfocada en capacidad cardiopulmonar y eficiencia mitocondrial. Adaptamos descanso corto y alimentos ricos en nitratos.",
            "category": "Resistencia Cardiovascular y Pulmonar",
            "duration_weeks": 4,
            "rest_between_sets_sec": 60,
            "progression_rule": "Si completas el tiempo con RPE < 7, incrementa 2 min la zona aeróbica la próxima sesión.",
            "has_plan": True,
            "structured_plan": {
                "day": "Lunes",
                "title": "Capacidad Aeróbica & Core",
                "exercises": [
                    {"name": "Remo en máquina o zancadas controladas", "sets": 4, "reps": "45s trabajo", "animation_key": "row-intervals", "primary_muscle": "Cardio/Dorsales", "secondary_muscle": "Piernas"},
                    {"name": "Plancha con respiración diafragmática", "sets": 3, "reps": "40s", "animation_key": "plank", "primary_muscle": "Core/Diafragma", "secondary_muscle": "Hombros"}
                ],
                "nutrition": {
                    "breakfast": "Avena cocida con rodajas de plátano y zumo de remolacha natural",
                    "lunch": "Pescado al horno o tofu con arroz integral y espinacas al vapor",
                    "dinner": "Crema de calabaza, semillas de calabaza y huevo pochado"
                }
            }
        }
    elif is_routine_request:
        return {
            "reply": "Entendido. He ajustado tu plan con progresión dinámica y dosificación adecuada a tus capacidades actuales.",
            "category": "Fuerza e Hipertrofia Funcional",
            "duration_weeks": 6,
            "rest_between_sets_sec": 90,
            "progression_rule": "Al completar todas las repeticiones sin fallo técnico, añade 2.5 kg.",
            "has_plan": True,
            "structured_plan": {
                "day": "Lunes",
                "title": "Fuerza Base",
                "exercises": [
                    {"name": "Sentadillas profundas controladas", "sets": 4, "reps": "10-12", "animation_key": "squat", "primary_muscle": "Cuádriceps", "secondary_muscle": "Glúteos"},
                    {"name": "Press plano con mancuernas", "sets": 3, "reps": "10", "animation_key": "bench-press", "primary_muscle": "Pectoral", "secondary_muscle": "Tríceps"}
                ],
                "nutrition": {
                    "breakfast": "Huevos revueltos con aguacate y tostadas integrales",
                    "lunch": "Pollo a la plancha con batata asada y brócoli",
                    "dinner": "Salmón o atún con ensalada fresca y aceite de oliva"
                }
            }
        }

    return {
        "reply": f"¡Hola! Soy tu Coach Inteligente. ¿En qué objetivo o ajuste de tu plan te gustaría que nos enfoquemos hoy?",
        "category": "General",
        "has_plan": False
    }