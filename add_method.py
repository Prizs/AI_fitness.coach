import sys
path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

method = '''
  void _markExerciseFeedback(ExerciseItem ex) {
    setState(() {
      ex.isCompleted = !ex.isCompleted;
    });
  }

  @override
'''

text = text.replace("  @override\n  Widget build(BuildContext context)", method + "  Widget build(BuildContext context)")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
