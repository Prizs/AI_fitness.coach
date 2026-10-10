import sys
path = 'mobile_app/lib/screens/anatomy_workout_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("class _DidacticPanel extends StatelessWidget {\n  const _DidacticPanel({required this.exercise, required this.onSelect});", "class _DidacticPanel extends StatelessWidget {\n  const _DidacticPanel({required this.exercise, required this.onSelect, required this.exercises});\n  final List<AnatomyExercise> exercises;")
text = text.replace("_ExerciseSelector(selected: exercise, onSelect: onSelect, exercises: _exercisesList),", "_ExerciseSelector(selected: exercise, onSelect: onSelect, exercises: exercises),")
text = text.replace("_DidacticPanel(exercise: _exercise, onSelect: _select),", "_DidacticPanel(exercise: _exercise, onSelect: _select, exercises: _exercisesList),")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
