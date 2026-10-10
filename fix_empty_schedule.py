import sys
path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

replacement = '''@override
  Widget build(BuildContext context) {
    if (_weeklySchedule.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F1D),
        appBar: AppBar(
          title: const Text('Cronograma Interactivo', style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: const Color(0xFF0F192B),
          elevation: 0,
        ),
        body: const Center(
          child: Text('No hay rutina generada.\\nPide a tu coach que genere un plan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        ),
      );
    }
    final currentDay = _weeklySchedule[_selectedDayIndex];'''

text = text.replace("@override\n  Widget build(BuildContext context) {\n    final currentDay = _weeklySchedule[_selectedDayIndex];", replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
