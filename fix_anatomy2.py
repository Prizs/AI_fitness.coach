import sys
path = 'mobile_app/lib/screens/anatomy_workout_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("final exercise = kAnatomyExercises[index];", "final exercise = _exercisesList[index];")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
