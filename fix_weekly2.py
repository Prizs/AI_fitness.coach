import os
path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace jsonDecode(cachedJson)
old_cache = '''        if (cachedJson != null) {
          week = jsonDecode(cachedJson);
          loadedFromCache = true;
          isLoading = false;
          _pending = null;
          notifyListeners();
          // Opcional: cargar en segundo plano para actualizar
          _fetchAndSave(profile);
          return;
        }'''

new_cache = '''        if (cachedJson != null) {
          try {
            week = jsonDecode(cachedJson);
            loadedFromCache = true;
            isLoading = false;
            _pending = null;
            notifyListeners();
            // Opcional: cargar en segundo plano para actualizar
            _fetchAndSave(profile);
            return;
          } catch (e) {
            print("Cache invalido");
          }
        }'''
text = text.replace(old_cache.replace('\n', '\r\n'), new_cache.replace('\n', '\r\n'))
text = text.replace(old_cache, new_cache) # Just in case

# Replace jsonDecode(response.body)
old_api = '''        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          week = data;
          loadedFromCache = false;
          lastError = null;
          await DBHelper.instance.saveWeeklyPlan(response.body);
        } else {
          if (week == null) lastError = 'Formato de plan inesperado.';
        }'''

new_api = '''        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            week = data;
            loadedFromCache = false;
            lastError = null;
            await DBHelper.instance.saveWeeklyPlan(response.body);
          } else {
            if (week == null) lastError = 'Formato de plan inesperado.';
          }
        } catch(e) {
          if (week == null) lastError = 'Error de formato JSON desde la IA.';
        }'''
text = text.replace(old_api.replace('\n', '\r\n'), new_api.replace('\n', '\r\n'))
text = text.replace(old_api, new_api) # Just in case

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
