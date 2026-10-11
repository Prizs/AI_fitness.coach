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
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  Map<String, dynamic>? get today {
    final days = week?['days'];
    if (days is! List) return null;
    for (final entry in days) {
      if (entry is Map && entry['weekday'] == todayIndex) {
        return Map<String, dynamic>.from(entry);
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get days {
    final list = week?['days'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  Future<void> ensureLoaded(UserProfile? profile) {
    if (week != null) return Future<void>.value();
    if (_pending != null) return _pending!;
    _pending = _load(profile);
    return _pending!;
  }

  Future<void> _load(UserProfile? profile) async {
    isLoading = true;
    lastError = null;
    notifyListeners();

    try {
      final cachedJson = await DBHelper.instance.getCachedWeeklyPlan();
      if (cachedJson != null && cachedJson.trim().isNotEmpty) {
        try {
          week = jsonDecode(cachedJson) as Map<String, dynamic>?;
          if (week != null) {
            loadedFromCache = true;
            isLoading = false;
            _pending = null;
            notifyListeners();
            return;
          }
        } catch (_) {}
      }
    } catch (_) {}

    isLoading = false;
    _pending = null;
    notifyListeners();
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
              'equipment_available': equipmentAvailable,
              'intensity': intensityPreference,
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
        }
      } else {
        if (week == null) {
          lastError = 'El servidor devolvió un error (${response.statusCode}).';
        }
      }
    } catch (e) {
      if (week == null) {
        lastError = 'No se pudo conectar con el servidor ($e).';
      }
    } finally {
      isLoading = false;
      _pending = null;
      notifyListeners();
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
  }

  Future<Map<String, dynamic>?> swapExercise(
    String currentExerciseName,
    String primaryMuscle,
    int dayIndex,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/plans/alternative'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'current_exercise': currentExerciseName,
          'target_muscle': primaryMuscle,
          'equipment_available': true,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final newExercise = jsonDecode(response.body);
        if (week != null && week!['days'] != null) {
          final daysList = List.from(week!['days']);
          final dIdx = daysList.indexWhere((d) => d['weekday'] == dayIndex);
          if (dIdx != -1) {
            final exList = List.from(daysList[dIdx]['exercises'] ?? []);
            final eIdx = exList.indexWhere((e) => e['name'] == currentExerciseName);
            if (eIdx != -1) {
              exList[eIdx] = newExercise;
              daysList[dIdx]['exercises'] = exList;
              week!['days'] = daysList;
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

  Future<void> injectCustomPlanForToday(Map<String, dynamic> structuredPlan) async {
    final title = structuredPlan['title'] ?? 'Sesión Personalizada Coach IA';
    final exercises = structuredPlan['exercises'] ?? [];
    final nutrition = structuredPlan['nutrition'] ?? {};

    if (week == null) {
      week = {
        'id': 'coach_plan_${DateTime.now().millisecondsSinceEpoch}',
        'goal': title,
        'days': List.generate(7, (i) => {
          'weekday': i,
          'title': i == todayIndex ? title : 'Descanso / Rutina Base',
          'exercises': i == todayIndex ? exercises : [],
          'nutrition': i == todayIndex ? nutrition : {
            'desayuno': 'Proteína y carbohidratos complejos según objetivo.',
            'almuerzo': 'Comida balanceada: proteína magra, vegetales y carbohidratos.',
            'cena': 'Cena ligera alta en proteína.',
          },
        }),
      };
    } else {
      final currentDays = List.from(week!['days'] ?? []);
      final idx = currentDays.indexWhere((d) => d['weekday'] == todayIndex);
      final newDay = {
        'weekday': todayIndex,
        'title': title,
        'exercises': exercises,
        'nutrition': nutrition,
      };

      if (idx != -1) {
        currentDays[idx] = newDay;
      } else {
        currentDays.add(newDay);
      }
      week!['days'] = currentDays;
    }

    notifyListeners();
    try {
      await DBHelper.instance.saveWeeklyPlan(jsonEncode(week));
    } catch (_) {}
  }
}
