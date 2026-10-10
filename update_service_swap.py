import sys

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

new_method = '''
  Future<Map<String, dynamic>?> swapExercise(
    String currentExerciseName,
    String primaryMuscle,
    int dayIndex,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('\/api/plans/alternative'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'current_exercise': currentExerciseName,
          'target_muscle': primaryMuscle,
          'equipment_available': true, // Podriamos leer del state, pero lo pasamos true por defecto
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final newExercise = jsonDecode(response.body);
        
        // Find and replace in local state
        if (week != null && week!['days'] != null) {
          final days = List.from(week!['days']);
          final dIdx = days.indexWhere((d) => d['weekday'] == dayIndex);
          if (dIdx != -1) {
            final exList = List.from(days[dIdx]['exercises'] ?? []);
            final eIdx = exList.indexWhere((e) => e['name'] == currentExerciseName);
            if (eIdx != -1) {
              exList[eIdx] = newExercise;
              days[dIdx]['exercises'] = exList;
              week!['days'] = days;
              notifyListeners();
              await DBHelper.instance.saveWeeklyPlan(jsonEncode(week));
              return newExercise;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }
'''
if "swapExercise(" not in text:
    text = text.replace("}\n", new_method + "}\n")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
