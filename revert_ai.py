import os

path = 'backend/app/routers/coach.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

bad_rule = '''        "REGLA DE ORO: Si el usuario te pide una rutina de entrenamiento, GENERALO INMEDIATAMENTE. NO le preguntes como se siente, ni que equipo tiene, ni su nivel. "
        "Simplemente asume que esta bien y genera el 'structured_plan' (has_plan: true) con ejercicios que tengan sentido para su peticion. "
        "El sistema ya tiene una interfaz grafica (botones) que le preguntara al usuario si tiene dolor, equipo o intensidad JUSTO ANTES de guardarlo. Por lo tanto, tu unico trabajo es escupir el plan propuesto sin hacerle preguntas de vuelta.\\n"
        "IMPORTANTE: El usuario ya proporciono su EDAD y PESO en su perfil (leelos en los Datos del usuario abajo). NO le preguntes su edad ni su peso.\\n"'''

good_rule = '''        "REGLA DE ORO: Al inicio de cualquier solicitud de entrenamiento, siempre preguntale al usuario COMO SE SIENTE HOY FISICAMENTE (si tiene dolores, molestias, nivel de energia o cansancio). "
        "Dependiendo de su respuesta, decide si es mejor darle descanso, modificar la rutina o continuar con normalidad.\\n"
        "Si el usuario responde que tiene una molestia, preguntale DONDE le duele exactamente para evitar esa zona.\\n"
        "Pregunta por EQUIPO disponible (Gym, en casa, o sin equipo) y la INTENSIDAD deseada si no lo han mencionado.\\n"
        "IMPORTANTE: El usuario ya proporciono su EDAD y PESO en su perfil. NO le preguntes su edad. El peso solo preguntalo ocasionalmente si es relevante.\\n"'''

text = text.replace(bad_rule, good_rule)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
