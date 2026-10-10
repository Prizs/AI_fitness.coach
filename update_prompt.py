import sys

path = 'backend/app/services/weekly_plan.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_prompt = '''    prompt = (
        "Genera un plan semanal de fitness y nutricion en JSON valido.\\n"
        "Perfil: objetivo " + str(profile.get("goal", "mejorar condicion fisica")) +
        "; nivel " + str(profile.get("level", "intermedio")) +
        "; edad " + str(profile.get("age", 25)) +
        "; peso " + str(profile.get("weight", 70)) + " kg.\\n"
        "Alergias: " + str(profile.get("food_allergies") or "ninguna") +
        ". Lesiones: " + str(profile.get("current_injuries") or "ninguna") +
        ". Zonas a evitar: " + str(profile.get("areas_to_avoid") or "ninguna") + ".\\n\\n"
        'Devuelve un objeto con la clave "days": una lista de exactamente 7 objetos, '
        "uno por dia.\\n"
        "Cada objeto debe tener: weekday (0=Lunes ... 6=Domingo), title, "
        "is_training (true/false),\\n"
        "exercises (lista con name, sets, reps, animation_key, primary_muscle, "
        "secondary_muscle),\\n"
        "nutrition (lista con title e items) y synergy.\\n\\n"
        '"synergy" explica en una frase como se combinan el entrenamiento de ese dia '
        "y la alimentacion\\n"
        "de ese dia para lograr el objetivo. Varia la comida cada dia: no repitas el "
        "mismo menu.\\n"
        "No diagnostiques ni prescribas tratamientos."
    )'''

new_prompt = '''    exp = profile.get("experience_level", "Intermedio")
    intensity = profile.get("intensity_preference", "Medio")
    prompt = (
        "Genera un plan semanal de fitness y nutricion en JSON valido.\\n"
        "Perfil: objetivo " + str(profile.get("goal", "mejorar condicion fisica")) +
        "; nivel de experiencia " + str(exp) +
        "; intensidad deseada " + str(intensity) +
        "; edad " + str(profile.get("age", 25)) +
        "; peso " + str(profile.get("weight", 70)) + " kg.\\n"
        "Alergias: " + str(profile.get("food_allergies") or "ninguna") +
        ". Lesiones: " + str(profile.get("current_injuries") or "ninguna") +
        ". Zonas a evitar: " + str(profile.get("areas_to_avoid") or "ninguna") + ".\\n\\n"
        "CRITICO: Si el nivel es 'Principiante', escoge ejercicios ultra-basicos, de intensidad " + str(intensity) + ".\\n"
        'Devuelve un objeto con la clave "days": una lista de exactamente 7 objetos, '
        "uno por dia.\\n"
        "Cada objeto debe tener: weekday (0=Lunes ... 6=Domingo), title, "
        "is_training (true/false),\\n"
        "exercises (lista con name, sets, reps, animation_key, primary_muscle, "
        "secondary_muscle),\\n"
        "nutrition (diccionario con desayuno, almuerzo, cena, snack) y synergy.\\n\\n"
        '"synergy" explica en una frase como se combinan el entrenamiento de ese dia '
        "y la alimentacion\\n"
        "de ese dia para lograr el objetivo. Varia la comida cada dia: no repitas el "
        "mismo menu.\\n"
        "No diagnostiques ni prescribas tratamientos."
    )'''

text = text.replace(old_prompt, new_prompt)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
