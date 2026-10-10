import sys
path = 'mobile_app/lib/screens/anatomy_workout_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("child: _DidacticPanel(\n              exercise: _exercise,\n              onSelect: _select,\n            ),", "child: _DidacticPanel(\n              exercise: _exercise,\n              onSelect: _select,\n              exercises: _exercisesList,\n            ),")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
