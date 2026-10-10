import sys

path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# IMPORTS
if "import 'package:mobile_app/services/weekly_plan_service.dart';" not in text:
    text = text.replace("import 'package:mobile_app/widgets/exercise_detail.dart';", 
'''import 'package:mobile_app/widgets/exercise_detail.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';''')

# CHANGE _WorkoutScheduleScreenState
import re
pattern = r"class _WorkoutScheduleScreenState extends State<WorkoutScheduleScreen> \{.*?(?=@override\s+Widget build\(BuildContext context\))"

replacement = '''class _WorkoutScheduleScreenState extends State<WorkoutScheduleScreen> {
  int _selectedDayIndex = 0;
  final List<String> _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  final WeeklyPlanService _service = WeeklyPlanService.instance;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = _service.todayIndex;
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  List<DaySchedule> get _weeklySchedule {
    if (_service.week == null) return [];
    
    List<DaySchedule> schedule = [];
    final days = _service.week!['days'] as List<dynamic>? ?? [];
    
    for (int i = 0; i < 7; i++) {
      final dayData = days.firstWhere((d) => d['weekday'] == i, orElse: () => null);
      if (dayData != null) {
        List<ExerciseItem> exercises = [];
        if (dayData['exercises'] != null) {
          for (var ex in dayData['exercises']) {
            exercises.add(ExerciseItem(
              name: ex['name'] ?? 'Ejercicio',
              sets: ex['sets'] ?? 3,
              reps: ex['reps']?.toString() ?? '10',
              animationKey: ex['animation_key'] ?? ex['name'] ?? '',
              primaryMuscle: ex['primary_muscle'] ?? 'General',
              secondaryMuscle: ex['secondary_muscle'] ?? '',
            ));
          }
        }
        
        Map<String, String> meals = {};
        if (dayData['nutrition'] != null) {
          final nut = dayData['nutrition'];
          if (nut['desayuno'] != null) meals['Desayuno'] = nut['desayuno'];
          if (nut['almuerzo'] != null) meals['Almuerzo'] = nut['almuerzo'];
          if (nut['cena'] != null) meals['Cena'] = nut['cena'];
          if (nut['snack'] != null) meals['Snack'] = nut['snack'];
        }
        
        schedule.add(DaySchedule(
          dayName: _days[i],
          title: dayData['title'] ?? 'Rutina del Día',
          focus: 'Enfoque General',
          exercises: exercises,
          meals: meals,
        ));
      } else {
        schedule.add(DaySchedule(
          dayName: _days[i],
          title: 'Día de Descanso',
          focus: 'Recuperación Activa',
          exercises: [],
          meals: {},
          isRestDay: true,
        ));
      }
    }
    return schedule;
  }

'''
text = re.sub(pattern, replacement, text, flags=re.DOTALL)

# CHANGE 3D BUTTON TO FETCH GIFS
# Search for: label: const Text('3D', style: TextStyle(fontSize: 12)),
# And replace the onPressed block

replacement_btn = '''onPressed: () async {
                        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                        List<AnatomyExercise> dyn = [];
                        for (var e in currentDay.exercises) {
                          String url = '';
                          try {
                            final res = await http.get(Uri.parse('https://ai-fitness-coach-818a.onrender.com/api/exercises/gif?query=' + Uri.encodeComponent(e.name)));
                            if (res.statusCode == 200) {
                              url = jsonDecode(res.body)['url'] ?? '';
                            }
                          } catch (_) {}
                          dyn.add(AnatomyExercise(
                            id: e.name,
                            name: e.name,
                            shortName: e.name,
                            gifUrl: url,
                            agonist: e.primaryMuscle,
                            synergists: [e.secondaryMuscle],
                            biomechanics: 'Activación dinámica sugerida por IA.',
                            tempo: '3-1-1',
                            posture: 'Mantén la postura natural.',
                            warning: 'Consulta a tu entrenador si sientes dolor.'
                          ));
                        }
                        if (!mounted) return;
                        Navigator.pop(context); // close dialog
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: const Color(0xFF0F192B),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                          builder: (ctx) => _Interactive3DViewer(exercise: ex, dynamicExercises: dyn),
                        );
                      },'''

text = re.sub(r"onPressed: \(\) \{[^{}]*// Modal 3D didáctico[^{}]*showModalBottomSheet\([^;]+;\s*\},", replacement_btn, text, flags=re.DOTALL)

# CHANGE _Interactive3DViewer
# Add dynamicExercises
text = text.replace("class _Interactive3DViewer extends StatelessWidget {\n  const _Interactive3DViewer({required this.exercise});", "class _Interactive3DViewer extends StatelessWidget {\n  const _Interactive3DViewer({required this.exercise, this.dynamicExercises});\n  final List<AnatomyExercise>? dynamicExercises;")
text = text.replace("ExerciseDetailView(\n            animationKey: exercise.animationKey,\n            primaryMuscle: exercise.primaryMuscle,\n            secondaryMuscle: exercise.secondaryMuscle,\n          ),", "ExerciseDetailView(\n            animationKey: exercise.animationKey,\n            primaryMuscle: exercise.primaryMuscle,\n            secondaryMuscle: exercise.secondaryMuscle,\n            dynamicExercises: dynamicExercises,\n          ),")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
