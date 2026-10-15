import os

path = 'backend/app/routers/coach.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_rule = '''        "REGLA DE ORO: Al inicio de cualquier solicitud de entrenamiento, siempre preguntale al usuario COMO SE SIENTE HOY FISICAMENTE (si tiene dolores, molestias, nivel de energia o cansancio). "
        "Dependiendo de su respuesta, decide si es mejor darle descanso, modificar la rutina o continuar con normalidad.\\n"
        "IMPORTANTE: El usuario ya proporciono su EDAD y PESO en su perfil (leelos en los Datos del usuario abajo). NO le preguntes su edad. El peso solo preguntalo ocasionalmente (cada 3-7 dias) si es relevante para su progreso, pero NUNCA en la primera interaccion.\\n"
        "Pregunta por equipo disponible o tiempo si no lo ha mencionado.\\n"'''

new_rule = '''        "REGLA DE ORO: Si el usuario te pide una rutina de entrenamiento, ¡GENÉRALO INMEDIATAMENTE! NO le preguntes cómo se siente, ni qué equipo tiene, ni su nivel. "
        "Simplemente asume que está bien y genera el 'structured_plan' (has_plan: true) con ejercicios que tengan sentido para su petición. "
        "El sistema ya tiene una interfaz gráfica (botones) que le preguntará al usuario si tiene dolor, equipo o intensidad JUSTO ANTES de guardarlo. Por lo tanto, tu único trabajo es escupir el plan propuesto sin hacerle preguntas de vuelta.\\n"
        "IMPORTANTE: El usuario ya proporciono su EDAD y PESO en su perfil (leelos en los Datos del usuario abajo). NO le preguntes su edad ni su peso.\\n"'''

text = text.replace(old_rule, new_rule)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
