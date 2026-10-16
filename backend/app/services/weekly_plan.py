"""Plan semanal: 7 dias con rutina, nutricion y sinergia por dia.

Se separa de `app.routers.plans` para no tocar el endpoint que ya funciona. Este
modulo genera una semana completa para que el telefono pueda mostrar siempre el
dia que le toca, sin depender de que el usuario consulte nada.

Cuando la IA no esta disponible se usa un plan base seguro y orientativo.
"""

from app.routers.exercises import classify_intensity, get_exercise_gif
from app.services.ai_providers import configured_providers, generate_json_text

WEEKDAY_NAMES = [
    "Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo",
]

AI_TIMEOUT_SEC = 20.0


def _fallback_synergy(index: int, title: str) -> str:
    """Explica de forma sencilla como se combinan entrenamiento y alimentacion."""
    if index < 5:
        return (
            f"Hoy entrenas {title.lower()}. La proteina de la comida y de la cena "
            "aporta los aminoacidos que el musculo necesita para repararse, y los "
            "carbohidratos de la comida dan energia para la sesion."
        )
    if index == 5:
        return (
            "Hoy toca recuperacion: el musculo se adapta mientras descansas. Mas "
            "proteina y liquidos ayudan a reponer lo que gastaste en la semana."
        )
    return (
        "Hoy es descanso activo. La alimentacion algo mas ligera y la hidratacion "
        "ayudan a que el cuerpo reponga sin cargar de mas."
    )


def _enrich_exercise(ex: dict, intensity_hint: str = "Media") -> dict:
    name = str(ex.get("name") or "Ejercicio")
    info = classify_intensity(name, intensity_hint)
    gif_data = get_exercise_gif(name, intensity_hint)
    return {
        "name": name,
        "sets": ex.get("sets") or 3,
        "reps": str(ex.get("reps") or "10-12"),
        "animation_key": str(ex.get("animation_key") or "generic-exercise"),
        "primary_muscle": str(ex.get("primary_muscle") or "General"),
        "secondary_muscle": str(ex.get("secondary_muscle") or "Secundario"),
        "intensity_level": str(ex.get("intensity_level") or info["label"]),
        "biomechanics": str(
            ex.get("biomechanics")
            or "Movimiento controlado respetando el rango articular y la respiración."
        ),
        "posture": str(
            ex.get("posture")
            or "Columna neutra, abdomen activado y estabilidad escapular."
        ),
        "gif_url": ex.get("gif_url") or gif_data.get("gif_url"),
    }


def _sessions(intensity_hint: str = "Media"):
    """Rutinas base de la semana alternadas (48-72h recuperacion muscular)."""
    is_low = any(k in intensity_hint.lower() for k in ("baja", "bajo", "principiante", "novato"))
    is_high = any(k in intensity_hint.lower() for k in ("alta", "alto", "avanzado"))
    lvl_label = (
        "Básico (Intensidad Baja)"
        if is_low
        else ("Avanzado (Intensidad Alta)" if is_high else "Intermedio (Intensidad Media)")
    )
    return [
        {
            "title": f"Tren Inferior (Piernas y Glúteos) · {lvl_label}",
            "exercises": [
                {"name": "Sentadilla asistida con peso corporal" if is_low else ("Sentadilla profunda con barra" if is_high else "Sentadilla goblet con mancuerna"),
                 "sets": 3 if is_low else 4, "reps": "10-12",
                 "animation_key": "chair-squat",
                 "primary_muscle": "Cuádriceps", "secondary_muscle": "Glúteos",
                 "intensity_level": lvl_label},
                {"name": "Puente de glúteos en suelo" if is_low else "Peso muerto rumano con mancuernas",
                 "sets": 3, "reps": "12",
                 "animation_key": "glute-bridge",
                 "primary_muscle": "Glúteos", "secondary_muscle": "Isquiotibiales",
                 "intensity_level": lvl_label},
                {"name": "Elevación de talones de pie",
                 "sets": 3, "reps": "15",
                 "animation_key": "calf-raise",
                 "primary_muscle": "Pantorrillas", "secondary_muscle": "Sóleo",
                 "intensity_level": lvl_label},
            ],
        },
        {
            "title": f"Tren Superior (Pecho y Espalda) · {lvl_label}",
            "exercises": [
                {"name": "Flexiones inclinadas con apoyo" if is_low else "Press de pecho con mancuernas",
                 "sets": 3, "reps": "10-12",
                 "animation_key": "incline-push-up",
                 "primary_muscle": "Pectorales", "secondary_muscle": "Tríceps",
                 "intensity_level": lvl_label},
                {"name": "Remo sentado con banda o polea" if is_low else "Remo con mancuerna a una mano",
                 "sets": 3, "reps": "12",
                 "animation_key": "seated-row",
                 "primary_muscle": "Dorsales", "secondary_muscle": "Bíceps",
                 "intensity_level": lvl_label},
                {"name": "Press de hombros sentado con mancuernas ligeras",
                 "sets": 3, "reps": "10-12",
                 "animation_key": "seated-shoulder-press",
                 "primary_muscle": "Deltoides", "secondary_muscle": "Tríceps",
                 "intensity_level": lvl_label},
            ],
        },
        {
            "title": f"Tren Inferior (Recuperación 48h Superada) · {lvl_label}",
            "exercises": [
                {"name": "Zancada estática asistida sin peso" if is_low else "Prensa de piernas en máquina",
                 "sets": 3, "reps": "10 por pierna" if is_low else "10-12",
                 "animation_key": "assisted-lunge",
                 "primary_muscle": "Cuádriceps", "secondary_muscle": "Glúteos",
                 "intensity_level": lvl_label},
                {"name": "Curl femoral tumbado en máquina",
                 "sets": 3, "reps": "12",
                 "animation_key": "leg-curl",
                 "primary_muscle": "Isquiotibiales", "secondary_muscle": "Glúteos",
                 "intensity_level": lvl_label},
                {"name": "Plancha abdominal isométrica",
                 "sets": 3, "reps": "30 s",
                 "animation_key": "front-plank",
                 "primary_muscle": "Core", "secondary_muscle": "Recto abdominal",
                 "intensity_level": lvl_label},
            ],
        },
        {
            "title": f"Hombros, Brazos y Core · {lvl_label}",
            "exercises": [
                {"name": "Elevaciones laterales con mancuernas",
                 "sets": 3, "reps": "12",
                 "animation_key": "lateral-raise",
                 "primary_muscle": "Deltoides", "secondary_muscle": "Trapecio",
                 "intensity_level": lvl_label},
                {"name": "Curl de bíceps con mancuernas",
                 "sets": 3, "reps": "12",
                 "animation_key": "bicep-curl",
                 "primary_muscle": "Bíceps", "secondary_muscle": "Antebrazo",
                 "intensity_level": lvl_label},
                {"name": "Crunch abdominal controlado en suelo",
                 "sets": 3, "reps": "12-15",
                 "animation_key": "dead-bug",
                 "primary_muscle": "Abdominales", "secondary_muscle": "Core",
                 "intensity_level": lvl_label},
            ],
        },
        {
            "title": f"Acondicionamiento Funcional Integral · {lvl_label}",
            "exercises": [
                {"name": "Subida al cajón baja (Step-up suave)" if is_low else "Zancadas caminando con mancuernas",
                 "sets": 3, "reps": "10 por lado",
                 "animation_key": "assisted-lunge",
                 "primary_muscle": "Cuádriceps", "secondary_muscle": "Glúteos",
                 "intensity_level": lvl_label},
                {"name": "Jalón al pecho en polea alta",
                 "sets": 3, "reps": "12",
                 "animation_key": "seated-row",
                 "primary_muscle": "Dorsales", "secondary_muscle": "Bíceps",
                 "intensity_level": lvl_label},
                {"name": "Elevación de piernas tumbado",
                 "sets": 3, "reps": "12",
                 "animation_key": "side-plank",
                 "primary_muscle": "Abdominales", "secondary_muscle": "Core",
                 "intensity_level": lvl_label},
            ],
        },
        {
            "title": "Movilidad Articular y Recuperación",
            "exercises": [
                {"name": "Estiramiento dinámico y movilidad de cadera", "sets": 3, "reps": "40 s",
                 "animation_key": "hamstring-stretch",
                 "primary_muscle": "Caderas y Movilidad", "secondary_muscle": "Zona Lumbar",
                 "intensity_level": "Básico (Intensidad Baja)"},
                {"name": "Caminata en cinta con inclinación moderada", "sets": 1, "reps": "15 min",
                 "animation_key": "walk",
                 "primary_muscle": "Sistema Cardiovascular", "secondary_muscle": "Tren Inferior",
                 "intensity_level": "Básico (Intensidad Baja)"},
            ],
        },
        {
            "title": "Descanso Activo y Regeneración",
            "exercises": [
                {"name": "Bicicleta estática a ritmo suave", "sets": 1, "reps": "20 min",
                 "animation_key": "bike",
                 "primary_muscle": "Cardio Bajo Impacto", "secondary_muscle": "Articulaciones",
                 "intensity_level": "Básico (Intensidad Baja)"},
            ],
        },
    ]


def _meals_for(index):
    """Alimentacion que cambia cada dia segun la carga del entrenamiento."""
    base = [
        {
            "title": "Desayuno",
            "items": ["Avena con yogur natural", "Fruta fresca de temporada",
                      "Agua 400 ml"],
        },
        {
            "title": "Almuerzo",
            "items": ["Proteina magra 150 g (pollo, pescado o huevo)",
                      "Arroz integral o tubérculo 1 taza cocida",
                      "Ensalada variada con aceite de oliva"],
        },
        {
            "title": "Merienda",
            "items": ["Fruta entera", "Puñado de frutos secos sin sal"],
        },
        {
            "title": "Cena",
            "items": ["Proteina ligera 120 g", "Verduras cocidas o al vapor",
                      "Carbohidrato moderado 1/2 taza"],
        },
    ]
    if index == 0:
        base[0]["items"].append("Yogur griego: proteina extra para fuerza")
    elif index == 2:
        base[1]["items"].append("Carbohidratos extra: energia para recuperacion muscular")
    elif index == 5:
        base[2]["items"] = ["Fruta", "Agua 500 ml: hidratacion para recuperar"]
    elif index == 6:
        base[3]["items"].append("Porcion algo menor: dia de descanso")
    return base


def _fallback_week(profile):
    """Semana completa sin IA, respetando las restricciones e intensidad del perfil."""
    intensity_hint = f"{profile.get('intensity_preference', 'Media')} {profile.get('experience_level', 'Intermedio')} {profile.get('goal', '')}"
    sessions = _sessions(intensity_hint)

    notes = " ".join([
        str(profile.get("areas_to_avoid") or ""),
        str(profile.get("current_injuries") or ""),
    ]).lower()
    if any(t in notes for t in ("tobillo", "rodilla", "cadera", "pierna")):
        allowed = ("Pectorales", "Dorsales", "Bíceps", "Tríceps", "Deltoides",
                   "Core", "Abdominales", "Sistema Cardiovascular", "Cardio Bajo Impacto")
        for day in sessions:
            filtered = [ex for ex in day["exercises"]
                        if ex["primary_muscle"] in allowed]
            day["exercises"] = filtered or sessions[1]["exercises"]

    days = []
    for index, name in enumerate(WEEKDAY_NAMES):
        session = sessions[index]
        enriched_exercises = [_enrich_exercise(ex, intensity_hint) for ex in session["exercises"]]
        days.append({
            "weekday": index,
            "weekday_name": name,
            "title": session["title"],
            "is_training": index < 5,
            "exercises": enriched_exercises,
            "nutrition": _meals_for(index),
            "synergy": _fallback_synergy(index, session["title"]),
        })

    return {
        "provider": "fallback",
        "days": days,
        "training_days": [d["weekday_name"] for d in days if d["is_training"]],
    }


def _normalize_days(raw, intensity_hint: str = "Media"):
    """Garantiza que haya 7 dias bien formados y en orden."""
    by_weekday = {}
    for entry in (raw if isinstance(raw, list) else []):
        if isinstance(entry, dict) and "weekday" in entry:
            try:
                by_weekday[int(entry["weekday"])] = entry
            except (TypeError, ValueError):
                continue

    days = []
    for index, name in enumerate(WEEKDAY_NAMES):
        entry = by_weekday.get(index, {})
        exercises = []
        for ex in entry.get("exercises") or []:
            if not isinstance(ex, dict):
                continue
            exercises.append(_enrich_exercise(ex, intensity_hint))
        nutrition = []
        for meal in entry.get("nutrition") or []:
            if not isinstance(meal, dict):
                continue
            items = meal.get("items") or []
            if isinstance(items, str):
                items = [items]
            nutrition.append({
                "title": str(meal.get("title") or "Comida"),
                "items": [str(i) for i in items],
            })
        days.append({
            "weekday": index,
            "weekday_name": name,
            "title": str(entry.get("title") or "Sesion"),
            "is_training": bool(entry.get("is_training", index < 5)),
            "exercises": exercises,
            "nutrition": nutrition,
            "synergy": str(entry.get("synergy") or ""),
        })
    return days


def _ai_week(profile):
    """Pide a la IA una semana completa. Devuelve None si no se puede."""
    if not configured_providers():
        return None
    exp = profile.get("experience_level", "Intermedio")
    intensity = profile.get("intensity_preference", "Medio")
    prompt = (
        "Genera un plan semanal de fitness y nutricion en JSON valido.\n"
        "Perfil: objetivo " + str(profile.get("goal", "mejorar condicion fisica")) +
        "; nivel de experiencia " + str(exp) +
        "; intensidad deseada " + str(intensity) +
        "; edad " + str(profile.get("age", 25)) +
        "; peso " + str(profile.get("weight", 70)) + " kg.\n"
        "Alergias: " + str(profile.get("food_allergies") or "ninguna") +
        ". Lesiones: " + str(profile.get("current_injuries") or "ninguna") +
        ". Zonas a evitar: " + str(profile.get("areas_to_avoid") or "ninguna") + ".\n\n"
        "CRITICO 1: Si el nivel es 'Principiante' o intensidad baja, escoge ejercicios basicos de bajo impacto acorde a la intensidad " + str(intensity) + ".\n"
        "CRITICO 2 (DESCANSO MUSCULAR 48-72H): NUNCA pongas el mismo grupo muscular (ej. Piernas) en dias consecutivos. Alterna p. ej. Lunes (Piernas/Tren Inferior), Martes (Tren Superior/Core), Miercoles (Descanso activo o Cardio/Core), Jueves (Piernas/Gluteos), Viernes (Tren Superior Funcional).\n"
        'Devuelve un objeto con la clave "days": una lista de exactamente 7 objetos, '
        "uno por dia.\n"
        "Cada objeto debe tener: weekday (0=Lunes ... 6=Domingo), title, "
        "is_training (true/false),\n"
        "exercises (lista con name, sets, reps, animation_key, primary_muscle, "
        "secondary_muscle, intensity_level, biomechanics, posture),\n"
        "nutrition (lista con objetos que tengan 'title' e 'items') y synergy.\n\n"
        "'biomechanics' debe ser una explicacion concisa paso a paso de la tecnica del ejercicio.\n"
        "'posture' debe ser una nota de seguridad o postura clave.\n"
        "Usa SOLO nombres de ejercicios clasicos y estandar (ej. Sentadilla asistida con peso corporal, Puente de gluteos, Zancada, Prensa de piernas) para que coincidan con nuestra base de datos.\n"
        '"synergy" explica en una frase como se combinan el entrenamiento de ese dia '
        "y la alimentacion\n"
        "de ese dia para lograr el objetivo. Varia la comida cada dia: no repitas el "
        "mismo menu.\n"
        "No diagnostiques ni prescribas tratamientos."
    )
    try:
        result = generate_json_text(prompt, timeout=AI_TIMEOUT_SEC)
        data = json.loads(result.text)
        days = _normalize_days(data.get("days"), f"{intensity} {exp}")
        # Solo se acepta si la IA trajo contenido real para varios dias.
        completos = sum(1 for d in days if d["exercises"] and d["nutrition"])
        if completos < 3:
            return None
        return {
            "provider": result.provider,
            "days": days,
            "training_days": [d["weekday_name"] for d in days if d["is_training"]],
        }
    except Exception:
        return None


def build_weekly_plan(profile):
    """Punto de entrada: devuelve la semana, con IA si se puede y si no la base."""
    return _ai_week(profile) or _fallback_week(profile)

def get_alternative_exercise(payload) -> dict | None:
    if not configured_providers():
        return None
    try:
        equip_rule = "" if payload.equipment_available else "CRITICO: El usuario NO TIENE EQUIPO. Debe ser peso corporal (calistenia)."
        prompt = f"""
        El usuario necesita un ejercicio alternativo para '{payload.current_exercise}' que trabaja el musculo '{payload.target_muscle}'.
        Motivo: Maquina ocupada o no disponible.
        Reglas: {equip_rule}
        Debes devolver UNICAMENTE un objeto JSON valido con la estructura exacta:
        {{
            "name": "Nombre del nuevo ejercicio",
            "sets": 3,
            "reps": "10-12",
            "animation_key": "animation-key",
            "primary_muscle": "{payload.target_muscle}",
            "secondary_muscle": "Secundario",
            "equipment": "Polea Alta o Peso Corporal"
        }}
        """
        result = generate_json_text(prompt, timeout=15)
        alt = json.loads(result.text)
        return alt
    except Exception:
        return None
