import os

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Fix _load method (add try-catch for cache jsonDecode)
old_load = '''      try {
        // 1. Intentar cargar desde SQLite
        final cachedJson = await DBHelper.instance.getCachedWeeklyPlan();
        if (cachedJson != null) {
          week = jsonDecode(cachedJson);
          loadedFromCache = true;
          isLoading = false;
          _pending = null;
          notifyListeners();
          // Opcional: cargar en segundo plano para actualizar
          _fetchAndSave(profile);
          return;
        }
        
        // 2. Si no hay cache, descargar de internet
        await _fetchAndSave(profile);
      } catch (error) {
        lastError = 'Error local: \.';'''

new_load = '''      try {
        // 1. Intentar cargar desde SQLite
        final cachedJson = await DBHelper.instance.getCachedWeeklyPlan();
        if (cachedJson != null) {
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
        }
        
        // 2. Si no hay cache, descargar de internet
        await _fetchAndSave(profile);
      } catch (error) {
        lastError = 'Hubo un error local cargando la rutina (Caché). Intenta crear una nueva.';'''

if old_load in text:
    text = text.replace(old_load, new_load)
else:
    print("Could not find old_load block to replace. Attempting fallback.")
    # Fallback to replace the exact error string
    text = text.replace("lastError = 'Error local: \.';", "lastError = 'Hubo un error local cargando la rutina (Caché). Intenta crear una nueva.';")


# 2. Fix _fetchAndSave method (add try-catch for API jsonDecode)
old_fetch = '''      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          week = data;
          loadedFromCache = false;
          lastError = null;
          await DBHelper.instance.saveWeeklyPlan(response.body);
        } else {
          if (week == null) lastError = 'Formato de plan inesperado.';
        }
      } else {
        if (week == null) lastError = 'El servidor respondiÃ³ \.';
      }
    } catch (error) {
      if (week == null) lastError = 'No se pudo conectar: \.';'''

new_fetch = '''      if (response.statusCode >= 200 && response.statusCode < 300) {
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
      if (week == null) lastError = 'Aviso: La generación tomó mucho tiempo o falló. Vuelve a intentarlo.';'''

if old_fetch in text:
    text = text.replace(old_fetch, new_fetch)
else:
    print("Could not find old_fetch block to replace. Attempting fallback.")
    text = text.replace("if (week == null) lastError = 'No se pudo conectar: \.';", "if (week == null) lastError = 'Aviso: La generación tomó mucho tiempo o falló. Vuelve a intentarlo.';")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
