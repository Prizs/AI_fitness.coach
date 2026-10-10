import sys

path = 'mobile_app/lib/screens/trainer_dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_text = '''            Text(
              "Tu CÃ³digo de Entrenador es:\\n",'''

new_text = '''            Text(
              "Tu CÃ³digo de Entrenador es:\\n\",'''

text = text.replace(old_text, new_text)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
