import sys

path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = '''          ExerciseDetailView(
            animationKey: exercise.animationKey,
            primaryMuscle: exercise.primaryMuscle,
            secondaryMuscle: exercise.secondaryMuscle,
            height: 300,
            dynamicExercises: dynamicExercises,
          ),'''

new_code = '''          ExerciseDetailView(
            animationKey: exercise.name, // Use name as ID to match dynamicExercises
            primaryMuscle: exercise.primaryMuscle,
            secondaryMuscle: exercise.secondaryMuscle,
            height: 300,
            dynamicExercises: dynamicExercises,
          ),'''

text = text.replace(old_code, new_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
