import sys
path = 'mobile_app/lib/widgets/exercise_detail.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

if 'final List<AnatomyExercise>? dynamicExercises;' not in text:
    text = text.replace("final String? secondaryMuscle;\n  final double height;", "final String? secondaryMuscle;\n  final double height;\n  final List<AnatomyExercise>? dynamicExercises;")
    text = text.replace("this.secondaryMuscle,\n    this.height = 320,\n  });", "this.secondaryMuscle,\n    this.height = 320,\n    this.dynamicExercises,\n  });")
    text = text.replace("initialExerciseId: _mapAnimKeyToAnatomyId(animationKey),\n                  ),", "initialExerciseId: _mapAnimKeyToAnatomyId(animationKey),\n                    dynamicExercises: dynamicExercises,\n                  ),")

if "import 'package:mobile_app/models/anatomy_exercise.dart';" not in text:
    text = text.replace("import 'package:mobile_app/screens/anatomy_workout_screen.dart';", "import 'package:mobile_app/screens/anatomy_workout_screen.dart';\nimport 'package:mobile_app/models/anatomy_exercise.dart';")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
