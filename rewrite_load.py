import os
import re

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# find _load function
pattern = r'Future<void> _load\(UserProfile\? profile\) async \{.*?\n    \n  Future<Map<String, dynamic>\?> swapExercise'

replacement = '''Future<void> _load(UserProfile? profile) async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    
    try {
      final cachedJson = await DBHelper.instance.getCachedWeeklyPlan();
      if (cachedJson != null) {
        try {
          week = jsonDecode(cachedJson);
          loadedFromCache = true;
          isLoading = false;
          _pending = null;
          notifyListeners();
          _fetchAndSave(profile);
          return;
        } catch (e) {
          // ignore cache if json is bad
          print("Cache error: \");
        }
      }
      await _fetchAndSave(profile);
    } catch (error) {
      lastError = 'Hubo un error cargando la rutina (Caché). Intenta crear una nueva.';
      isLoading = false;
      _pending = null;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> swapExercise'''

text = re.sub(pattern, replacement, text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
