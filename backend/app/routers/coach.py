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
    role: str = Field(..., pattern="^(user|assistant)$")
    content: str = Field(..., max_length=4000)


class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    history: list[ChatTurn] = Field(default_factory=list, max_length=MAX_HISTORY_TURNS)
    user_goal: str | None = Field(default=None, max_length=120)
    user_level: str | None = Field(default=None, max_length=40)
    user_intensity: str | None = Field(default=None, max_length=40)
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


def _extract_effective_level_and_intensity(payload: ChatMessage) -> tuple[str, str]:
    """Detecta el nivel de experiencia e intensidad reales a partir del mensaje y del historial."""
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
    elif level == "Principiante" and not payload.user_intensity:
        intensity = "Baja"

    return level, intensity


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

    for idx, exercise in enumerate(raw_exercises):
        if not isinstance(exercise, dict):
            continue
        raw_name = str(exercise.get("name") or "Ejercicio").strip()
        primary = str(exercise.get("primary_muscle") or "General").strip()
        secondary = str(exercise.get("secondary_muscle") or "Secundario").strip()

        # Si el usuario pidió exclusivamente piernas y la IA coló un ejercicio de tren superior/tórax/brazos, reemplazarlo por uno de piernas acorde a la intensidad
        if requested_focus == "piernas" and not _is_leg_exercise(raw_name, primary):
            fallback_ex = leg_pool[idx % len(leg_pool)]
            raw_name = fallback_ex["name"]
            primary = fallback_ex["primary_muscle"]
            secondary = fallback_ex["secondary_muscle"]

        clean_name = _sanitize_exercise_by_intensity(raw_name, intensity_hint)
        gif_meta = get_exercise_gif(clean_name, muscle=primary, intensity=intensity_hint)

        exercises.append(
            {
                "name": clean_name,
                "sets": exercise.get("sets") or 3,
                "reps": str(exercise.get("reps") or "10-12"),
                "animation_key": str(exercise.get("animation_key") or "squat"),
                "primary_muscle": primary,
                "secondary_muscle": secondary,
                "intensity_level": forced_label,
                "gif_url": gif_meta.get("url") or "",
                "biomechanics": str(
                    exercise.get("biomechanics") or gif_meta.get("biomechanics") or "Movimiento controlado respetando el rango articular."
                ),
                "tempo": str(
                    exercise.get("tempo") or gif_meta.get("tempo") or "3-1-1"
                ),
                "posture": str(
                    exercise.get("posture") or gif_meta.get("posture") or "Mantén la columna neutra y abdomen activo."
                ),
                "warning": str(
                    exercise.get("warning") or gif_meta.get("warning") or "Detén el ejercicio si sientes dolor articular."
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

    return {
        "day": "Martes y Jueves (Complemento Intermedio)" if is_complementary_days else f"{' y '.join(recommended_days)} (Alternado 48-72h)",
        "title": str(raw_plan.get("title") or "Sesión Personalizada"),
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
        plan_info = f" Plan actual vigente desde {payload.active_plan_start} hasta {payload.active_plan_end}."
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

    effective_level, effective_intensity = _extract_effective_level_and_intensity(payload)
    requested_focus = _detect_requested_focus(payload)

    prompt = (
        f"""Eres un Coach de Fitness, Biomecánica y Nutrición altamente interactivo, empático, científico y analítico. Responde en español con tono motivador pero riguroso.
REGLAS OBLIGATORIAS DE DISEÑO, BIOMECÁNICA Y PERIODIZACIÓN:
1. REGLA DE FLUJO Y NO REPETICIÓN:
   - El usuario ya responde un cuestionario inicial con: Estado Físico (Bien o Molestia/Dolor), Equipo general (Gym, Casa, Sin herramientas), Intensidad deseada ({effective_intensity}) y Nivel de Experiencia ({effective_level}).
   - NUNCA vuelvas a preguntarle esos mismos datos que ya vienen indicados en su reporte de estado.
   - Si reporta MOLESTIA/DOLOR: Menciónalo de entrada y aclara cómo adaptarás la sesión (o si pidió pausa/descanso total, NO generes rutina de ejercicios y da solo pautas de recuperación y alerta médica).

2. REGLA DE ABSOLUTA PRECISIÓN DEL GRUPO MUSCULAR Y CATEGORIZACIÓN POR INTENSIDAD:
   - Si el usuario pide ejercicios para un área específica (ej. **PIERNAS / TREN INFERIOR**), el **100% de los ejercicios recomendados en el plan DEBEN enfocarse en las piernas** (Cuádriceps, Glúteos, Isquiotibiales, Gemelos, Abductores/Aductores). ¡ESTÁ ESTRICTAMENTE PROHIBIDO mezclar ejercicios de tórax, pecho, abdomen o brazos cuando el usuario pidió piernas!
   - CATEGORIZA cada ejercicio según el Nivel de Experiencia ({effective_level}) y la Intensidad solicitada ({effective_intensity}):
     * **Nivel Básico (Intensidad Baja) / Principiante**: Usa EXCLUSIVAMENTE ejercicios básicos de bajo impacto y control motor (ej. "Sentadilla asistida con peso corporal", "Puente de glúteos en suelo (Glute Bridge)", "Zancada estática con peso corporal", "Elevación de talones de pie", "Curl femoral de pie o sentado suave", "Abducción de cadera lateral"). PROHIBIDO mandar sentadilla con barra pesada o ejercicios avanzados a un principiante de intensidad baja.
     * **Nivel Intermedio (Intensidad Media)**: Ejercicios con carga moderada o máquinas guiadas (ej. "Sentadilla Goblet con mancuerna", "Prensa de piernas 45°", "Zancadas con mancuernas", "Peso muerto rumano con mancuernas", "Curl de isquiotibiales en máquina").
     * **Nivel Avanzado (Intensidad Alta)**: Ejercicios compuestos pesados o pliométricos (ej. "Sentadilla profunda con barra", "Peso muerto con barra", "Sentadilla búlgara", "Sentadilla con salto").

3. REGLA CIENTÍFICA DE DESCANSO MUSCULAR (48-72 HORAS) E INTERACCIÓN SEMANAL (¡MUY IMPORTANTE!):
   - Basado en fisiología del ejercicio, entrenar un mismo grupo muscular grande (especialmente **Piernas y Glúteos**) todos los días seguidos genera fatiga neuromuscular acumulada, catabolismo y riesgo de lesión articular/tendinosa. Las piernas necesitan entre **48 y 72 horas de recuperación** entre sesiones.
   - Por lo tanto, cuando el usuario pida una rutina de Piernas (o de un grupo muscular específico) para su semana:
     a) **NO la pautes para todos los días seguidos**.
     b) **Explícale en `reply`**:
        - Si es Principiante / Intensidad Baja: que lo más óptimo para no fatigar el músculo es entrenar Piernas **2 días a la semana separados por 48-72h (ej. Lunes y Miércoles, o Lunes y Jueves)**.
        - Si es Intermedio / Avanzado: que lo más óptimo es entrenar Piernas en **días alternos: Lunes, Miércoles y Viernes** (variando el enfoque: ej. Lunes dominante de cuádriceps, Miércoles dominante de glúteos/isquiotibiales).
     c) **Hazle la pregunta interactiva de combinación en `reply`**:
        Dile textualmente algo como: *"Estás pidiendo entrenar piernas para la semana, pero para no fatigar el músculo y respetar las 48 a 72 horas de recuperación, lo más recomendable es hacer Piernas los días Lunes y Miércoles (y opcionalmente Viernes). Para los días intermedios (Martes y Jueves), podemos relacionarlo y combinarlo con otro grupo muscular mientras tus piernas descansan. ¿Con cuál te gustaría combinarlo: **1) Tren Superior (Espalda, Pecho y Brazos)**, **2) Core, Abdomen y Postura**, o **3) Movilidad articular y Cardio suave**?"*

4. REGLA DE EQUIPAMIENTO Y NUTRICIÓN SINÉRGICA:
   - Respeta estrictamente el equipo disponible del usuario.
   - Adapta la nutrición a la intensidad ({effective_intensity}).

5. REGLA DE RECALIBRACIÓN O REPETIR CUESTIONARIO:
   - Solo pon `"suggest_questionnaire": true` si el usuario pide explícitamente cambiar sus respuestas o abrir de nuevo el cuestionario. En cualquier otro caso pon `false`.

Retorna EXCLUSIVAMENTE un objeto JSON válido con esta estructura exacta:
{{
  "reply": "Respuesta conversacional clara, explicando la selección por nivel de intensidad, la pauta de días alternos (ej. Lunes y Miércoles) para no fatigar el músculo y preguntando con qué grupo complementario quiere combinar los días Martes y Jueves",
  "category": "Categoría de la fase (ej. Piernas - Nivel Básico · Intensidad Baja)",
  "duration_weeks": 4,
  "rest_between_sets_sec": 60,
  "progression_rule": "Regla de progresión y descanso de 48-72h entre sesiones de pierna",
  "extracted_equipment": null,
  "suggest_questionnaire": false,
  "has_plan": true,
  "structured_plan": {{
    "day": "Lunes y Miércoles (Alternado 48-72h)",
    "title": "Rutina de Piernas ({effective_level} - Intensidad {effective_intensity})",
    "recommended_days": ["Lunes", "Miércoles"],
    "complementary_days": {{
      "Martes": "Tren Superior Suave o Core",
      "Jueves": "Movilidad Articular o Tren Superior"
    }},
    "exercises": [
      {{
        "name": "Nombre exacto del ejercicio acorde a la intensidad",
        "sets": 3,
        "reps": "10-12",
        "animation_key": "squat",
        "primary_muscle": "Cuádriceps, Glúteos",
        "secondary_muscle": "Isquiotibiales",
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
Nota: Si el usuario ya indicó qué área quiere entrenar (ej. piernas) o ya envió su cuestionario pidiendo ejercicios, genera de una vez `has_plan: true` con su `structured_plan` completo para los días óptimos (ej. Lunes y Miércoles) Y al final de `reply` pregúntale con qué ejercicio/grupo complementario desea relacionar los días Martes y Jueves. Si apenas envió el cuestionario sin decir qué área quiere entrenar hoy, pon `has_plan: false` y pregúntale qué grupo muscular quiere priorizar.
Datos del usuario: {_profile_context(payload, effective_level, effective_intensity)}
Historial de la conversación:
{_conversation_history(payload.history)}
Mensaje actual del usuario: {payload.message}
Devuelve SOLO JSON."""
    )

    result = generate_json_text(prompt, timeout=AI_TIMEOUT_SEC)
    raw = (result.text or "").strip()
    data = None
    try:
        data = json.loads(raw)
    except Exception:
        first_brace = raw.find("{")
        last_brace = raw.rfind("}")
        if first_brace != -1 and last_brace > first_brace:
            try:
                data = json.loads(raw[first_brace:last_brace + 1])
            except Exception:
                pass

    if not isinstance(data, dict):
        reply_clean = re.sub(r"```(?:json)?", "", raw).replace("```", "").strip()
        data = {
            "reply": reply_clean or "¡Entendido! Vamos a continuar afinando tu plan de entrenamiento.",
            "category": "Acondicionamiento y Fuerza",
            "duration_weeks": 4,
            "rest_between_sets_sec": 60,
            "progression_rule": "Mantén técnica estricta y respeta 48-72h de recuperación muscular.",
            "extracted_equipment": None,
            "has_plan": False,
            "structured_plan": None,
        }

    is_complementary = _is_complementary_days_request(payload)
    structured_plan = _normalize_structured_plan(
        data.get("structured_plan"),
        intensity=effective_intensity,
        level=effective_level,
        requested_focus=requested_focus,
        is_complementary_days=is_complementary,
    )
    has_plan = bool(data.get("has_plan")) and structured_plan is not None
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

    return {
        "provider": result.provider,
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
