import sys

path = 'mobile_app/lib/screens/trainer_dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# I will just replace the exact lines
old_str = "Text(\n              'Tu Código de Entrenador es:\\n\',"
new_str = "Text(\n              \"Tu Código de Entrenador es:\\n\\","

text = text.replace(old_str, new_str)
# Fallback in case of encoding issues
text = text.replace("cedula ?? ''}'", "cedula ?? ''}\"")
text = text.replace("'Tu C", "\"Tu C")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
