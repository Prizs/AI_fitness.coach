import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/models/user_profile.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/database/db_helper.dart';

class WeeklyPlanService extends ChangeNotifier {
  static String get apiBaseUrl => AuthService.apiBaseUrl;

  static final WeeklyPlanService instance = WeeklyPlanService();

  Map<String, dynamic>? week;
  String? lastError;
  bool isLoading = false;
  bool loadedFromCache = false;

  Future<void>? _pending;

  int get todayIndex => DateTime.now().weekday - 1;
  String get todayName => _weekdayNames[todayIndex];

  static const List<String> _weekdayNames = [
    'Lunes',
    'Martes',
    'MiÃ©rcoles',
    'Jueves',
    'Viernes',
    'SÃ¡bado',
    'Domingo',
  ];

  Map<String, dynamic>? get today {
    final days = week?['days'];
    if (days is! List) return null;
    for (final entry in days) {
      if (entry is Map && entry['weekday'] == todayIndex) {
        return Map<String, dynamic>.from(entry);
      
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
}
    
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
}
    return null;
  
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
}

  List<Map<String, dynamic>> get days {
    final raw = week?['days'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  
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
}

  Future<void> ensureLoaded(UserProfile? profile) {
    if (week != null) return Future<void>.value();
    final pending = _pending;
    if (pending != null) return pending;

    final future = _load(profile);
    _pending = future;
    return future;
  
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
}

  Future<void> _load(UserProfile? profile) async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    
    try {
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
}
      
      // 2. Si no hay cache, descargar de internet
      await _fetchAndSave(profile);
    } catch (error) {
      lastError = 'Hubo un error local cargando la rutina (Caché). Intenta crear una nueva.';
      isLoading = false;
      _pending = null;
      notifyListeners();
    
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
}
  
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
}
  
  Future<void> _fetchAndSave(
    UserProfile? profile, {
    String goal = 'Mejorar condición física general',
    String experienceLevel = 'Intermedio',
    String intensityPreference = 'Medio',
    bool equipmentAvailable = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/api/plans/weekly'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'goal': goal,
              'level': experienceLevel.toLowerCase(),
              'age': profile?.age ?? 25,
              'weight': profile?.weight ?? 70,
              'food_allergies': profile?.foodAllergies,
              'current_injuries': profile?.currentInjuries,
              'areas_to_avoid': profile?.areasToAvoid,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          week = data;
          loadedFromCache = false;
          lastError = null;
          await DBHelper.instance.saveWeeklyPlan(response.body);
        } else {
          if (week == null) lastError = 'Formato de plan inesperado.';
        
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
}
      } else {
        if (week == null) lastError = 'El servidor respondiÃ³ ${response.statusCode}.';
      
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
}
    } catch (error) {
      if (week == null) lastError = 'Aviso: La generación tomó mucho tiempo o falló. Vuelve a intentarlo.';
    } finally {
      isLoading = false;
      _pending = null;
      notifyListeners();
    
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
}
  
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
}

  Future<void> refresh(
    UserProfile? profile, {
    String goal = 'Mejorar condición física general',
    String experienceLevel = 'Intermedio',
    String intensityPreference = 'Medio',
    bool equipmentAvailable = true,
  }) async {
    isLoading = true;
    notifyListeners();
    await _fetchAndSave(
      profile,
      goal: goal,
      experienceLevel: experienceLevel,
      intensityPreference: intensityPreference,
      equipmentAvailable: equipmentAvailable,
    );
  
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
}

  Future<void> injectCustomPlanForToday(Map<String, dynamic> structuredPlan) async {
    if (week == null) return;
    final currentDays = List.from(week!['days'] ?? []);
    final idx = currentDays.indexWhere((d) => d['weekday'] == todayIndex);
    
    final newDay = {
      'weekday': todayIndex,
      'title': structuredPlan['title'] ?? 'SesiÃ³n Personalizada',
      'exercises': structuredPlan['exercises'] ?? [],
      'nutrition': structuredPlan['nutrition'] ?? {},
    };

    if (idx != -1) {
      currentDays[idx] = newDay;
    } else {
      currentDays.add(newDay);
    
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
}
    
    week!['days'] = currentDays;
    notifyListeners();
    await DBHelper.instance.saveWeeklyPlan(jsonEncode(week));
  
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
}

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
}
