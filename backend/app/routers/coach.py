import json
import re
from pathlib import Path

from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.routers.exercises import classify_intensity, get_exercise_gif
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
    role: str = Field(default="user")
    content: str = Field(default="", max_length=20000)


class ChatMessage(BaseModel):
    message: str = Field(default="Hola", max_length=15000)
    history: list[ChatTurn] = Field(default_factory=list)
    user_id: str | None = Field(default=None, max_length=100)
    cedula: str | None = Field(default=None, max_length=50)
    user_goal: str | None = Field(default=None, max_length=5000)
    user_level: str | None = Field(default=None, max_length=500)
    user_intensity: str | None = Field(default=None, max_length=500)
    allergies: str | None = Field(default=None, max_length=3000)
    injuries: str | None = Field(default=None, max_length=3000)
    motor_disability: str | None = Field(default=None, max_length=3000)
    areas_to_avoid: str | None = Field(default=None, max_length=3000)
    rpe_feedback: int | float | None = Field(default=None)
    age: int | float | None = Field(default=None)
    weight: float | int | None = Field(default=None)
    active_plan_start: str | None = Field(default=None, max_length=200)
    active_plan_end: str | None = Field(default=None, max_length=200)
    next_cycle_start: str | None = Field(default=None, max_length=200)
    active_training_days: list[str] | None = Field(default=None)
    user_streak: int | None = Field(default=None)
    total_completed_sessions: int | None = Field(default=None)
    equipment_details: str | None = Field(default=None, max_length=2000)
    user_name: str | None = Field(default=None, max_length=200)
    weekly_metrics: dict | None = Field(default=None)
    is_initial_greeting: bool = Field(default=False)
    today_routine: dict | None = Field(default=None)
    weekly_schedule: list | dict | None = Field(default=None)


def _extract_effective_level_and_intensity(payload: ChatMessage) -> tuple[str, str]:
    """Detecta el nivel de experiencia e intensidad reales a partir del mensaje y del historial sin acoplarlos."""
    combined_user_text = " ".join(
        [t.content for t in payload.history if t.role == "user"] + [payload.message]
    ).lower()

    level = payload.user_level or "Intermedio"
    if any(k in combined_user_text for k in ("principiante", "novato", "iniciando", "empezando", "básico", "basico")):
        level = "Principiante"
    elif any(k in combined_user_text for k in ("avanzado", "experto", "atleta")):
        level = "Avanzado"
    elif "intermedio" in combined_user_text:
        level = "Intermedio"

    intensity = payload.user_intensity or "Media"
    if any(k in combined_user_text for k in (
        "intensidad deseada: baja", "intensidad baja", "nivel de intensidad bajo",
        "intensidad bajo", "suave", "ligero", "baja intensidad", "bajo impacto",
    )):
        intensity = "Baja"
    elif any(k in combined_user_text for k in (
        "intensidad deseada: alta", "intensidad alta", "alta intensidad", "intenso", "pesado",
    )):
        intensity = "Alta"
    elif any(k in combined_user_text for k in ("intensidad deseada: media", "intensidad media", "moderada")):
        intensity = "Media"

    return level, intensity


def _detect_fatigue_and_intensity_calibration(message: str, current_intensity: str) -> tuple[bool, str | None]:
    """Detecta retroalimentación de fatiga o solicitud de ajuste de intensidad sin alterar el nivel de experiencia."""
    msg = (message or "").lower()
    fatigue_keywords = (
        "terminé cansado", "termine cansado", "terminé cansada", "termine cansada",
        "bajemos un poco", "bajemos la intensidad", "muy cansado", "muy cansada",
        "fatiga", "fatigado", "fatigada", "agotado", "agotada", "exhausto", "exhausta",
        "me costó mucho", "me costo mucho", "demasiado pesado", "bajar un poco",
        "bajar intensidad", "descarga", "deload",
    )
    boost_keywords = (
        "siguiente nivel", "subir intensidad", "subamos la intensidad", "muy fácil",
        "muy facil", "quiero más", "quiero mas", "aumentar intensidad", "más pesado",
        "mas pesado", "sube la intensidad",
    )
    repeat_keywords = (
        "fue genial", "repetir intensidad", "mantener intensidad", "misma intensidad",
        "igual intensidad", "la misma intensidad",
    )

    if any(k in msg for k in fatigue_keywords):
        if current_intensity.lower() == "alta":
            return True, "Media"
        return True, "Baja"
    elif any(k in msg for k in boost_keywords):
        if current_intensity.lower() == "baja":
            return False, "Media"
        return False, "Alta"
    elif any(k in msg for k in repeat_keywords):
        return False, current_intensity

    return False, None


def _detect_requested_focus(payload: ChatMessage) -> str | None:
    """Detecta qué zona pidió el usuario dando prioridad al mensaje actual sobre el historial."""
    def _match_focus(txt: str) -> str | None:
        # Si el usuario está eligiendo el complemento para días intermedios, priorizar el complemento elegido
        if any(w in txt for w in ("tren superior", "espalda y pecho", "pecho y espalda", "brazos y espalda")):
            return "tren_superior"
        if any(w in txt for w in ("movilidad", "cardio suave", "bajo impacto", "estiramiento")):
            return "movilidad_cardio"
        if any(w in txt for w in ("abdomen", "abdominal", "core", "estabilidad lumbar")):
            return "core"
        if any(w in txt for w in ("pecho", "pectoral", "empuje")):
            return "pecho"
        if any(w in txt for w in ("espalda", "dorsal", "traccion", "tracción")):
            return "espalda"
        if any(w in txt for w in ("brazo", "brazos", "biceps", "bíceps", "triceps", "tríceps", "hombro")):
            return "brazos_hombros"
        if any(w in txt for w in ("pierna", "piernas", "tren inferior", "gluteo", "glúteo", "cuadriceps", "cuádriceps", "isquio", "femoral")):
            return "piernas"
        return None

    current_msg = (payload.message or "").lower()
    focus = _match_focus(current_msg)
    if focus:
        return focus

    for turn in reversed(payload.history[-4:]):
        if turn.role == "user":
            f = _match_focus(turn.content.lower())
            if f:
                return f
    return None


def _is_complementary_days_request(payload: ChatMessage) -> bool:
    """Detecta si el usuario está respondiendo a la pregunta interactiva para programar los días intermedios (Martes y Jueves)."""
    msg = (payload.message or "").lower()
    return any(
        phrase in msg
        for phrase in (
            "martes y jueves",
            "dias intermedios",
            "días intermedios",
            "relacionarlo con",
            "combinarlo con",
            "combinar con",
            "mientras descansan las piernas",
        )
    )


def _is_pure_greeting_or_conversation(message: str) -> bool:
    """Detecta si el mensaje es un saludo o conversación de cortesía sin solicitud explícita de rutina."""
    msg = (message or "").strip().lower()
    cleaned = re.sub(r"[?!¡¿.,;:()\-_]", " ", msg)
    cleaned = " ".join(cleaned.split())

    # Frases comunes de saludo y cortesía directa
    greeting_phrases = (
        "hola", "buen dia", "buenos dias", "buenas tardes", "buenas noches",
        "que tal", "que tal estas", "como estas", "como te va", "como andas",
        "saludos", "hola coach", "buenas", "hey", "hello", "hi",
        "que mas", "que hubo", "todo bien", "hola buen dia", "hola buenos dias",
        "hola buenas tardes", "hola que tal", "hola como estas", "hola que tal estas",
        "buen dia que tal estas", "buenos dias como estas", "hola buen dia que tal",
    )
    if cleaned in greeting_phrases:
        return True

    # Si empieza con saludo o pregunta de cortesía
    greeting_patterns = [
        r"^hola\b",
        r"^buen(os)?\s+d[ií]as\b",
        r"^buenas\s+(tardes|noches)?\b",
        r"^[¿?]?c[oó]mo\s+(est[aá]s|te\s+va|andas)\b",
        r"^[¿?]?qu[eé]\s+tal\b",
        r"^saludos\b",
    ]
    is_greeting_start = any(re.search(pat, cleaned) for pat in greeting_patterns)
    if is_greeting_start:
        routine_triggers = (
            "rutina", "plan", "ejercicio", "entrenar", "entreno", "dieta", "comida",
            "pierna", "pecho", "espalda", "brazo", "abdomen", "core", "calistenia",
            "pesas", "cardio", "deload", "descarga", "cuestionario", "estado actual",
            "qué me toca", "que me toca", "qué hago", "que hago", "qué entreno", "que entreno",
            "hazme", "dame", "crear", "arma", "diseña"
        )
        if not any(k in cleaned for k in routine_triggers):
            return True

    return False


def _is_explicit_routine_request(message: str) -> bool:
    """Detecta si el usuario está pidiendo explícitamente generar o ver un plan o rutina."""
    msg = (message or "").lower()

    # Si expresa dolor o molestia, es una consulta de salud/rehabilitación, no una orden de rutina
    if any(k in msg for k in ("me duele", "molestia", "dolor", "lesión", "lesion", "tengo dudas", "tengo una duda", "pregunta")):
        return False

    explicit_phrases = (
        "dame la rutina", "dame una rutina", "dame mi rutina", "dame el plan", "dame un plan",
        "arma la rutina", "arma mi rutina", "arma un plan", "armemos la rutina", "armemos el plan",
        "genera la rutina", "genera mi rutina", "generar rutina", "crear rutina", "crear plan",
        "planifiquemos", "planificar mi sesión", "planificar mi sesion", "planificar rutina",
        "qué me toca entrenar", "que me toca entrenar", "qué entreno hoy", "que entreno hoy",
        "ejercicios de hoy", "quiero empezar la rutina", "listo para entrenar", "empecemos el entrenamiento",
        "rutina de piernas", "rutina de pecho", "rutina de espalda", "rutina de brazos",
        "rutina de core", "rutina de tren superior", "rutina complementaria", "rutina de hoy",
        "ver rutina con intensidad ajustada", "ver rutina de alta intensidad", "ver mi rutina para hoy",
        "armar rutina", "armar mi plan", "hacer rutina", "generar mi plan", "planificar la rutina",
        "puedes armarme la rutina", "diseña mi rutina", "diseñame una rutina"
    )
    return any(p in msg for p in explicit_phrases)



BEGINNER_LOW_LEG_EXERCISES = [
    {
        "name": "Sentadilla asistida con peso corporal (Básico)",
        "sets": 3,
        "reps": "10-12",
        "animation_key": "squat",
        "primary_muscle": "Cuádriceps, Glúteos",
        "secondary_muscle": "Core, Estabilizadores",
    },
    {
        "name": "Puente de glúteos en suelo (Glute Bridge - Básico)",
        "sets": 3,
        "reps": "12-15",
        "animation_key": "glute-bridge",
        "primary_muscle": "Glúteos",
        "secondary_muscle": "Isquiotibiales, Core",
    },
    {
        "name": "Zancada estática asistida con peso corporal (Básico)",
        "sets": 3,
        "reps": "8-10 por pierna",
        "animation_key": "lunge",
        "primary_muscle": "Cuádriceps, Glúteos",
        "secondary_muscle": "Isquiotibiales",
    },
    {
        "name": "Curl femoral de pie sin peso (Isquiotibiales - Básico)",
        "sets": 3,
        "reps": "12 por pierna",
        "animation_key": "leg-curl",
        "primary_muscle": "Isquiotibiales",
        "secondary_muscle": "Gemelos",
    },
    {
        "name": "Elevación de talones de pie con peso corporal (Básico)",
        "sets": 3,
        "reps": "15",
        "animation_key": "calf-raise",
        "primary_muscle": "Gemelos",
        "secondary_muscle": "Sóleo, Tobillo",
    },
]

INTERMEDIATE_MID_LEG_EXERCISES = [
    {
        "name": "Sentadilla Goblet con mancuerna (Intermedio)",
        "sets": 4,
        "reps": "10-12",
        "animation_key": "squat",
        "primary_muscle": "Cuádriceps, Glúteos",
        "secondary_muscle": "Core",
    },
    {
        "name": "Prensa de piernas inclinada 45° (Intermedio)",
        "sets": 4,
        "reps": "10-12",
        "animation_key": "leg-press",
        "primary_muscle": "Cuádriceps, Glúteos",
        "secondary_muscle": "Isquiotibiales",
    },
    {
        "name": "Zancadas alternas con mancuernas (Intermedio)",
        "sets": 3,
        "reps": "10 por pierna",
        "animation_key": "lunge",
        "primary_muscle": "Cuádriceps, Glúteos",
        "secondary_muscle": "Isquiotibiales",
    },
    {
        "name": "Curl de isquiotibiales sentado en máquina (Intermedio)",
        "sets": 3,
        "reps": "12",
        "animation_key": "leg-curl",
        "primary_muscle": "Isquiotibiales",
        "secondary_muscle": "Gemelos",
    },
    {
        "name": "Peso muerto rumano con mancuernas (Intermedio)",
        "sets": 3,
        "reps": "10-12",
        "animation_key": "deadlift",
        "primary_muscle": "Isquiotibiales, Glúteos",
        "secondary_muscle": "Espalda baja",
    },
]

ADVANCED_HIGH_LEG_EXERCISES = [
    {
        "name": "Sentadilla profunda con barra libre (Avanzado)",
        "sets": 4,
        "reps": "6-8",
        "animation_key": "squat",
        "primary_muscle": "Cuádriceps, Glúteos",
        "secondary_muscle": "Core, Erectores espinales",
    },
    {
        "name": "Peso muerto rumano con barra (Avanzado)",
        "sets": 4,
        "reps": "8-10",
        "animation_key": "deadlift",
        "primary_muscle": "Isquiotibiales, Glúteos",
        "secondary_muscle": "Cadena posterior",
    },
    {
        "name": "Sentadilla búlgara con carga (Avanzado)",
        "sets": 4,
        "reps": "8-10 por pierna",
        "animation_key": "split-squat",
        "primary_muscle": "Cuádriceps, Glúteo mayor",
        "secondary_muscle": "Estabilizadores de cadera",
    },
    {
        "name": "Curl femoral tumbado en máquina (Avanzado)",
        "sets": 4,
        "reps": "10-12",
        "animation_key": "leg-curl",
        "primary_muscle": "Isquiotibiales",
        "secondary_muscle": "Gemelos",
    },
    {
        "name": "Prensa 45° pesada pies anchos (Avanzado)",
        "sets": 4,
        "reps": "8-10",
        "animation_key": "leg-press",
        "primary_muscle": "Cuádriceps, Glúteos, Aductores",
        "secondary_muscle": "Isquiotibiales",
    },
]


UPPER_BODY_POOLS = {
    "baja": [
        {
            "name": "Flexiones inclinadas con manos apoyadas en banco o pared (Básico)",
            "sets": 3,
            "reps": "10-12",
            "animation_key": "pushup",
            "primary_muscle": "Pectorales, Deltoides Anterior",
            "secondary_muscle": "Tríceps, Core",
        },
        {
            "name": "Remo sentado con banda elástica o tracción controlada (Básico)",
            "sets": 3,
            "reps": "12",
            "animation_key": "row",
            "primary_muscle": "Espalda Media, Dorsal Ancho",
            "secondary_muscle": "Bíceps, Romboides",
        },
        {
            "name": "Press de hombros sentado con banda o peso ligero (Básico)",
            "sets": 3,
            "reps": "10-12",
            "animation_key": "shoulder-press",
            "primary_muscle": "Hombros (Deltoides)",
            "secondary_muscle": "Tríceps, Trapecio",
        },
        {
            "name": "Elevaciones laterales suaves de hombros (Básico)",
            "sets": 3,
            "reps": "12-15",
            "animation_key": "lateral-raise",
            "primary_muscle": "Deltoides Lateral",
            "secondary_muscle": "Trapecio Superior",
        },
        {
            "name": "Curl de bíceps sentado controlado (Básico)",
            "sets": 3,
            "reps": "12",
            "animation_key": "bicep-curl",
            "primary_muscle": "Bíceps Braquial",
            "secondary_muscle": "Antebrazo",
        },
    ],
    "media": [
        {
            "name": "Press de pecho con mancuernas en banco (Intermedio)",
            "sets": 4,
            "reps": "10-12",
            "animation_key": "bench-press",
            "primary_muscle": "Pectoral Mayor",
            "secondary_muscle": "Tríceps, Deltoides Anterior",
        },
        {
            "name": "Remo en polea baja sentado (Intermedio)",
            "sets": 4,
            "reps": "10-12",
            "animation_key": "row",
            "primary_muscle": "Espalda Media, Dorsales",
            "secondary_muscle": "Bíceps, Romboides",
        },
        {
            "name": "Jalón al pecho en polea alta (Intermedio)",
            "sets": 3,
            "reps": "10-12",
            "animation_key": "pulldown",
            "primary_muscle": "Dorsal Ancho",
            "secondary_muscle": "Bíceps",
        },
        {
            "name": "Press militar sentado con mancuernas (Intermedio)",
            "sets": 3,
            "reps": "10-12",
            "animation_key": "shoulder-press",
            "primary_muscle": "Deltoides Anterior y Lateral",
            "secondary_muscle": "Tríceps",
        },
        {
            "name": "Extensión de tríceps en polea alta (Intermedio)",
            "sets": 3,
            "reps": "12",
            "animation_key": "tricep-pushdown",
            "primary_muscle": "Tríceps Braquial",
            "secondary_muscle": "Estabilizadores de hombro",
        },
    ],
    "alta": [
        {
            "name": "Press de banca con barra libre (Avanzado)",
            "sets": 4,
            "reps": "6-8",
            "animation_key": "bench-press",
            "primary_muscle": "Pectoral Mayor, Tríceps",
            "secondary_muscle": "Deltoides Anterior",
        },
        {
            "name": "Dominadas pronas completas (Avanzado)",
            "sets": 4,
            "reps": "8-10",
            "animation_key": "pullup",
            "primary_muscle": "Dorsal Ancho, Espalda Alta",
            "secondary_muscle": "Bíceps, Core",
        },
        {
            "name": "Remo inclinado con barra libre (Avanzado)",
            "sets": 4,
            "reps": "8-10",
            "animation_key": "row",
            "primary_muscle": "Espalda Media, Dorsal Ancho",
            "secondary_muscle": "Erectores Espinales, Bíceps",
        },
        {
            "name": "Press militar con barra (Avanzado)",
            "sets": 4,
            "reps": "8-10",
            "animation_key": "shoulder-press",
            "primary_muscle": "Deltoides, Tríceps",
            "secondary_muscle": "Core",
        },
        {
            "name": "Curl de bíceps con barra olímpica (Avanzado)",
            "sets": 3,
            "reps": "8-10",
            "animation_key": "bicep-curl",
            "primary_muscle": "Bíceps Braquial",
            "secondary_muscle": "Antebrazos",
        },
    ],
}

CORE_POOLS = {
    "baja": [
        {
            "name": "Dead Bug / Estabilización lumbopélvica en suelo (Básico)",
            "sets": 3,
            "reps": "10 por lado",
            "animation_key": "dead-bug",
            "primary_muscle": "Core Profundo, Transverso Abdominal",
            "secondary_muscle": "Estabilizadores Lumbares",
        },
        {
            "name": "Plancha abdominal suave con rodillas apoyadas (Básico)",
            "sets": 3,
            "reps": "25-30 seg",
            "animation_key": "plank",
            "primary_muscle": "Abdomen, Core",
            "secondary_muscle": "Hombros, Glúteos",
        },
        {
            "name": "Crunch abdominal corto controlado en suelo (Básico)",
            "sets": 3,
            "reps": "12-15",
            "animation_key": "crunch",
            "primary_muscle": "Recto Abdominal",
            "secondary_muscle": "Oblicuos",
        },
        {
            "name": "Remo postural sentado con retracción escapular (Básico)",
            "sets": 3,
            "reps": "12",
            "animation_key": "row",
            "primary_muscle": "Espalda Media, Postura Dorsal",
            "secondary_muscle": "Romboides, Core",
        },
    ],
    "media": [
        {
            "name": "Plancha abdominal frontal con toque de hombros (Intermedio)",
            "sets": 3,
            "reps": "35-45 seg",
            "animation_key": "plank",
            "primary_muscle": "Core, Transverso Abdominal",
            "secondary_muscle": "Oblicuos, Deltoides",
        },
        {
            "name": "Dead Bug alterno completo sin apoyo (Intermedio)",
            "sets": 3,
            "reps": "12 por lado",
            "animation_key": "dead-bug",
            "primary_muscle": "Abdomen Profundo, Core",
            "secondary_muscle": "Flexores de Cadera",
        },
        {
            "name": "Crunch abdominal en suelo con pausa isométrica (Intermedio)",
            "sets": 3,
            "reps": "15",
            "animation_key": "crunch",
            "primary_muscle": "Recto Abdominal",
            "secondary_muscle": "Oblicuos",
        },
        {
            "name": "Remo en polea para control postural (Intermedio)",
            "sets": 3,
            "reps": "12",
            "animation_key": "row",
            "primary_muscle": "Espalda Media, Trapecio Medio",
            "secondary_muscle": "Core",
        },
    ],
    "alta": [
        {
            "name": "Plancha abdominal lastrada de alta tensión (Avanzado)",
            "sets": 4,
            "reps": "45-60 seg",
            "animation_key": "plank",
            "primary_muscle": "Core Total, Recto Abdominal",
            "secondary_muscle": "Oblicuos, Serrato",
        },
        {
            "name": "Elevación de piernas colgado en barra (Avanzado)",
            "sets": 4,
            "reps": "10-12",
            "animation_key": "hanging-leg-raise",
            "primary_muscle": "Abdomen Inferior, Core",
            "secondary_muscle": "Agarre, Dorsal",
        },
        {
            "name": "Dead Bug con resistencia isométrica (Avanzado)",
            "sets": 4,
            "reps": "12 por lado",
            "animation_key": "dead-bug",
            "primary_muscle": "Transverso Abdominal",
            "secondary_muscle": "Oblicuos",
        },
        {
            "name": "Remo inclinado pesado para cadena posterior alta (Avanzado)",
            "sets": 4,
            "reps": "8-10",
            "animation_key": "row",
            "primary_muscle": "Espalda Alta, Erectores",
            "secondary_muscle": "Core",
        },
    ],
}

MOBILITY_CARDIO_POOLS = {
    "baja": [
        {
            "name": "Bicicleta estática o marcha suave sin impacto (Básico)",
            "sets": 1,
            "reps": "12-15 min Zona 2",
            "animation_key": "cardio-bike",
            "primary_muscle": "Sistema Cardiovascular, Movilidad",
            "secondary_muscle": "Flujo Sanguíneo de Recuperación",
        },
        {
            "name": "Dead Bug respiratorio de movilidad lumbopélvica (Básico)",
            "sets": 3,
            "reps": "10 lentas",
            "animation_key": "dead-bug",
            "primary_muscle": "Core, Movilidad de Cadera y Hombro",
            "secondary_muscle": "Columna Lumbar",
        },
        {
            "name": "Movilidad escapular y tracción suave con banda (Básico)",
            "sets": 3,
            "reps": "12-15",
            "animation_key": "row",
            "primary_muscle": "Movilidad Torácica, Espalda Alta",
            "secondary_muscle": "Deltoides Posterior",
        },
        {
            "name": "Plancha suave con apoyo para activación postural (Básico)",
            "sets": 3,
            "reps": "25 seg",
            "animation_key": "plank",
            "primary_muscle": "Core, Estabilidad Articular",
            "secondary_muscle": "Cintura Escapular",
        },
    ],
    "media": [
        {
            "name": "Jumping Jacks a ritmo controlado (Intermedio)",
            "sets": 3,
            "reps": "40 seg",
            "animation_key": "cardio",
            "primary_muscle": "Cardio Metabólico, Coordinación",
            "secondary_muscle": "Hombros, Core",
        },
        {
            "name": "Plancha dinámica con rotación torácica (Intermedio)",
            "sets": 3,
            "reps": "10 por lado",
            "animation_key": "plank",
            "primary_muscle": "Movilidad Torácica, Oblicuos",
            "secondary_muscle": "Hombros",
        },
        {
            "name": "Dead Bug fluido de control motor (Intermedio)",
            "sets": 3,
            "reps": "12 por lado",
            "animation_key": "dead-bug",
            "primary_muscle": "Core y Estabilidad Lumbopélvica",
            "secondary_muscle": "Flexores",
        },
        {
            "name": "Remo continuo de resistencia aeróbica (Intermedio)",
            "sets": 3,
            "reps": "15",
            "animation_key": "row",
            "primary_muscle": "Espalda Media, Cardio",
            "secondary_muscle": "Bíceps",
        },
    ],
    "alta": [
        {
            "name": "Burpees atléticos controlados (Avanzado)",
            "sets": 4,
            "reps": "12",
            "animation_key": "burpee",
            "primary_muscle": "Cardio HIIT, Capacidad Metabólica",
            "secondary_muscle": "Pecho, Core, Hombros",
        },
        {
            "name": "Jumping Jacks de alta cadencia (Avanzado)",
            "sets": 4,
            "reps": "60 seg",
            "animation_key": "cardio",
            "primary_muscle": "Sistema Cardiorrespiratorio",
            "secondary_muscle": "Deltoides, Core",
        },
        {
            "name": "Plancha activa de alta tensión (Avanzado)",
            "sets": 4,
            "reps": "45 seg",
            "animation_key": "plank",
            "primary_muscle": "Core Anti-extensión",
            "secondary_muscle": "Hombros",
        },
        {
            "name": "Dominadas o tracción metabólica (Avanzado)",
            "sets": 4,
            "reps": "10",
            "animation_key": "pullup",
            "primary_muscle": "Dorsal Ancho, Acondicionamiento",
            "secondary_muscle": "Bíceps, Core",
        },
    ],
}


def _is_leg_exercise(name: str, primary_muscle: str) -> bool:
    text = f"{name} {primary_muscle}".lower()
    leg_terms = (
        "sentadilla", "squat", "zancada", "desplante", "lunge", "prensa", "leg press",
        "puente", "bridge", "hip thrust", "glute", "glúte", "cuadriceps", "cuádriceps",
        "quad", "isquio", "femoral", "hamstring", "gemelo", "pantorrilla", "talon",
        "talón", "calf", "abduc", "aduc", "pierna", "step", "cajon", "cajón", "peso muerto", "deadlift",
    )
    upper_terms = (
        "pecho", "pectoral", "banca", "bench press", "dominada", "pull up", "jalon",
        "remo", "biceps", "bíceps", "triceps", "tríceps", "press militar", "hombro",
        "deltoides", "antebrazo", "muñeca", "wrist", "crunch", "oblicuo", "tórax", "torax",
    )
    if any(u in text for u in upper_terms) and not any(l in text for l in ("sentadilla", "zancada", "pierna", "isquio", "femoral", "glute", "glúte", "cuadriceps", "cuádriceps", "gemelo")):
        return False
    return any(l in text for l in leg_terms)


def _sanitize_exercise_by_intensity(name: str, intensity_hint: str) -> str:
    """Ajusta el nombre del ejercicio para que coincida de forma coherente con el nivel de intensidad solicitado."""
    lower = name.lower()
    if intensity_hint == "baja":
        if "prensa" in lower or "leg press" in lower:
            return "Sentadilla asistida en silla o cajón con peso corporal"
        if "sentadilla" in lower and ("barra" in lower or "profunda" in lower or "salto" in lower or "búlgara" in lower or "bulgara" in lower):
            return "Sentadilla asistida con peso corporal"
        if "peso muerto" in lower and ("barra" in lower or "pesado" in lower):
            return "Puente de glúteos en suelo (Glute Bridge)"
        if ("isquio" in lower or "femoral" in lower) and ("máquina" in lower or "maquina" in lower or "barra" in lower):
            return "Curl femoral de pie sin peso (Isquiotibiales)"
        if ("zancada" in lower or "lunge" in lower) and ("barra" in lower or "salto" in lower or "mancuerna" in lower):
            return "Zancada estática con peso corporal"
        if "press de banca" in lower and "barra" in lower:
            return "Flexiones inclinadas con manos apoyadas en banco"
        if "dominada" in lower:
            return "Jalón o tracción suave con banda elástica"
    return name


def _normalize_exercises(
    raw_exercises,
    intensity: str = "Media",
    level: str = "Intermedio",
    requested_focus: str | None = None,
) -> list[dict]:
    exercises: list[dict] = []
    if not isinstance(raw_exercises, list):
        return exercises

    intensity_hint = "baja" if (intensity.lower() == "baja" or (level.lower() == "principiante" and intensity.lower() != "alta" and intensity.lower() != "media")) else (
        "alta" if (intensity.lower() == "alta" or level.lower() == "avanzado") else "media"
    )
    forced_label = {
        "baja": "Básico (Intensidad Baja)",
        "media": "Intermedio (Intensidad Media)",
        "alta": "Avanzado (Intensidad Alta)",
    }[intensity_hint]

    leg_pool = (
        BEGINNER_LOW_LEG_EXERCISES
        if intensity_hint == "baja"
        else (ADVANCED_HIGH_LEG_EXERCISES if intensity_hint == "alta" else INTERMEDIATE_MID_LEG_EXERCISES)
    )
    upper_pool = UPPER_BODY_POOLS[intensity_hint]
    core_pool = CORE_POOLS[intensity_hint]
    mobility_pool = MOBILITY_CARDIO_POOLS[intensity_hint]

    for idx, exercise in enumerate(raw_exercises):
        if not isinstance(exercise, dict):
            continue
        raw_name = str(exercise.get("name") or "Ejercicio").strip()
        primary = str(exercise.get("primary_muscle") or "General").strip()
        secondary = str(exercise.get("secondary_muscle") or "Secundario").strip()
        sets_val = exercise.get("sets") or 3
        reps_val = str(exercise.get("reps") or "10-12")
        anim_key = str(exercise.get("animation_key") or "squat")
        replaced_from_pool = False

        # 1. Si el usuario pidió piernas y la IA coló un ejercicio de otra parte, usar pool de piernas
        if requested_focus == "piernas" and not _is_leg_exercise(raw_name, primary):
            fallback_ex = leg_pool[idx % len(leg_pool)]
            raw_name = fallback_ex["name"]
            primary = fallback_ex["primary_muscle"]
            secondary = fallback_ex["secondary_muscle"]
            sets_val = fallback_ex["sets"]
            reps_val = fallback_ex["reps"]
            anim_key = fallback_ex["animation_key"]
            replaced_from_pool = True

        # 2. Si el usuario pidió Tren Superior (o Pecho/Espalda/Brazos) y la IA repitió ejercicios de piernas, usar pool de Tren Superior
        elif requested_focus in ("tren_superior", "pecho", "espalda", "brazos_hombros") and _is_leg_exercise(raw_name, primary):
            fallback_ex = upper_pool[idx % len(upper_pool)]
            raw_name = fallback_ex["name"]
            primary = fallback_ex["primary_muscle"]
            secondary = fallback_ex["secondary_muscle"]
            sets_val = fallback_ex["sets"]
            reps_val = fallback_ex["reps"]
            anim_key = fallback_ex["animation_key"]
            replaced_from_pool = True

        # 3. Si el usuario pidió Core/Abdomen/Postura y la IA repitió ejercicios de piernas, usar pool de Core
        elif requested_focus == "core" and _is_leg_exercise(raw_name, primary):
            fallback_ex = core_pool[idx % len(core_pool)]
            raw_name = fallback_ex["name"]
            primary = fallback_ex["primary_muscle"]
            secondary = fallback_ex["secondary_muscle"]
            sets_val = fallback_ex["sets"]
            reps_val = fallback_ex["reps"]
            anim_key = fallback_ex["animation_key"]
            replaced_from_pool = True

        # 4. Si el usuario pidió Movilidad y Cardio Suave y la IA repitió ejercicios de fuerza de piernas, usar pool de Movilidad y Cardio
        elif requested_focus == "movilidad_cardio" and _is_leg_exercise(raw_name, primary):
            fallback_ex = mobility_pool[idx % len(mobility_pool)]
            raw_name = fallback_ex["name"]
            primary = fallback_ex["primary_muscle"]
            secondary = fallback_ex["secondary_muscle"]
            sets_val = fallback_ex["sets"]
            reps_val = fallback_ex["reps"]
            anim_key = fallback_ex["animation_key"]
            replaced_from_pool = True

        clean_name = _sanitize_exercise_by_intensity(raw_name, intensity_hint)
        gif_meta = get_exercise_gif(clean_name, muscle=primary, intensity=intensity_hint)

        exercises.append(
            {
                "name": clean_name,
                "sets": sets_val,
                "reps": reps_val,
                "animation_key": anim_key,
                "primary_muscle": primary,
                "secondary_muscle": secondary,
                "intensity_level": forced_label,
                "gif_url": gif_meta.get("url") or "",
                "biomechanics": str(
                    (gif_meta.get("biomechanics") if replaced_from_pool else (exercise.get("biomechanics") or gif_meta.get("biomechanics")))
                    or "Movimiento controlado respetando el rango articular."
                ),
                "tempo": str(
                    (gif_meta.get("tempo") if replaced_from_pool else (exercise.get("tempo") or gif_meta.get("tempo")))
                    or "3-1-1"
                ),
                "posture": str(
                    (gif_meta.get("posture") if replaced_from_pool else (exercise.get("posture") or gif_meta.get("posture")))
                    or "Mantén la columna neutra y abdomen activo."
                ),
                "warning": str(
                    (gif_meta.get("warning") if replaced_from_pool else (exercise.get("warning") or gif_meta.get("warning")))
                    or "Detén el ejercicio si sientes dolor articular."
                ),
            }
        )
    return exercises


def _normalize_structured_plan(
    raw_plan,
    intensity: str = "Media",
    level: str = "Intermedio",
    requested_focus: str | None = None,
    is_complementary_days: bool = False,
) -> dict | None:
    if not isinstance(raw_plan, dict):
        return None
    exercises = _normalize_exercises(
        raw_plan.get("exercises"),
        intensity=intensity,
        level=level,
        requested_focus=requested_focus,
    )
    if not exercises:
        return None
    nutrition = raw_plan.get("nutrition")
    if isinstance(nutrition, dict):
        nutrition = {str(k): str(v) for k, v in nutrition.items()}
    else:
        nutrition = {}

    # Determinar días óptimos de entrenamiento respetando 48-72h de recuperación muscular
    if is_complementary_days:
        recommended_days = ["Martes", "Jueves"]
        complementary_days = {
            "Lunes y Miércoles": "Sesión Principal de Piernas (En recuperación muscular 48-72h)",
            "Viernes": "Movilidad o Sesión Integrada Suave",
        }
    else:
        raw_days = raw_plan.get("recommended_days")
        if isinstance(raw_days, list) and raw_days and len(raw_days) <= 3:
            recommended_days = [str(d) for d in raw_days]
        else:
            if level.lower() == "principiante" or intensity.lower() == "baja":
                recommended_days = ["Lunes", "Miércoles"]
            else:
                recommended_days = ["Lunes", "Miércoles", "Viernes"]

        complementary_days = raw_plan.get("complementary_days")
        if not isinstance(complementary_days, dict) or not complementary_days:
            complementary_days = {
                "Martes": "Tren Superior Suave (Espalda/Pecho) o Core",
                "Jueves": "Core, Postura o Movilidad Articular y Cardio Suave",
            }

    raw_title = str(raw_plan.get("title") or "Sesión Personalizada")
    if is_complementary_days or requested_focus in ("tren_superior", "core", "movilidad_cardio"):
        focus_titles = {
            "tren_superior": f"Rutina Complementaria: Tren Superior ({level} · Intensidad {intensity})",
            "core": f"Rutina Complementaria: Core, Abdomen y Postura ({level} · Intensidad {intensity})",
            "movilidad_cardio": f"Rutina Complementaria: Movilidad y Cardio Suave ({level} · Intensidad {intensity})",
        }
        if requested_focus in focus_titles and ("pierna" in raw_title.lower() or is_complementary_days):
            raw_title = focus_titles[requested_focus]

    return {
        "day": "Martes y Jueves (Complemento Intermedio)" if is_complementary_days else f"{' y '.join(recommended_days)} (Alternado 48-72h)",
        "title": raw_title,
        "focus_area": requested_focus or "general",
        "is_complementary_days": is_complementary_days,
        "intensity_summary": f"Nivel {level} · Intensidad {intensity}",
        "recommended_days": recommended_days,
        "complementary_days": complementary_days,
        "recovery_rule": "Descanso obligatorio de 48 a 72 horas para este grupo muscular (nunca entrenar piernas en días seguidos).",
        "exercises": exercises,
        "nutrition": nutrition,
    }


def _profile_context(payload: ChatMessage, effective_level: str, effective_intensity: str) -> str:
    plan_info = ""
    if payload.active_plan_start and payload.active_plan_end:
        active_days_str = ", ".join(payload.active_training_days) if payload.active_training_days else "Lunes, Miércoles y Viernes"
        next_str = payload.next_cycle_start or "el próximo lunes"
        plan_info = (
            f" [CICLO SEMANAL ACTIVO: Vigente del {payload.active_plan_start} al {payload.active_plan_end}. "
            f"Días de entrenamiento programados: {active_days_str}. "
            f"Próxima planificación de ciclo completo: {next_str}. "
            f"REGLA: Si pide generar una nueva rutina, recuérdale que su ciclo actual está activo hasta el {payload.active_plan_end} "
            f"y que el nuevo ciclo completo se podrá planificar a partir de {next_str} para respetar 48-72h de descanso. "
            f"Para esta semana, ofrécele rutinas complementarias para sus días libres (Martes/Jueves: Tren Superior, Core o Movilidad).] "
        )

    today_info = ""
    if payload.today_routine and isinstance(payload.today_routine, dict):
        d_name = payload.today_routine.get("day_name", "Hoy")
        d_focus = payload.today_routine.get("focus") or payload.today_routine.get("title") or "Entrenamiento"
        is_rest = bool(payload.today_routine.get("is_rest", False))
        exs = payload.today_routine.get("exercises") or []
        ex_names = []
        if isinstance(exs, list):
            for e in exs:
                if isinstance(e, dict):
                    ex_names.append(f"{e.get('name', 'Ejercicio')} ({e.get('sets', 3)} series de {e.get('reps', '10-12')})")
                elif isinstance(e, str):
                    ex_names.append(e)
        ex_str = "; ".join(ex_names) if ex_names else "Sin ejercicios pesados"
        if is_rest:
            today_info = f" [ENTRENAMIENTO DE HOY ({d_name}): DÍA DE DESCANSO ACTIVO / RECUPERACIÓN. No tiene sesión de sobrecarga programada para hoy.] "
        else:
            today_info = f" [ENTRENAMIENTO DE HOY ({d_name}): Enfoque '{d_focus}'. Ejercicios estructurados en su plan: {ex_str}.] "

    schedule_info = ""
    if payload.weekly_schedule and isinstance(payload.weekly_schedule, list):
        sched_items = []
        for s in payload.weekly_schedule:
            if isinstance(s, dict):
                dn = s.get("day") or s.get("weekday_name") or ""
                df = s.get("focus") or s.get("title") or ""
                if dn and df:
                    sched_items.append(f"{dn}: {df}")
        if sched_items:
            schedule_info = f" [CRONOGRAMA DE LA SEMANA: {'; '.join(sched_items)}.] "

    equip_info = f" Equipamiento reportado: {payload.equipment_details}." if payload.equipment_details else ""
    return (
        f"Edad: {payload.age if payload.age is not None else 'No indicada'}. "
        f"Peso: {payload.weight if payload.weight is not None else 'No indicado'} kg. "
        f"Meta: {payload.user_goal or 'Rendimiento general'}. "
        f"Nivel de experiencia: {effective_level}. "
        f"Intensidad solicitada: {effective_intensity}. "
        f"Alergias: {payload.allergies or 'Ninguna'}. "
        f"Lesiones: {payload.injuries or 'Ninguna'}. "
        f"Discapacidad motora: {payload.motor_disability or 'Ninguna'}. "
        f"RPE reportado: {payload.rpe_feedback if payload.rpe_feedback is not None else 'no indicado'}. "
        f"Racha actual de entrenamientos completados: {payload.user_streak or 0} sesiones consecutivas. "
        f"Total de sesiones completadas históricas: {payload.total_completed_sessions or 0}."
        f"{plan_info}{today_info}{schedule_info}{equip_info}"
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
    effective_level, effective_intensity = _extract_effective_level_and_intensity(payload)

    # 1. Saludo Contextual y Revisión de Semana Completada con Métricas Reales
    if payload.is_initial_greeting:
        metrics = payload.weekly_metrics or {}
        user_name = payload.user_name or "Atleta"
        adherence = metrics.get("adherence_rate")
        try:
            adherence_float = float(adherence) if adherence is not None else 100.0
            adherence_str = f"{adherence_float:.0f}%"
        except Exception:
            adherence_str = f"{adherence}%" if adherence is not None else "100%"

        completed_sessions = metrics.get("completed_sessions")
        if completed_sessions is None:
            completed_sessions = payload.total_completed_sessions or 0

        date_range = metrics.get("date_range") or (
            f"{payload.active_plan_start} al {payload.active_plan_end}"
            if payload.active_plan_start
            else "la semana recién completada"
        )
        streak = metrics.get("streak")
        if streak is None:
            streak = payload.user_streak or 0

        last_rpe = metrics.get("last_rpe") or payload.rpe_feedback or 7
        last_feeling = metrics.get("last_feeling") or "Con energía"

        greeting_prompt = (
            f"""Eres un Coach de Fitness, Biomecánica y Nutrición empático, científico, motivador y cercano.
Estás iniciando una nueva interacción con el usuario en el módulo 'Coach IA & Adaptación'.
El usuario completó su semana de entrenamiento y estas son sus métricas reales en JSON:
{json.dumps({
    "nombre_usuario": user_name,
    "rango_fechas": date_range,
    "sesiones_completadas": completed_sessions,
    "porcentaje_cumplimiento": adherence_str,
    "racha_actual": f"{streak} sesiones consecutivas",
    "rpe_esfuerzo": last_rpe,
    "sensacion_subjetiva": last_feeling,
    "nivel_experiencia": effective_level,
    "intensidad_actual": effective_intensity,
    "meta_principal": payload.user_goal or "Rendimiento general",
}, ensure_ascii=False, indent=2)}

INSTRUCCIONES OBLIGATORIAS:
1. SALUDO CONTEXTUAL PERSONALIZADO: Saluda a {user_name} por su nombre. Menciona explícitamente sus logros reales de la semana completada ({completed_sessions} sesiones completadas, {adherence_str} de cumplimiento en el período {date_range}). Felicítalo con entusiasmo por su constancia.
2. CONSULTA DE PERCEPCIÓN DE RENDIMIENTO Y FATIGA: Pregúntale cómo sintió su rendimiento, si el volumen/intensidad fue adecuado o si terminó con fatiga muscular acumulada.
3. TRANSICIÓN Y MOTIVACIÓN: Motívalo activamente a iniciar un nuevo ciclo de entrenamiento adaptado a sus metas actuales ({payload.user_goal or 'Rendimiento general'}).
4. BOTONES DE RESPUESTA RÁPIDA (QUICK REPLIES): Proporciona exactamente estas 4 respuestas rápidas para que el usuario responda en un clic:
   - "¡Fue genial, quiero repetir intensidad!"
   - "Terminé cansado, bajemos un poco"
   - "¡Listo para el siguiente nivel!"
   - "Completar mi estado actual"

Retorna EXCLUSIVAMENTE un JSON válido con esta estructura:
{{
  "reply": "Tu saludo personalizado, felicitación con métricas reales, pregunta de rendimiento y motivación al nuevo ciclo.",
  "category": "Revisión Semanal y Adaptación",
  "quick_replies": [
    "¡Fue genial, quiero repetir intensidad!",
    "Terminé cansado, bajemos un poco",
    "¡Listo para el siguiente nivel!",
    "Completar mi estado actual"
  ],
  "suggest_questionnaire": true,
  "has_plan": false,
  "structured_plan": null
}}
Devuelve SOLO JSON."""
        )

        quick_replies = [
            "¡Fue genial, quiero repetir intensidad!",
            "Terminé cansado, bajemos un poco",
            "¡Listo para el siguiente nivel!",
            "Completar mi estado actual",
        ]

        reply_str = None
        category = "Revisión Semanal y Adaptación"
        suggest_q = True
        try:
            if configured_providers():
                res = generate_json_text(greeting_prompt, timeout=AI_TIMEOUT_SEC)
                raw = (res.text or "").strip()
                first_b = raw.find("{")
                last_b = raw.rfind("}")
                if first_b != -1 and last_b > first_b:
                    d = json.loads(raw[first_b:last_b + 1])
                    if isinstance(d, dict):
                        reply_str = d.get("reply")
                        category = d.get("category") or category
                        if isinstance(d.get("quick_replies"), list) and d.get("quick_replies"):
                            quick_replies = d["quick_replies"]
                        suggest_q = bool(d.get("suggest_questionnaire", True))
        except Exception as e:
            print("Aviso: Fallback en saludo contextual de Coach IA:", e)

        if not reply_str:
            reply_str = (
                f"¡Hola, {user_name}! 👋 ¡Qué gran trabajo has hecho!\n\n"
                f"Revisando tus métricas de la semana ({date_range}), completaste con éxito "
                f"**{completed_sessions} sesiones** alcanzando un **{adherence_str} de cumplimiento** "
                f"y una racha de **{streak} sesiones**. ¡Te felicito por esa disciplina!\n\n"
                f"¿Cómo sentiste tu rendimiento y nivel de esfuerzo físico la semana anterior? "
                f"Cuéntame si terminaste con energía o con fatiga acumulada para calibrar a la perfección "
                f"tu nuevo ciclo de entrenamiento adaptado a tu meta de **{payload.user_goal or 'rendimiento general'}**."
            )

        return {
            "provider": "ai",
            "reply": reply_str,
            "category": category,
            "duration_weeks": 4,
            "rest_between_sets_sec": 60,
            "progression_rule": "Monitorea tu fatiga y respeta 48-72h de recuperación muscular.",
            "extracted_equipment": None,
            "suggest_questionnaire": suggest_q,
            "has_plan": False,
            "structured_plan": None,
            "quick_replies": quick_replies,
            "recommended_intensity": None,
            "fatigue_detected": False,
        }

    if not configured_providers():
        raise AllProvidersFailed({})

    is_pure_greeting = _is_pure_greeting_or_conversation(payload.message)
    is_routine_request = _is_explicit_routine_request(payload.message)

    # Si es solo un saludo o cortesía (ej: "Hola buen día, ¿qué tal estás?"), responder conversacionalmente SIN tirar plan
    if is_pure_greeting and not is_routine_request:
        conversation_prompt = (
            f"""Eres un Coach de Fitness, Biomecánica y Nutrición empático, educado, cercano y altamente profesional.
El usuario te acaba de escribir un mensaje de saludo o cortesía: "{payload.message}".

REGLAS OBLIGATORIAS:
1. RESPONDE AL SALUDO Y A LA PREGUNTA CON NATURALIDAD, ENERGÍA Y CORTESÍA HUMANA:
   - Responde amablemente al saludo (por ejemplo: "¡Hola! Muy buen día. Me encuentro excelente, motivado y listo para apoyarte en cada paso de tu entrenamiento.").
   - Interactúa preguntándole cómo se siente el día de hoy, qué energía tiene o en qué desea que lo asesores hoy (planificar su rutina, revisar dudas de técnica o consultar su plan nutricional).
2. ESTÁ ESTRICTAMENTE PROHIBIDO GENERAR UN PLAN DE EJERCICIOS O RUTINA EN ESTE TURNO:
   - El usuario solo te está saludando o preguntando cómo estás. NO le tires una rutina de la nada ni inventes ejercicios no pedidos.
   - Debes poner obligatoriamente:
     "has_plan": false,
     "structured_plan": null
3. BOTONES DE RESPUESTA RÁPIDA (QUICK REPLIES):
   - Proporciona exactamente estos 4 botones de acción para guiar al usuario:
     [
       "💪 Planificar mi sesión de hoy",
       "📋 Completar mi estado actual",
       "🏃 Consultar rutina de cardio/movilidad",
       "🥗 Consultar plan de nutrición"
     ]

Retorna EXCLUSIVAMENTE este JSON:
{{
  "reply": "Tu respuesta conversacional cálida, cordial y motivadora, respondiendo a su saludo y preguntándole qué desea trabajar o cómo se siente hoy.",
  "category": "Interacción Conversacional",
  "quick_replies": [
    "💪 Planificar mi sesión de hoy",
    "📋 Completar mi estado actual",
    "🏃 Consultar rutina de cardio/movilidad",
    "🥗 Consultar plan de nutrición"
  ],
  "suggest_questionnaire": false,
  "has_plan": false,
  "structured_plan": null
}}
Devuelve SOLO JSON."""
        )

        reply_str = None
        category = "Interacción Conversacional"
        quick_replies = [
            "💪 Planificar mi sesión de hoy",
            "📋 Completar mi estado actual",
            "🏃 Consultar rutina de cardio/movilidad",
            "🥗 Consultar plan de nutrición",
        ]

        try:
            res = generate_json_text(conversation_prompt, timeout=AI_TIMEOUT_SEC)
            raw = (res.text or "").strip()
            first_b = raw.find("{")
            last_b = raw.rfind("}")
            if first_b != -1 and last_b > first_b:
                d = json.loads(raw[first_b:last_b + 1])
                if isinstance(d, dict):
                    reply_str = d.get("reply")
                    category = d.get("category") or category
                    if isinstance(d.get("quick_replies"), list) and d.get("quick_replies"):
                        quick_replies = d["quick_replies"]
        except Exception as e:
            print("Aviso: Fallback en saludo conversacional:", e)

        if not reply_str:
            reply_str = (
                "¡Hola! Muy buen día. Me encuentro excelente, motivado y listo para ayudarte a alcanzar tus metas. "
                "¿Cómo te sientes el día de hoy? Cuéntame si deseas planificar tu sesión de entrenamiento, "
                "revisar tu nutrición o resolver cualquier duda que tengas."
            )

        return {
            "provider": "ai",
            "reply": reply_str,
            "category": category,
            "duration_weeks": 4,
            "rest_between_sets_sec": 60,
            "progression_rule": "Monitorea tu técnica y respeta 48-72h de recuperación.",
            "extracted_equipment": None,
            "suggest_questionnaire": False,
            "has_plan": False,
            "structured_plan": None,
            "quick_replies": quick_replies,
            "recommended_intensity": None,
            "fatigue_detected": False,
        }

    # 2. Detección de Fatiga y Calibración de Intensidad (Desacoplada del Nivel)
    fatigue_detected, calibrated_intensity = _detect_fatigue_and_intensity_calibration(payload.message, effective_intensity)
    recommended_intensity = calibrated_intensity
    if calibrated_intensity:
        effective_intensity = calibrated_intensity

    requested_focus = _detect_requested_focus(payload)
    is_complementary = _is_complementary_days_request(payload)

    focus_instruction = {
        "piernas": "PIERNAS Y GLÚTEOS (Cuádriceps, Isquiotibiales, Glúteos y Gemelos). PROHIBIDO incluir ejercicios de pecho, espalda, abdomen o brazos.",
        "tren_superior": "TREN SUPERIOR COMPLEMENTARIO PARA MARTES Y JUEVES (Espalda, Pecho, Hombros y Brazos). ¡ESTÁ ESTRICTAMENTE PROHIBIDO incluir Sentadillas, Puente de Glúteos, Zancadas, Elevación de Talones o cualquier ejercicio de piernas!",
        "core": "CORE, ABDOMEN Y ESTABILIDAD LUMBAR PARA MARTES Y JUEVES (Dead Bug, Plancha, Crunch, Control Postural). ¡ESTÁ ESTRICTAMENTE PROHIBIDO incluir Sentadillas, Puente de Glúteos, Zancadas o cualquier ejercicio de piernas!",
        "movilidad_cardio": "MOVILIDAD ARTICULAR, ESTABILIDAD Y CARDIO SUAVE DE BAJO IMPACTO PARA MARTES Y JUEVES (Bicicleta/Marcha Zona 2, Movilidad Torácica/Escapular, Dead Bug respiratorio, Plancha suave). ¡ESTÁ ESTRICTAMENTE PROHIBIDO repetir Sentadillas, Puente de Glúteos, Zancadas o Elevación de Talones!",
    }.get(requested_focus or "", "el grupo muscular solicitado por el usuario en su último mensaje.")

    fatigue_instruction = ""
    if fatigue_detected:
        fatigue_instruction = (
            f"\n5. DETECCIÓN DE FATIGA MUSCULAR O SOBRECARGA PREVIA:\n"
            f"   - El usuario reporta fatiga acumulada o cansancio. Valida fisiológicamente su estado con empatía.\n"
            f"   - Confírmale que has calibrado la intensidad recomendada a **{effective_intensity}** (fase de deload o descarga activa) para favorecer la supercompensación sin agotar el SNC.\n"
            f"   - ACLARACIÓN OBLIGATORIA: Enfatiza que su **nivel de experiencia ({effective_level}) se mantiene intacto**, ya que regular la intensidad no disminuye su nivel atlético.\n"
            f"   - Todos los ejercicios recomendados deben coincidir rigurosamente con la intensidad **{effective_intensity}**."
        )
    user_msg_lower = (payload.message or "").lower()

    is_rest_request = (
        "me impide entrenar" in user_msg_lower
        or "descanso total" in user_msg_lower
        or "no puedo entrenar hoy" in user_msg_lower
        or "no generes ninguna rutina" in user_msg_lower
        or "pausa o descanso total" in user_msg_lower
        or "reporte de descanso" in user_msg_lower
        or "tomar una pausa o descanso" in user_msg_lower
    )

    is_submission = (
        "mi estado actual para la sesión" in user_msg_lower
        or "mi estado actual para la sesion" in user_msg_lower
        or "📋 mi estado actual" in user_msg_lower
        or is_rest_request
        or ("estado físico:" in user_msg_lower and ("equipo disponible:" in user_msg_lower or "motivo" in user_msg_lower or "decisión" in user_msg_lower))
        or ("estado fisico:" in user_msg_lower and ("equipo disponible:" in user_msg_lower or "motivo" in user_msg_lower or "decision" in user_msg_lower))
    )

    should_generate_plan = (is_routine_request or is_submission or is_complementary) and not is_pure_greeting and not is_rest_request

    # Si el usuario NO está pidiendo explícitamente armar o ver una rutina, responder como un Coach amigo y profesional
    if not should_generate_plan:
        conversational_prompt = (
            f"""Eres un Coach de Fitness, Biomecánica y Nutrición altamente interactivo, empático, analítico y cercano.
Actúas como el entrenador personal, amigo y mentor del usuario. Responde en español con tono motivador, riguroso y cálido.

El usuario te acaba de decir: "{payload.message}".

CONTEXTO DEL ATLETA:
- Nivel de Experiencia: {effective_level}
- Intensidad de Trabajo: {effective_intensity}
- Meta: {payload.user_goal or 'Mejorar condición física y salud'}

REGLAS OBLIGATORIAS:
1. DIÁLOGO, EMPATÍA Y ASESORÍA HUMANA:
   - Responde directamente a lo que el usuario comenta, pregunta o expresa (dudas sobre nutrición, mitos, dolores musculares o articulares, suplementación, técnica biomecánica, motivación o charla casual).
   - Explica con claridad y sustento científico práctico.
   - Si expresa alguna molestia física o lesión, dale recomendaciones de cuidado postural, descanso y prevención.
   - Si consulta de alimentación, recuerda las pautas accesibles de Venezuela (huevos, pollo, carne molida magra, atún, queso blanco llanero, arepa de maíz, arroz blanco, avena, batata, yuca, plátano, cambur criollo. Cero ingredientes importados inaccesibles).
2. ESTRICTAMENTE PROHIBIDO GENERAR UNA RUTINA O LISTA DE EJERCICIOS EN ESTE TURNO:
   - El usuario NO ha solicitado explícitamente armar o ver su rutina hoy. No le tires un plan de entrenamiento de golpe.
   - Resuelve sus dudas, conversa con él y dile amablemente que cuando desee entrenar o planificar su sesión, con mucho gusto la estructurarán.
   - Pon obligatoriamente: "has_plan": false, "structured_plan": null.
3. BOTONES DE RESPUESTA RÁPIDA (QUICK REPLIES):
   - Proporciona entre 3 y 4 botones interactivos útiles acordes al tema para que el usuario continúe la interacción con un toque:
     [
       "💪 Planificar mi sesión de hoy",
       "📋 Completar mi estado actual",
       "🥗 Consultar pautas de nutrición",
       "💬 Tengo otra duda"
     ]

Retorna EXCLUSIVAMENTE este JSON:
{{
  "reply": "Tu respuesta conversacional cálida, profesional y empática.",
  "category": "Asesoría y Diálogo de Coach",
  "suggest_questionnaire": false,
  "has_plan": false,
  "structured_plan": null,
  "quick_replies": [
    "💪 Planificar mi sesión de hoy",
    "📋 Completar mi estado actual",
    "🥗 Consultar pautas de nutrición",
    "💬 Tengo otra duda"
  ]
}}
Devuelve SOLO JSON."""
        )

        reply_str = None
        category = "Asesoría y Diálogo de Coach"
        quick_replies = [
            "💪 Planificar mi sesión de hoy",
            "📋 Completar mi estado actual",
            "🥗 Consultar pautas de nutrición",
            "💬 Tengo otra duda",
        ]
        if fatigue_detected:
            quick_replies = [
                "Ver rutina con intensidad ajustada",
                "Consultar rutina de movilidad/descarga",
                "Completar mi estado actual",
            ]

        try:
            res = generate_json_text(conversational_prompt, timeout=AI_TIMEOUT_SEC)
            raw = (res.text or "").strip()
            first_b = raw.find("{")
            last_b = raw.rfind("}")
            if first_b != -1 and last_b > first_b:
                d = json.loads(raw[first_b:last_b + 1])
                if isinstance(d, dict):
                    reply_str = d.get("reply")
                    category = d.get("category") or category
                    if isinstance(d.get("quick_replies"), list) and d.get("quick_replies"):
                        quick_replies = d["quick_replies"]
        except Exception as e:
            print("Aviso: Fallback en diálogo de Coach IA:", e)

        if not reply_str:
            reply_str = (
                f"¡Hola! Te escucho con total atención. Como tu coach y amigo, estoy aquí para guiarte tanto en "
                f"tus entrenamientos como en tus dudas de técnica, nutrición y recuperación. "
                f"¿En qué aspecto específico te gustaría que nos enfoquemos ahora mismo?"
            )

        return {
            "provider": "ai",
            "reply": reply_str,
            "category": category,
            "duration_weeks": 4,
            "rest_between_sets_sec": 60,
            "progression_rule": "Monitorea tu fatiga y respeta 48-72h de recuperación.",
            "extracted_equipment": None,
            "suggest_questionnaire": False,
            "has_plan": False,
            "structured_plan": None,
            "quick_replies": quick_replies,
            "recommended_intensity": recommended_intensity,
            "fatigue_detected": fatigue_detected,
        }

    prompt = (
        f"""Eres un Coach de Fitness, Biomecánica y Nutrición altamente interactivo, empático, científico y analítico. Responde en español con tono motivador pero riguroso.
REGLAS OBLIGATORIAS DE DISEÑO, BIOMECÁNICA Y PERIODIZACIÓN:
1. ENFOQUE OBLIGATORIO DEL MENSAJE ACTUAL:
   - El usuario en este turno está solicitando enfocarse en: **{focus_instruction}**
   - Si `is_complementary` es `{is_complementary}` (rutina complementaria para Martes y Jueves), TODOS los ejercicios del plan DEBEN ser de esa zona complementaria ({requested_focus}) y NINGUNO puede ser de piernas.

2. REGLA DE CATEGORIZACIÓN POR INTENSIDAD ({effective_level} · Intensidad {effective_intensity}):
   - **Nivel Básico (Intensidad Baja) / Principiante**: Usa EXCLUSIVAMENTE ejercicios básicos de bajo impacto y control motor.
   - **Nivel Intermedio (Intensidad Media)**: Ejercicios con carga moderada, mancuernas, poleas o máquinas guiadas.
   - **Nivel Avanzado (Intensidad Alta)**: Ejercicios compuestos pesados o alta exigencia neuromuscular.
   - REGLA DE DESACOPLAMIENTO: Nivel de experiencia ({effective_level}) e Intensidad ({effective_intensity}) son totalmente independientes.

3. REGLA CIENTÍFICA DE DESCANSO MUSCULAR (48-72 HORAS) E INTERACCIÓN SEMANAL:
   - Si el usuario pidió Piernas: pauta la sesión para **Lunes y Miércoles** (o Lunes, Miércoles y Viernes) explicando las 48-72h de recuperación muscular, y pregúntale con qué grupo complementario quiere combinar los días Martes y Jueves.
   - Si el usuario ya eligió la rutina complementaria para **Martes y Jueves** ({requested_focus}): felicítalo por completar su estructura semanal alternada y entrega los ejercicios específicos de **{requested_focus}** para los días **Martes y Jueves**.

4. REGLA OBLIGATORIA DE NUTRICIÓN ADAPTADA A VENEZUELA (MERCADO LOCAL ACCESIBLE):
   - Todos los planes de alimentación DEBEN usar ingredientes económicos y fáciles de conseguir en Venezuela:
     * Proteínas: huevos (pericos criollos con tomate y cebolla, o sancochados), pechuga o muslos de pollo, carne molida magra, atún, sardinas, queso blanco llanero o paisa.
     * Carbohidratos: arepa de maíz, avena en hojuelas, arroz blanco, caraotas negras, lentejas, frijoles, batata, yuca, plátano verde o maduro (asado o hervido).
     * Frutas y vegetales: cambur, lechosa, patilla, melón, guayaba, tomate, cebolla, pimentón, repollo, pepino, chayota, calabacín y aguacate criollo.
   - PROHIBIDO TERMINANTEMENTE incluir salmón, quinoa, espárragos, semillas de chía, frutos rojos importados ni suplementos costosos.{fatigue_instruction}

Retorna EXCLUSIVAMENTE un objeto JSON válido con esta estructura exacta:
{{
  "reply": "Respuesta conversacional clara acorde a la zona solicitada ({requested_focus or 'general'}) y nivel de intensidad ({effective_intensity})",
  "category": "Categoría de la fase",
  "duration_weeks": 4,
  "rest_between_sets_sec": 60,
  "progression_rule": "Regla de progresión y descanso de 48-72h entre sesiones del mismo grupo muscular",
  "extracted_equipment": null,
  "suggest_questionnaire": false,
  "has_plan": true,
  "structured_plan": {{
    "day": "{'Martes y Jueves' if is_complementary else 'Lunes y Miércoles'}",
    "title": "Rutina personalizada ({effective_level} - Intensidad {effective_intensity})",
    "recommended_days": {json.dumps(['Martes', 'Jueves'] if is_complementary else ['Lunes', 'Miércoles'])},
    "complementary_days": {{
      "Martes": "Tren Superior Suave o Core",
      "Jueves": "Movilidad Articular o Tren Superior"
    }},
    "exercises": [
      {{
        "name": "Nombre exacto del ejercicio de {requested_focus or 'la zona solicitada'} acorde a la intensidad {effective_intensity}",
        "sets": 3,
        "reps": "10-12",
        "animation_key": "generic",
        "primary_muscle": "Músculo principal de {requested_focus or 'la zona'}",
        "secondary_muscle": "Músculo secundario",
        "intensity_level": "Básico (Intensidad Baja)",
        "biomechanics": "Explicación biomecánica concisa del movimiento",
        "posture": "Nota postural clave"
      }}
    ],
    "nutrition": {{
      "desayuno": "...",
      "almuerzo": "...",
      "cena": "..."
    }}
  }}
}}
Datos del usuario: {_profile_context(payload, effective_level, effective_intensity)}
Historial de la conversación:
{_conversation_history(payload.history)}
Mensaje actual del usuario: {payload.message}
Devuelve SOLO JSON."""
    )

    data = None
    provider_name = "ai"
    raw = ""
    try:
        result = generate_json_text(prompt, timeout=AI_TIMEOUT_SEC)
        raw = (result.text or "").strip()
        provider_name = result.provider
        first_brace = raw.find("{")
        last_brace = raw.rfind("}")
        if first_brace != -1 and last_brace > first_brace:
            data = json.loads(raw[first_brace:last_brace + 1])
    except Exception as exc:
        print("Aviso: Proveedores de IA no disponibles o con timeout, activando fallback local inteligente:", exc)
        data = None

    if not isinstance(data, dict):
        reply_clean = re.sub(r"```(?:json)?", "", raw).replace("```", "").strip()
        
        # Seleccionar pool de ejercicios según la zona solicitada e intensidad
        focus_key = requested_focus or "piernas"
        if focus_key == "tren_superior":
            chosen_pool = UPPER_BODY_POOLS.get(intensity_hint, UPPER_BODY_POOLS["media"])
            focus_name = "Tren Superior (Espalda, Pecho y Brazos)"
        elif focus_key == "core":
            chosen_pool = CORE_POOLS.get(intensity_hint, CORE_POOLS["media"])
            focus_name = "Core y Estabilidad Lumbar"
        elif focus_key == "movilidad_cardio":
            chosen_pool = MOBILITY_CARDIO_POOLS.get(intensity_hint, MOBILITY_CARDIO_POOLS["media"])
            focus_name = "Movilidad Articular y Cardio Suave"
        else:
            chosen_pool = leg_pool
            focus_name = "Piernas y Glúteos"

        fallback_exercises = []
        for ex in chosen_pool[:5]:
            fallback_exercises.append({
                "name": ex["name"],
                "sets": ex.get("sets", 3),
                "reps": ex.get("reps", "10-12"),
                "animation_key": ex.get("animation_key", "generic"),
                "primary_muscle": ex.get("primary_muscle", "Músculo principal"),
                "secondary_muscle": ex.get("secondary_muscle", "Estabilizadores"),
                "intensity_level": forced_label,
                "biomechanics": "Mantén trayectoria controlada, retracción escapular y rango de movimiento completo.",
                "posture": "Core activo y columna neutra durante todo el recorrido.",
            })

        data = {
            "reply": reply_clean or (
                f"¡Excelente decisión! He preparado tu plan de sesión enfocado en **{focus_name}**, "
                f"calibrado para tu nivel de experiencia **{effective_level}** a una intensidad **{effective_intensity}**.\n\n"
                f"Recuerda que para optimizar la hipertrofia y adaptación neuromuscular, este grupo muscular requiere entre "
                f"**48 y 72 horas de recuperación** antes de volver a trabajarse."
            ),
            "category": f"Entrenamiento ({effective_level} · Intensidad {effective_intensity})",
            "duration_weeks": 4,
            "rest_between_sets_sec": 60,
            "progression_rule": "Respeta 48-72h de recuperación entre sesiones del mismo grupo muscular.",
            "extracted_equipment": None,
            "suggest_questionnaire": False,
            "has_plan": True,
            "structured_plan": {
                "day": "Martes y Jueves" if is_complementary else "Lunes y Miércoles",
                "title": f"Rutina personalizada: {focus_name} ({effective_level} · Intensidad {effective_intensity})",
                "recommended_days": ["Martes", "Jueves"] if is_complementary else ["Lunes", "Miércoles"],
                "complementary_days": {
                    "Martes": "Tren Superior Suave o Core",
                    "Jueves": "Movilidad Articular o Tren Superior"
                },
                "exercises": fallback_exercises,
                "nutrition": {
                    "desayuno": "2 huevos revueltos con tomate y cebolla (perico criollo), 1 arepa de maíz asada y café o té.",
                    "almuerzo": "150g de pechuga de pollo o carne molida magra, 1 taza de arroz blanco o batata y ensalada fresca.",
                    "cena": "2 huevos sancochados o atún al agua con queso blanco llanero y 1/2 plátano maduro asado."
                }
            }
        }

    structured_plan = _normalize_structured_plan(
        data.get("structured_plan"),
        intensity=effective_intensity,
        level=effective_level,
        requested_focus=requested_focus,
        is_complementary_days=is_complementary,
    )
    has_plan = bool(data.get("has_plan")) and structured_plan is not None and should_generate_plan
    reply_str = str(data.get("reply") or raw or "Entendido, continuamos afinando la rutina.")
    user_msg_lower = (payload.message or "").lower()

    if has_plan and not is_complementary and requested_focus == "piernas":
        lower_reply = reply_str.lower()
        if not any(w in lower_reply for w in ("martes", "combinar", "relacionar", "48", "72")):
            rec_days_txt = " y ".join(structured_plan.get("recommended_days", ["Lunes", "Miércoles"]))
            reply_str += (
                f"\n\n💡 **Recomendación de Periodización Semanal:** Estás pidiendo ejercicios de piernas para la semana, "
                f"pero fisiológicamente no es recomendable hacerlos todos los días seguidos porque el músculo requiere entre **48 y 72 horas de recuperación** "
                f"para evitar fatiga neuromuscular. Lo más óptimo es realizar esta sesión los días **{rec_days_txt}**.\n"
                f"Para los días intermedios (**Martes y Jueves**), podemos relacionarlo con otro grupo muscular complementario. ¿Cuál prefieres?\n"
                f"1️⃣ **Tren Superior Suave (Espalda, Pecho y Brazos)**\n"
                f"2️⃣ **Core, Abdomen y Postura**\n"
                f"3️⃣ **Movilidad Articular y Cardio de Bajo Impacto**"
            )

    if payload.active_plan_start and payload.active_plan_end:
        active_days_str = ", ".join(payload.active_training_days) if payload.active_training_days else "Lunes, Miércoles y Viernes"
        next_cycle = payload.next_cycle_start or "el próximo lunes"
        is_routine_request = any(k in user_msg_lower for k in ("nueva rutina", "otra rutina", "crear rutina", "planifica", "rutina nueva", "nuevo plan"))
        if is_routine_request and not is_complementary:
            lower_reply = reply_str.lower()
            if not any(k in lower_reply for k in ("ciclo activo", "próximo lunes", "proximo lunes", "nuevo ciclo", "planificar un nuevo")):
                reply_str = (
                    f"🗓️ **Estado de tu Plan Semanal:** Tienes un ciclo de entrenamiento activo hasta el **domingo {payload.active_plan_end}**, "
                    f"con sesiones programadas para los días **{active_days_str}**.\n\n"
                    f"⏳ **¿Cuándo podrás planificar un nuevo ciclo general?** Podrás generar un ciclo completo totalmente nuevo a partir del **{next_cycle}**, "
                    f"asegurando la adaptación neuromuscular y el descanso de 48 a 72 horas.\n\n"
                    f"💡 **Para esta semana:** Puedes aprovechar tus días libres con una **rutina complementaria** "
                    f"(Tren Superior, Core o Movilidad) o incorporar la propuesta ajustada a continuación:\n\n"
                    + reply_str
                )

    is_rest_request = (
        "me impide entrenar" in user_msg_lower
        or "descanso total" in user_msg_lower
        or "no puedo entrenar hoy" in user_msg_lower
        or "no generes ninguna rutina" in user_msg_lower
        or "pausa o descanso total" in user_msg_lower
        or "reporte de descanso" in user_msg_lower
        or "tomar una pausa o descanso" in user_msg_lower
    )
    if is_rest_request:
        has_plan = False
        structured_plan = None
        data["category"] = "Recuperación y Descanso"

    is_submission = (
        "mi estado actual para la sesión" in user_msg_lower
        or "mi estado actual para la sesion" in user_msg_lower
        or "📋 mi estado actual" in user_msg_lower
        or is_rest_request
        or ("estado físico:" in user_msg_lower and ("equipo disponible:" in user_msg_lower or "motivo" in user_msg_lower or "decisión" in user_msg_lower))
        or ("estado fisico:" in user_msg_lower and ("equipo disponible:" in user_msg_lower or "motivo" in user_msg_lower or "decision" in user_msg_lower))
    )

    recalibration_keywords = [
        "me equivoqu",
        "arrojame el cuestionario",
        "arrojar cuestionario",
        "volver a llenar",
        "llenar de nuevo",
        "llenar nuevamente",
        "repetir estado",
        "repetir cuestionario",
        "cambiar estado",
        "cambiar respuestas",
        "modificar mi estado",
        "recalibrar estado",
        "decir mi estado actual nuevamente",
        "decir mi estado de nuevo",
        "abrir cuestionario",
        "abre el cuestionario",
    ]
    force_suggest = not is_submission and any(k in user_msg_lower for k in recalibration_keywords)
    if is_submission:
        suggest_q = False
    else:
        suggest_q = bool(data.get("suggest_questionnaire")) or force_suggest

    quick_replies = None
    if fatigue_detected:
        quick_replies = [
            "Ver rutina con intensidad ajustada",
            "Consultar rutina de movilidad/descarga",
            "Completar mi estado actual",
        ]
    elif calibrated_intensity == "Alta":
        quick_replies = [
            "Ver rutina de alta intensidad",
            "Completar mi estado actual",
            "Consultar plan nutricional",
        ]
    elif any(k in user_msg_lower for k in ("fue genial", "repetir intensidad", "misma intensidad")):
        quick_replies = [
            "Ver mi rutina para hoy",
            "Completar mi estado actual",
            "Consultar plan nutricional",
        ]
    elif suggest_q:
        quick_replies = [
            "Completar mi estado actual",
            "Solicitar rutina de hoy",
        ]

    return {
        "provider": provider_name,
        "reply": reply_str,
        "category": str(data.get("category") or f"Entrenamiento ({effective_level} · Intensidad {effective_intensity})"),
        "duration_weeks": int(data.get("duration_weeks") or 4),
        "rest_between_sets_sec": int(data.get("rest_between_sets_sec") or 60),
        "progression_rule": str(
            data.get("progression_rule")
            or "Deja 48 a 72 horas de recuperación antes de repetir el mismo grupo muscular."
        ),
        "extracted_equipment": data.get("extracted_equipment"),
        "suggest_questionnaire": suggest_q,
        "has_plan": has_plan,
        "structured_plan": structured_plan if has_plan else None,
        "quick_replies": quick_replies or data.get("quick_replies"),
        "recommended_intensity": recommended_intensity,
        "fatigue_detected": fatigue_detected,
    }


def _persist_coach_message(
    role: str,
    content: str,
    cedula: str | None = None,
    user_id: str | None = None,
    plan: dict | None = None,
    category: str | None = None,
    rule: str | None = None,
    suggest_questionnaire: bool = False,
    quick_replies: list[str] | None = None,
    recommended_intensity: str | None = None,
):
    try:
        from app.services.supabase_service import get_supabase_admin_client
        admin = get_supabase_admin_client()
        resolved_uuid = None
        if user_id and len(user_id) > 10 and "-" in user_id:
            resolved_uuid = user_id
        elif cedula:
            u_res = admin.table("usuarios").select("id").eq("cedula", cedula).limit(1).execute()
            if u_res.data and len(u_res.data) > 0:
                resolved_uuid = u_res.data[0]["id"]

        row = {
            "cedula": cedula,
            "role": role,
            "content": content,
            "plan": plan,
            "category": category,
            "rule": rule,
            "suggest_questionnaire": bool(suggest_questionnaire),
            "quick_replies": quick_replies,
            "recommended_intensity": recommended_intensity,
        }
        if resolved_uuid:
            row["user_id"] = resolved_uuid

        admin.table("coach_mensajes").insert(row).execute()
    except Exception as e:
        print("Aviso: No se pudo persistir mensaje en coach_mensajes:", e)


RATE_LIMIT_ERRORS = ("ResourceExhausted", "TooManyRequests", "QuotaExceeded")
TIMEOUT_ERRORS = ("DeadlineExceeded", "TimeoutError", "ReadTimeout", "ConnectTimeout")


@router.post("/chat")
def chat_with_coach(payload: ChatMessage):
    try:
        result = _call_ai_coach(payload)
        # Persist messages if user is identified
        if payload.cedula or payload.user_id:
            # Save user prompt (skip internal greeting prompt)
            if not payload.is_initial_greeting:
                _persist_coach_message(
                    role="user",
                    content=payload.message,
                    cedula=payload.cedula,
                    user_id=payload.user_id,
                )
            # Save assistant reply
            reply_text = str(result.get("reply", ""))
            plan_data = result.get("structured_plan") if result.get("has_plan") else None
            _persist_coach_message(
                role="assistant",
                content=reply_text,
                cedula=payload.cedula,
                user_id=payload.user_id,
                plan=plan_data,
                category=result.get("category"),
                rule=result.get("progression_rule"),
                suggest_questionnaire=bool(result.get("suggest_questionnaire", False)),
                quick_replies=result.get("quick_replies"),
                recommended_intensity=result.get("recommended_intensity"),
            )
        return result
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


@router.get("/history")
def get_coach_history(cedula: str | None = None, user_id: str | None = None, limit: int = 50):
    """Recupera el historial de conversación persistente del usuario en el Coach IA."""
    if not cedula and not user_id:
        return []
    try:
        from app.services.supabase_service import get_supabase_admin_client
        admin = get_supabase_admin_client()
        query = admin.table("coach_mensajes").select("*").neq("category", "body_metric")
        if user_id and "-" in user_id:
            query = query.eq("user_id", user_id)
        elif cedula:
            query = query.eq("cedula", cedula)

        res = query.order("created_at", desc=False).limit(limit).execute()
        rows = res.data or []
        formatted = []
        for r in rows:
            formatted.append({
                "id": str(r.get("id")),
                "role": r.get("role", "assistant"),
                "isUser": r.get("role") == "user",
                "text": r.get("content", ""),
                "plan": r.get("plan"),
                "category": r.get("category"),
                "rule": r.get("rule"),
                "suggest_questionnaire": r.get("suggest_questionnaire", False),
                "quick_replies": r.get("quick_replies"),
                "recommended_intensity": r.get("recommended_intensity"),
                "created_at": str(r.get("created_at")),
            })
        return formatted
    except Exception as e:
        print("Error obteniendo historial de coach_mensajes:", e)
        return []


@router.delete("/history")
def delete_coach_history(cedula: str | None = None, user_id: str | None = None):
    """Limpia el historial de conversación del usuario para iniciar una nueva sesión activa."""
    if not cedula and not user_id:
        raise HTTPException(status_code=400, detail="Debe especificar cedula o user_id")
    try:
        from app.services.supabase_service import get_supabase_admin_client
        admin = get_supabase_admin_client()
        query = admin.table("coach_mensajes")
        if user_id and "-" in user_id:
            query = query.delete().eq("user_id", user_id)
        elif cedula:
            query = query.delete().eq("cedula", cedula)
        query.execute()
        return {"status": "ok", "message": "Historial reiniciado exitosamente."}
    except Exception as e:
        print("Error borrando historial de coach:", e)
        raise HTTPException(status_code=500, detail=str(e))


