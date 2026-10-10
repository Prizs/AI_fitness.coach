import sys
path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# We need to import WeeklyPlanService
if "import 'package:mobile_app/services/weekly_plan_service.dart';" not in text:
    text = text.replace("import 'package:mobile_app/widgets/exercise_detail.dart';", "import 'package:mobile_app/widgets/exercise_detail.dart';\nimport 'package:mobile_app/services/weekly_plan_service.dart';")

# We will change how _weeklySchedule is built.
# Let's completely replace the class _WorkoutScheduleScreenState extends State<WorkoutScheduleScreen> { ... } up to the uild method.
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
        
        List<NutritionItem> nutrition = [];
        if (dayData['nutrition'] != null) {
          final nut = dayData['nutrition'];
          if (nut['desayuno'] != null) nutrition.add(NutritionItem(meal: 'Desayuno', description: nut['desayuno']));
          if (nut['almuerzo'] != null) nutrition.add(NutritionItem(meal: 'Almuerzo', description: nut['almuerzo']));
          if (nut['cena'] != null) nutrition.add(NutritionItem(meal: 'Cena', description: nut['cena']));
          if (nut['snack'] != null) nutrition.add(NutritionItem(meal: 'Snack', description: nut['snack']));
        }
        
        schedule.add(DaySchedule(
          dayName: _days[i],
          title: dayData['title'] ?? 'Rutina del Día',
          focus: 'Enfoque General',
          exercises: exercises,
          nutrition: nutrition,
        ));
      } else {
        schedule.add(DaySchedule(
          dayName: _days[i],
          title: 'Día de Descanso',
          focus: 'Recuperación Activa',
          exercises: [],
          nutrition: [],
        ));
      }
    }
    return schedule;
  }

'''

text = re.sub(pattern, replacement, text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
