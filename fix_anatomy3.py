import sys
path = 'mobile_app/lib/screens/anatomy_workout_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("class _ExerciseSelector extends StatelessWidget {\n  const _ExerciseSelector({required this.selected, required this.onSelect});", "class _ExerciseSelector extends StatelessWidget {\n  const _ExerciseSelector({required this.selected, required this.onSelect, required this.exercises});\n  final List<AnatomyExercise> exercises;")
text = text.replace("itemCount: _exercisesList.length,", "itemCount: exercises.length,")
text = text.replace("final exercise = _exercisesList[index];", "final exercise = exercises[index];")
text = text.replace("_ExerciseSelector(selected: _exercise, onSelect: _select),", "_ExerciseSelector(selected: _exercise, onSelect: _select, exercises: _exercisesList),")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
