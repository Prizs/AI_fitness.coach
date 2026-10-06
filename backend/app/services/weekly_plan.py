"""Plan semanal: 7 dias con rutina, nutricion y sinergia por dia.

Se separa de `app.routers.plans` para no tocar el endpoint que ya funciona. Este
modulo genera una semana completa para que el telefono pueda mostrar siempre el
dia que le toca, sin depender de que el usuario consulte nada.

Cuando la IA no esta disponible se usa un plan base seguro y orientativo.
"""

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


def _sessions():
    """Rutinas base de la semana. Los ultimos dos dias recuperan."""
    return [
        {
            "title": "Fuerza tren superior",
            "exercises": [
                {"name": "Press de pecho en pared", "sets": 3, "reps": "10",
                 "animation_key": "wall-chest-press",
                 "primary_muscle": "Pectoral", "secondary_muscle": "Triceps"},
                {"name": "Flexiones inclinadas", "sets": 3, "reps": "8-12",
                 "animation_key": "incline-push-up",
                 "primary_muscle": "Pectoral", "secondary_muscle": "Core"},
                {"name": "Remo con banda elastica", "sets": 3, "reps": "12",
                 "animation_key": "seated-row",
                 "primary_muscle": "Dorsal ancho", "secondary_muscle": "Biceps"},
            ],
        },
        {
            "title": "Fuerza tren inferior",
            "exercises": [
                {"name": "Sentadilla a la silla", "sets": 3, "reps": "10-12",
                 "animation_key": "chair-squat",
                 "primary_muscle": "Cuadriceps", "secondary_muscle": "Gluteos"},
                {"name": "Puente de cadera", "sets": 3, "reps": "12",
                 "animation_key": "glute-bridge",
                 "primary_muscle": "Gluteos", "secondary_muscle": "Isquiotibiales"},
                {"name": "Elevacion de talones de pie", "sets": 3, "reps": "15",
                 "animation_key": "calf-raise",
                 "primary_muscle": "Gemelos", "secondary_muscle": "Tibial anterior"},
            ],
        },
        {
            "title": "Resistencia y cardio",
            "exercises": [
                {"name": "Marcha en el sitio", "sets": 5, "reps": "60 s",
                 "animation_key": "march-in-place",
                 "primary_muscle": "Cardio", "secondary_muscle": "Cuadriceps"},
                {"name": "Bicicleta suave", "sets": 4, "reps": "45 s",
                 "animation_key": "bike",
                 "primary_muscle": "Cardio", "secondary_muscle": "Gluteos"},
                {"name": "Plancha frontal", "sets": 3, "reps": "20-30 s",
                 "animation_key": "front-plank",
                 "primary_muscle": "Core", "secondary_muscle": "Dorsal ancho"},
            ],
        },
        {
            "title": "Hombros y core",
            "exercises": [
                {"name": "Press de hombros sentado", "sets": 3, "reps": "10",
                 "animation_key": "seated-shoulder-press",
                 "primary_muscle": "Deltoides", "secondary_muscle": "Triceps"},
                {"name": "Elevaciones laterales", "sets": 3, "reps": "12",
                 "animation_key": "lateral-raise",
                 "primary_muscle": "Deltoides", "secondary_muscle": "Trapecio"},
                {"name": "Dead bug", "sets": 3, "reps": "10 por lado",
                 "animation_key": "dead-bug",
                 "primary_muscle": "Core", "secondary_muscle": "Cuadriceps"},
            ],
        },
        {
            "title": "Fuerza funcional",
            "exercises": [
                {"name": "Zancada asistida", "sets": 3, "reps": "10 por pierna",
                 "animation_key": "assisted-lunge",
                 "primary_muscle": "Cuadriceps", "secondary_muscle": "Gluteos"},
                {"name": "Remo sentado en silla", "sets": 3, "reps": "12",
                 "animation_key": "seated-row",
                 "primary_muscle": "Dorsal ancho", "secondary_muscle": "Biceps"},
                {"name": "Plancha lateral", "sets": 3, "reps": "20 s por lado",
                 "animation_key": "side-plank",
                 "primary_muscle": "Core", "secondary_muscle": "Dorsal ancho"},
            ],
        },
        {
            "title": "Movilidad y recuperacion",
            "exercises": [
                {"name": "Estiramiento de cadena posterior", "sets": 2, "reps": "30 s",
                 "animation_key": "hamstring-stretch",
                 "primary_muscle": "Isquiotibiales", "secondary_muscle": "Gemelos"},
                {"name": "Rotacion de hombro asistida", "sets": 2, "reps": "12",
                 "animation_key": "shoulder-mobility",
                 "primary_muscle": "Deltoides", "secondary_muscle": "Trapecio"},
                {"name": "Caminata suave", "sets": 1, "reps": "15 min",
                 "animation_key": "walk",
                 "primary_muscle": "Cardio", "secondary_muscle": "Core"},
            ],
        },
        {
            "title": "Descanso activo",
            "exercises": [
                {"name": "Caminata a ritmo conversacional", "sets": 1, "reps": "25 min",
                 "animation_key": "walk",
                 "primary_muscle": "Cardio", "secondary_muscle": "Core"},
                {"name": "Estiramiento de pectoral en puerta", "sets": 2, "reps": "30 s",
                 "animation_key": "chest-stretch",
                 "primary_muscle": "Pectoral", "secondary_muscle": "Deltoides"},
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
        base[1]["items"].append("Carbohidratos extra: energia para el cardio")
    elif index == 5:
        base[2]["items"] = ["Fruta", "Agua 500 ml: hidratacion para recuperar"]
    elif index == 6:
        base[3]["items"].append("Porcion algo menor: dia de descanso")
    return base


def _fallback_week(profile):
    """Semana completa sin IA, respetando las restricciones del perfil."""
    sessions = _sessions()

    notes = " ".join([
        str(profile.get("areas_to_avoid") or ""),
        str(profile.get("current_injuries") or ""),
    ]).lower()
    if any(t in notes for t in ("tobillo", "rodilla", "cadera", "pierna")):
        allowed = ("Pectoral", "Dorsal ancho", "Biceps", "Triceps", "Deltoides",
                   "Core", "Cardio", "Trapecio", "Isquiotibiales")
        for day in sessions:
            filtered = [ex for ex in day["exercises"]
                        if ex["primary_muscle"] in allowed]
            day["exercises"] = filtered or sessions[6]["exercises"]

    days = []
    for index, name in enumerate(WEEKDAY_NAMES):
        session = sessions[index]
        days.append({
            "weekday": index,
            "weekday_name": name,
            "title": session["title"],
            "is_training": index < 5,
            "exercises": session["exercises"],
            "nutrition": _meals_for(index),
            "synergy": _fallback_synergy(index, session["title"]),
        })

    return {
        "provider": "fallback",
        "days": days,
        "training_days": [d["weekday_name"] for d in days if d["is_training"]],
    }


def _normalize_days(raw):
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
            exercises.append({
                "name": str(ex.get("name") or "Ejercicio"),
                "sets": ex.get("sets") or 3,
                "reps": str(ex.get("reps") or "10"),
                "animation_key": str(ex.get("animation_key") or "generic-exercise"),
                "primary_muscle": str(ex.get("primary_muscle") or "General"),
                "secondary_muscle": str(ex.get("secondary_muscle") or "Secundario"),
            })
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
        "CRITICO: Si el nivel es 'Principiante', escoge ejercicios ultra-basicos, de intensidad " + str(intensity) + ".\n"
        'Devuelve un objeto con la clave "days": una lista de exactamente 7 objetos, '
        "uno por dia.\n"
        "Cada objeto debe tener: weekday (0=Lunes ... 6=Domingo), title, "
        "is_training (true/false),\n"
        "exercises (lista con name, sets, reps, animation_key, primary_muscle, "
        "secondary_muscle, biomechanics, posture),\n"
        "nutrition (lista con objetos que tengan 'title' e 'items') y synergy.\n\n"
        "'biomechanics' debe ser una explicacion detallada paso a paso de la tecnica del ejercicio.\n"
        "'posture' debe ser una nota de seguridad o postura clave.\n"
        "Usa SOLO nombres de ejercicios clasicos y estandar (ej. Sentadilla, Press de Banca) para que coincidan con nuestra base de datos.\n"
        '"synergy" explica en una frase como se combinan el entrenamiento de ese dia '
        "y la alimentacion\n"
        "de ese dia para lograr el objetivo. Varia la comida cada dia: no repitas el "
        "mismo menu.\n"
        "No diagnostiques ni prescribas tratamientos."
    )
    try:
        result = generate_json_text(prompt, timeout=AI_TIMEOUT_SEC)
        data = json.loads(result.text)
        days = _normalize_days(data.get("days"))
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
