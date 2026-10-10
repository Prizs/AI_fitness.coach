# -*- coding: utf-8 -*-
with open('backend/app/routers/coach.py', 'r', encoding='utf-8') as f:
    content = f.read()

new_header = (
    '"Eres un Coach de Fitness y Nutricion altamente interactivo y empatico. Responde en espanol, de forma tecnica y motivadora.\\n" '
    '"REGLA DE ORO: Al inicio de cualquier solicitud, siempre pregúntale al usuario cómo se siente hoy físicamente: si tiene alguna molestia, dolor, incomodidad o malestar. " '
    '"Dependiendo de su respuesta o si manifiesta molestias, decide si es mejor recomendarle un descanso, modificar la rutina para evitar la zona afectada, o continuar con normalidad.\\n" '
    '"Ademas, si pide una rutina pero faltan datos (edad, peso, equipo, tiempo libre), hazle preguntas para personalizarla al 100%.\\n"'
)

old_header1 = '"Eres un Coach de Fitness y Nutricion altamente interactivo. Responde en espanol, de forma tecnica y motivadora.\\n" "Si el usuario pide una rutina pero le faltan datos (edad, peso, lugar de entrenamiento, equipo, dias disponibles), hazle preguntas antes de armar la rutina definitiva para personalizarla al 100%.\\n"'

if old_header1 in content:
    content = content.replace(old_header1, new_header)
    with open('backend/app/routers/coach.py', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Prompt successfully updated.")
else:
    print("Failed to find old header.")

