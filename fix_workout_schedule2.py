import sys
import re
path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# We need to import anatomy_exercise.dart if not present
if "import 'package:mobile_app/models/anatomy_exercise.dart';" not in text:
    text = text.replace("import 'package:mobile_app/widgets/exercise_detail.dart';", "import 'package:mobile_app/widgets/exercise_detail.dart';\nimport 'package:mobile_app/models/anatomy_exercise.dart';")

# Change class _Interactive3DViewer to accept dynamicExercises
text = text.replace("const _Interactive3DViewer({required this.exercise});", "const _Interactive3DViewer({required this.exercise, this.dynamicExercises});\n  final List<AnatomyExercise>? dynamicExercises;")
text = text.replace("ExerciseDetailView(\n            animationKey: exercise.animationKey,\n            primaryMuscle: exercise.primaryMuscle,\n            secondaryMuscle: exercise.secondaryMuscle,\n          ),", "ExerciseDetailView(\n            animationKey: exercise.animationKey,\n            primaryMuscle: exercise.primaryMuscle,\n            secondaryMuscle: exercise.secondaryMuscle,\n            dynamicExercises: dynamicExercises,\n          ),")

# Change uilder: (ctx) => _Interactive3DViewer(exercise: ex) to build dynamicExercises
replacement_builder = '''builder: (ctx) {
                            List<AnatomyExercise> dyn = currentDay.exercises.map((e) => AnatomyExercise(
                              id: e.animationKey,
                              name: e.name,
                              shortName: e.name,
                              gifUrl: 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/' + e.animationKey + '/0.jpg',
                              agonist: e.primaryMuscle,
                              synergists: [e.secondaryMuscle],
                              biomechanics: 'Activación dinámica sugerida por IA.',
                              tempo: '3-1-1',
                              posture: 'Mantén la postura natural.',
                              warning: 'Consulta a tu entrenador si sientes dolor.',
                            )).toList();
                            return _Interactive3DViewer(exercise: ex, dynamicExercises: dyn);
                          }'''

text = re.sub(r"builder: \(ctx\) => _Interactive3DViewer\(exercise: ex\),", replacement_builder, text)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
