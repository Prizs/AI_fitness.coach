import sys

path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

replacement = '''  List<DaySchedule> get _weeklySchedule {
    if (_service.week == null) return [];
    
    List<DaySchedule> schedule = [];
    try {
      final dynamic daysData = _service.week!['days'];
      List<dynamic> days = [];
      if (daysData is List) {
        days = daysData;
      } else if (daysData is Map) {
        days = daysData.values.toList();
      }
      
      for (int i = 0; i < 7; i++) {
        dynamic dayData;
        try {
          dayData = days.firstWhere((d) => (d is Map) && (d['weekday'] == i || d['weekday'] == i.toString()), orElse: () => null);
        } catch (_) {}
        
        if (dayData != null && dayData is Map) {
          List<ExerciseItem> exercises = [];
          if (dayData['exercises'] is List) {
            for (var ex in dayData['exercises']) {
              try {
                if (ex is Map<String, dynamic>) {
                  exercises.add(ExerciseItem.fromJson(ex));
                } else if (ex is Map) {
                  exercises.add(ExerciseItem.fromJson(Map<String, dynamic>.from(ex)));
                }
              } catch (e) {
                // Ignore invalid exercise
              }
            }
          }
          
          Map<String, String> meals = {};
          if (dayData['nutrition'] is Map) {
            final nut = dayData['nutrition'];
            if (nut['desayuno'] != null) meals['Desayuno'] = nut['desayuno'].toString();
            if (nut['almuerzo'] != null) meals['Almuerzo'] = nut['almuerzo'].toString();
            if (nut['cena'] != null) meals['Cena'] = nut['cena'].toString();
            if (nut['snack'] != null) meals['Snack'] = nut['snack'].toString();
          }
          
          schedule.add(DaySchedule(
            dayName: _days[i],
            title: dayData['title']?.toString() ?? 'Rutina del Día',
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
    } catch (e) {
      // If parsing fails completely, just return 7 rest days
      for (int i = 0; i < 7; i++) {
        schedule.add(DaySchedule(
          dayName: _days[i],
          title: 'Error de Formato',
          focus: 'Recuperación Activa',
          exercises: [],
          meals: {},
          isRestDay: true,
        ));
      }
    }
    return schedule;
  }'''

import re
text = re.sub(r'  List<DaySchedule> get _weeklySchedule \{.*?(?=@override\s+Widget build\(BuildContext context\))', replacement + '\n\n', text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
