import sys

path = 'backend/app/services/weekly_plan.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_prompt = '''        "exercises (lista con name, sets, reps, animation_key, primary_muscle, "
        "secondary_muscle),\\n"
        "nutrition (diccionario con desayuno, almuerzo, cena, snack) y synergy.\\n\\n"'''

new_prompt = '''        "exercises (lista con name, sets, reps, animation_key, primary_muscle, "
        "secondary_muscle, biomechanics, posture),\\n"
        "nutrition (lista con objetos que tengan 'title' e 'items') y synergy.\\n\\n"
        "'biomechanics' debe ser una explicacion detallada paso a paso de la tecnica del ejercicio.\\n"
        "'posture' debe ser una nota de seguridad o postura clave.\\n"
        "Usa SOLO nombres de ejercicios clasicos y estandar (ej. Sentadilla, Press de Banca) para que coincidan con nuestra base de datos.\\n"'''

text = text.replace(old_prompt, new_prompt)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
