import sys

path = 'mobile_app/lib/widgets/exercise_detail.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_route = '''                  MaterialPageRoute(
                    builder: (_) => AnatomyWorkoutScreen(
                      initialExerciseId: _mapAnimKeyToAnatomyId(animationKey),
                      dynamicExercises: dynamicExercises,
                    ),
                  ),'''

new_route = '''                  MaterialPageRoute(
                    builder: (_) => AnatomyWorkoutScreen(
                      initialExerciseId: dynamicExercises != null ? animationKey : _mapAnimKeyToAnatomyId(animationKey),
                      dynamicExercises: dynamicExercises,
                    ),
                  ),'''

text = text.replace(old_route, new_route)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
