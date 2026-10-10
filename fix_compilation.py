import sys

path = 'mobile_app/lib/screens/workouts_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Fix literal \n
text = text.replace("\\n", "\n")

# Fix _selectedDay in _DayCard
old_call = '''onPressed: () => _openExercisePreview(context, item, exercises, _selectedDay),'''
new_call = '''onPressed: () => _openExercisePreview(context, item, exercises, day['weekday']),'''
text = text.replace(old_call, new_call)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
