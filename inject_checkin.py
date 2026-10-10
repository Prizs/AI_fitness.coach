import sys

path = 'mobile_app/lib/screens/workouts_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import_stmt = "import 'package:mobile_app/widgets/pre_workout_checkin.dart';"
if import_stmt not in text:
    text = text.replace("import 'package:mobile_app/widgets/plan_options_sheet.dart';", "import 'package:mobile_app/widgets/plan_options_sheet.dart';\\n" + import_stmt)

# Add _startedDays
text = text.replace("final Set<int> _completed = {};", "final Set<int> _completed = {};\\n  final Set<int> _startedDays = {};")

# Find the start of the exercise list and hide it if not started
old_exercises_section = '''          // Lista de ejercicios (o descanso)
          if (exercises.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Día de descanso',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: exercises.length,'''

new_exercises_section = '''          // Lista de ejercicios (o descanso)
          if (exercises.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Día de descanso',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            )
          else if (!_startedDays.contains(_selectedDay))
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sports_martial_arts_rounded, size: 64, color: Color(0xFF8BE0C0)),
                    const SizedBox(height: 16),
                    const Text('¿Listo para darlo todo?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8BE0C0),
                        foregroundColor: const Color(0xFF0B1220),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      onPressed: () {
                        showPreWorkoutCheckin(context, onProceed: () {
                          setState(() => _startedDays.add(_selectedDay));
                        });
                      },
                      child: const Text('Iniciar entrenamiento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    )
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: exercises.length,'''

text = text.replace(old_exercises_section, new_exercises_section)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
