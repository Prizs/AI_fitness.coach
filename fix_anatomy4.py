import sys
path = 'mobile_app/lib/screens/anatomy_workout_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("_ExerciseSelector(selected: exercise, onSelect: onSelect),", "_ExerciseSelector(selected: exercise, onSelect: onSelect, exercises: _exercisesList),")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
