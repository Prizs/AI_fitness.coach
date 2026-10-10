import sys
path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# remove bad _markExerciseFeedback
text = text.replace('''  void _markExerciseFeedback(ExerciseItem ex) {
    setState(() {
      ex.isCompleted = !ex.isCompleted;
    });
  }

  @override''', "  @override")

# insert correct one
text = text.replace("  List<DaySchedule> get _weeklySchedule {", '''  void _markExerciseFeedback(ExerciseItem ex) {
    setState(() {
      ex.isCompleted = !ex.isCompleted;
    });
  }

  List<DaySchedule> get _weeklySchedule {''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
