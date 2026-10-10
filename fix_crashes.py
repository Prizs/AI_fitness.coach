import sys

path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Fix 1: Use ExerciseItem.fromJson to safely parse JSON and prevent TypeError crash
old_loop = '''          for (var ex in dayData['exercises']) {
            exercises.add(ExerciseItem(
              name: ex['name'] ?? 'Ejercicio',
              sets: ex['sets'] ?? 3,
              reps: ex['reps']?.toString() ?? '10',
              animationKey: ex['animation_key'] ?? ex['name'] ?? '',
              primaryMuscle: ex['primary_muscle'] ?? 'General',
              secondaryMuscle: ex['secondary_muscle'] ?? '',
            ));
          }'''

new_loop = '''          for (var ex in dayData['exercises']) {
            try {
              exercises.add(ExerciseItem.fromJson(ex as Map<String, dynamic>));
            } catch (e) {
              // Ignore invalid exercise
            }
          }'''

text = text.replace(old_loop, new_loop)

# Fix 2: Pass dynamicExercises down to ExerciseDetailView
old_detail = '''          ExerciseDetailView(
            animationKey: exercise.animationKey,
            primaryMuscle: exercise.primaryMuscle,
            secondaryMuscle: exercise.secondaryMuscle,
            height: 300,
          ),'''

new_detail = '''          ExerciseDetailView(
            animationKey: exercise.animationKey,
            primaryMuscle: exercise.primaryMuscle,
            secondaryMuscle: exercise.secondaryMuscle,
            height: 300,
            dynamicExercises: dynamicExercises,
          ),'''

text = text.replace(old_detail, new_detail)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
