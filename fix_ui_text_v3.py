import sys
import re

path = 'mobile_app/lib/screens/workouts_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = re.sub(r"biomechanics: 'Activaci.*?IA\.',", "biomechanics: ex.get('biomechanics', 'Biomecánica sugerida por IA.'),", text, flags=re.DOTALL)
text = re.sub(r"posture: 'Mant.*?natural\.',", "posture: ex.get('posture', 'Mantén la postura natural.'),", text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
