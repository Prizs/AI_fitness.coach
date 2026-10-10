import sys

# 1. Update plans.py
path_plans = 'backend/app/routers/plans.py'
with open(path_plans, 'r', encoding='utf-8') as f:
    text_plans = f.read()

old_fields = '''                        "name": str(exercise.get("name") or exercise.get("exercise") or "Ejercicio"),
                        "sets": exercise.get("sets") or exercise.get("series") or 3,
                        "reps": str(exercise.get("reps") or exercise.get("repetitions") or "10"),
                        "animation_key": str(exercise.get("animation_key") or "generic-exercise"),
                        "primary_muscle": str(exercise.get("primary_muscle") or "General"),
                        "secondary_muscle": str(exercise.get("secondary_muscle") or "Secundario"),'''

new_fields = '''                        "name": str(exercise.get("name") or exercise.get("exercise") or "Ejercicio"),
                        "sets": exercise.get("sets") or exercise.get("series") or 3,
                        "reps": str(exercise.get("reps") or exercise.get("repetitions") or "10"),
                        "animation_key": str(exercise.get("animation_key") or "generic-exercise"),
                        "primary_muscle": str(exercise.get("primary_muscle") or "General"),
                        "secondary_muscle": str(exercise.get("secondary_muscle") or "Secundario"),
                        "equipment": str(exercise.get("equipment") or "Peso Corporal"),'''

text_plans = text_plans.replace(old_fields, new_fields)
with open(path_plans, 'w', encoding='utf-8') as f:
    f.write(text_plans)

# 2. Update weekly_plan.py
path_wp = 'backend/app/services/weekly_plan.py'
with open(path_wp, 'r', encoding='utf-8') as f:
    text_wp = f.read()

old_schema = '''"sessions" DEBE ser una lista de objetos con las claves day, title y exercises (lista de objetos con name, sets, reps, animation_key, primary_muscle, secondary_muscle).'''
new_schema = '''"sessions" DEBE ser una lista de objetos con las claves day, title y exercises (lista de objetos con name, sets, reps, animation_key, primary_muscle, secondary_muscle, equipment). 
En 'equipment', especifica textualmente qué máquina o herramienta usar (Ej. 'Polea Alta', 'Mancuernas', 'Barra Z', 'Peso Corporal'). Extrae esto de la lógica del ejercicio.'''

text_wp = text_wp.replace(old_schema, new_schema)

old_alt_schema = '''        {{
            "name": "Nombre del nuevo ejercicio",
            "sets": 3,
            "reps": "10-12",
            "animation_key": "animation-key",
            "primary_muscle": "{payload.target_muscle}",
            "secondary_muscle": "Secundario"
        }}'''

new_alt_schema = '''        {{
            "name": "Nombre del nuevo ejercicio",
            "sets": 3,
            "reps": "10-12",
            "animation_key": "animation-key",
            "primary_muscle": "{payload.target_muscle}",
            "secondary_muscle": "Secundario",
            "equipment": "Polea Alta o Peso Corporal"
        }}'''
text_wp = text_wp.replace(old_alt_schema, new_alt_schema)

with open(path_wp, 'w', encoding='utf-8') as f:
    f.write(text_wp)
