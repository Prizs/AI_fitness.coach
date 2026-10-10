import sys

path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# I will find the AnatomyExercise creation inside the loop
old_dyn = "biomechanics: 'Activaci"
if old_dyn in text:
    pass # Wait, it might have UTF-8 issues. I'll just replace the line using python.

import re
text = re.sub(r"biomechanics: 'Activaci.*?IA\.',", "biomechanics: e.biomechanics,", text, flags=re.DOTALL)
text = re.sub(r"posture: 'Mant.*?natural\.',", "posture: e.posture,", text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
