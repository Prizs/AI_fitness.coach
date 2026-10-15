import os

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import re

load_old = '''      try {
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

load_new = '''      try {
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
            // Json invalido en cache
            await DBHelper.instance.clearWeeklyPlan();
          }
        }
        
        // 2. Si no hay cache, descargar de internet
        await _fetchAndSave(profile);
      } catch (error) {
        lastError = 'Hubo un error cargando la rutina. Intenta crear una nueva.';'''

text = text.replace(load_old, load_new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
