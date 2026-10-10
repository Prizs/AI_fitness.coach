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

# insert correct one inside _WorkoutScheduleScreenState before build
text = text.replace("  @override\n  Widget build(BuildContext context) {", '''  void _markExerciseFeedback(ExerciseItem ex) {
    setState(() {
      ex.isCompleted = !ex.isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {''', 1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
