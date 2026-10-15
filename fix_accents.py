import os

path = 'backend/app/routers/coach.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("¡GENÉRALO INMEDIATAMENTE! NO le preguntes cómo se siente, ni qué equipo tiene", "GENERALO INMEDIATAMENTE. NO le preguntes como se siente, ni que equipo tiene")
text = text.replace("Simplemente asume que está bien", "Simplemente asume que esta bien")
text = text.replace("petición", "peticion")
text = text.replace("El sistema ya tiene una interfaz gráfica (botones) que le preguntará", "El sistema ya tiene una interfaz grafica (botones) que le preguntara")
text = text.replace("tu único trabajo", "tu unico trabajo")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
