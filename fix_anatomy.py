import sys
path = 'mobile_app/lib/screens/anatomy_workout_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("itemCount: kAnatomyExercises.length,", "itemCount: _exercisesList.length,")
text = text.replace("final ex = kAnatomyExercises[index];", "final ex = _exercisesList[index];")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
