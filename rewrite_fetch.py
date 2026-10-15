import os

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import re
pattern = r'Future<void> _fetchAndSave\(.*?finally \{'
replacement = '''Future<void> _fetchAndSave(
    UserProfile? profile, {
    String experienceLevel = 'Intermedio',
    String intensityPreference = 'Medio',
    bool equipmentAvailable = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('\/api/plans/weekly'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'goal': 'mejorar condicion fisica',
              'level': 'principiante',
              'age': profile?.age ?? 25,
              'weight': profile?.weight ?? 70,
              'food_allergies': profile?.foodAllergies,
              'current_injuries': profile?.currentInjuries,
              'areas_to_avoid': profile?.areasToAvoid,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            week = data;
            loadedFromCache = false;
            lastError = null;
            await DBHelper.instance.saveWeeklyPlan(response.body);
          } else {
            if (week == null) lastError = 'Formato de plan inesperado (no es un objeto JSON).';
          }
        } catch (e) {
          if (week == null) lastError = 'Error procesando rutina: La IA no respondió con JSON válido. Reintenta.';
        }
      } else {
        if (week == null) lastError = 'El servidor devolvió un error: \.';
      }
    } catch (error) {
      if (week == null) lastError = 'Aviso: La generaciÃ³n de IA tomÃ³ mucho tiempo o fallÃ³. Vuelve a intentarlo.';
    } finally {'''

text = re.sub(pattern, replacement, text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
