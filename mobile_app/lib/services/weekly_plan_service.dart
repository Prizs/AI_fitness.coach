import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/models/user_profile.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/database/db_helper.dart';

class WeeklyPlanService extends ChangeNotifier {
  static String get apiBaseUrl => AuthService.apiBaseUrl;

  static final WeeklyPlanService instance = WeeklyPlanService();

  Map<String, dynamic>? week;
  Map<String, dynamic>? upcomingWeek;
  String? lastError;
  bool isLoading = false;
  bool loadedFromCache = false;

  Future<void>? _pending;

  static const List<String> availableGoals = [
    'Pérdida de grasa y definición',
    'Aumentar masa muscular',
    'Ganar fuerza funcional',
    'Salud integral y movilidad',
    'Acondicionamiento físico general',
  ];

  String _userGoal = 'Acondicionamiento físico general';
  String _userLevel = 'Principiante';
  String _userIntensity = 'Baja';
  Set<int> _completedDaysSet = {};
  Map<String, dynamic> _workoutStats = {
    'current_streak': 0,
    'best_streak': 0,
    'total_sessions': 0,
    'last_rpe': 7,
    'last_feeling': 'Con energía',
  };

  String get userGoal => _userGoal;
  String get userLevel => _userLevel;
  String get userIntensity => _userIntensity;
  Set<int> get completedDays => _completedDaysSet;
  int get currentStreak => (_workoutStats['current_streak'] as int?) ?? 0;
  int get bestStreak => (_workoutStats['best_streak'] as int?) ?? 0;
  int get totalCompletedSessions => (_workoutStats['total_sessions'] as int?) ?? 0;
  int get lastRpe => (_workoutStats['last_rpe'] as int?) ?? 7;
  String get lastFeeling => (_workoutStats['last_feeling'] as String?) ?? 'Con energía';

  double get adherenceRate {
    final scheduled = days.where((d) => (d['exercises'] as List?)?.isNotEmpty == true).length;
    if (scheduled == 0) return 100.0;
    final done = days.where((d) {
      final isTraining = (d['exercises'] as List?)?.isNotEmpty == true;
      return isTraining && _completedDaysSet.contains(d['weekday']);
    }).length;
    return ((done / scheduled) * 100).clamp(0.0, 100.0);
  }

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
    final mapped = list.whereType<Map>().map((entry) {
      final m = Map<String, dynamic>.from(entry);
      final w = (m['weekday'] is int) ? (m['weekday'] as int).clamp(0, 6) : 0;
      m['weekday'] = w;
      if (m['weekday_name'] == null ||
          m['weekday_name'].toString().trim().isEmpty) {
        m['weekday_name'] = _weekdayNames[w];
      }
      return m;
    }).toList();
    mapped.sort((a, b) => (a['weekday'] as int).compareTo(b['weekday'] as int));
    return mapped;
  }

  DateTime get currentWeekMonday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  }

  DateTime get currentWeekSunday => currentWeekMonday.add(const Duration(days: 6));

  DateTime get nextCycleMonday => currentWeekMonday.add(const Duration(days: 7));

  String get cycleDateRangeStr {
    final m = currentWeekMonday;
    final s = currentWeekSunday;
    final mMonth = m.month < 10 ? '0${m.month}' : '${m.month}';
    final sMonth = s.month < 10 ? '0${s.month}' : '${s.month}';
    return '${m.day}/$mMonth al ${s.day}/$sMonth';
  }

  bool get hasUpcomingPlan =>
      upcomingWeek != null &&
      upcomingWeek!['days'] is List &&
      (upcomingWeek!['days'] as List).isNotEmpty;

  String get upcomingCycleRangeStr {
    final range = upcomingWeek?['cycle_range_str']?.toString();
    if (range != null && range.trim().isNotEmpty) return range;
    final nextM = nextCycleMonday;
    final nextS = nextM.add(const Duration(days: 6));
    final mMonth = nextM.month < 10 ? '0${nextM.month}' : '${nextM.month}';
    final sMonth = nextS.month < 10 ? '0${nextS.month}' : '${nextS.month}';
    return '${nextM.day}/$mMonth al ${nextS.day}/$sMonth';
  }

  String get upcomingCycleStartDate =>
      upcomingWeek?['cycle_start_date']?.toString() ??
      upcomingWeek?['week_monday']?.toString() ??
      nextCycleMonday.toIso8601String();

  List<Map<String, dynamic>> get upcomingDays {
    final list = upcomingWeek?['days'];
    if (list is! List) return const [];
    final mapped = list.whereType<Map>().map((entry) {
      final m = Map<String, dynamic>.from(entry);
      final w = (m['weekday'] is int) ? (m['weekday'] as int).clamp(0, 6) : 0;
      m['weekday'] = w;
      if (m['weekday_name'] == null ||
          m['weekday_name'].toString().trim().isEmpty) {
        m['weekday_name'] = _weekdayNames[w];
      }
      return m;
    }).toList();
    mapped.sort((a, b) => (a['weekday'] as int).compareTo(b['weekday'] as int));
    return mapped;
  }


  bool get isTodayHomeWorkout {
    final t = today;
    return t != null && t['is_home_workout'] == true;
  }

  Future<void> substituteTodayWithHomeWorkout({
    required String title,
    required List<dynamic> exercises,
  }) async {
    if (week == null || week!['days'] is! List) return;
    final daysList = List<dynamic>.from(week!['days']);
    for (int i = 0; i < daysList.length; i++) {
      if (daysList[i] is Map && daysList[i]['weekday'] == todayIndex) {
        final current = Map<String, dynamic>.from(daysList[i]);
        current['title'] = title;
        current['exercises'] = exercises;
        current['is_home_workout'] = true;
        daysList[i] = current;
        break;
      }
    }
    week!['days'] = daysList;
    notifyListeners();
    try {
      await DBHelper.instance.saveWeeklyPlan(jsonEncode(week!));
    } catch (_) {}
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'cached_weekly_plan_v1', value: jsonEncode(week!));
    } catch (_) {}
  }


  /// Cancela la sesión del día de hoy por descanso o molestia física, guardando el respaldo de lo previsto originalmente.
  Future<void> cancelTodayRoutineForRest({String reason = "Descanso y recuperación por molestia física"}) async {
    if (week == null || week!['days'] is! List) return;
    final daysList = List<dynamic>.from(week!['days']);
    for (int i = 0; i < daysList.length; i++) {
      if (daysList[i] is Map && daysList[i]['weekday'] == todayIndex) {
        final current = Map<String, dynamic>.from(daysList[i]);
        current['original_title'] ??= current['title'];
        current['original_exercises'] ??= current['exercises'];
        current['title'] = 'Descanso y Recuperación ($reason)';
        current['exercises'] = <dynamic>[];
        current['is_rest'] = true;
        current['is_cancelled_for_rest'] = true;
        current['cancel_reason'] = reason;
        daysList[i] = current;
        break;
      }
    }
    week!['days'] = daysList;
    notifyListeners();
    try {
      await DBHelper.instance.saveWeeklyPlan(jsonEncode(week!));
    } catch (_) {}
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'cached_weekly_plan_v1', value: jsonEncode(week!));
    } catch (_) {}
  }

  /// Adapta los días restantes de la semana en curso ante un reporte de molestia articular (tobillo, rodilla, hombro, lumbar, etc.).
  Future<int> adaptRemainingDaysForInjury(String zoneKey, String zoneLabel) async {
    if (week == null || week!['days'] is! List) return 0;
    final daysList = List<dynamic>.from(week!['days']);
    int adaptedCount = 0;

    final lowerKey = zoneKey.toLowerCase();

    for (int i = 0; i < daysList.length; i++) {
      if (daysList[i] is! Map) continue;
      final current = Map<String, dynamic>.from(daysList[i]);
      final int w = (current['weekday'] is int) ? current['weekday'] as int : 0;

      // Adaptar desde hoy en adelante
      if (w >= todayIndex) {
        final rawExs = current['exercises'];
        if (rawExs is List && rawExs.isNotEmpty) {
          current['original_title'] ??= current['title'];
          current['original_exercises'] ??= List<dynamic>.from(rawExs);

          final List<Map<String, dynamic>> safeExercises = [];

          if (lowerKey.contains('tobillo') || lowerKey.contains('pie')) {
            safeExercises.addAll([
              {
                'name': 'Press de pecho con mancuernas sentado con soporte',
                'sets': 3,
                'reps': '10-12',
                'primary_muscle': 'Pectorales',
                'secondary_muscle': 'Tríceps',
                'intensity_level': 'Intermedio (Intensidad Media)',
                'biomechanics': 'Posición sentada con espalda apoyada firmemente; cero carga sobre el pie o tobillo.',
              },
              {
                'name': 'Remo con mancuernas con soporte en banco inclinado',
                'sets': 3,
                'reps': '10-12',
                'primary_muscle': 'Dorsales',
                'secondary_muscle': 'Bíceps',
                'intensity_level': 'Intermedio (Intensidad Media)',
                'biomechanics': 'Pecho apoyado en banco; anula cualquier participación de miembros inferiores.',
              },
              {
                'name': 'Dead Bug en colchoneta (Core sin apoyo plantar)',
                'sets': 3,
                'reps': '12 por lado',
                'primary_muscle': 'Core / Recto Abdominal',
                'secondary_muscle': 'Estabilizadores',
                'intensity_level': 'Básico (Intensidad Baja)',
                'biomechanics': 'Espalda baja pegada al suelo con pies en el aire sin apoyar en el suelo.',
              },
              {
                'name': 'Curl de bíceps sentado con mancuernas',
                'sets': 3,
                'reps': '12-15',
                'primary_muscle': 'Bíceps Braquial',
                'secondary_muscle': 'Antebrazos',
                'intensity_level': 'Intermedio (Intensidad Media)',
                'biomechanics': 'Aislamiento estricto de brazos sentado en banco.',
              },
            ]);
            current['title'] = 'Tren Superior y Core Sentado (Adaptado por $zoneLabel)';
          } else if (lowerKey.contains('rodilla')) {
            safeExercises.addAll([
              {
                'name': 'Puente de glúteos en suelo con control (Glute Bridge)',
                'sets': 3,
                'reps': '12-15',
                'primary_muscle': 'Glúteos',
                'secondary_muscle': 'Isquiotibiales',
                'intensity_level': 'Básico (Intensidad Baja)',
                'biomechanics': 'Empuje exclusivo de cadera con ángulo suave de rodilla sin compresión femororrotuliana.',
              },
              {
                'name': 'Elevaciones laterales de pierna acostado en colchoneta',
                'sets': 3,
                'reps': '15 por lado',
                'primary_muscle': 'Glúteo Medio',
                'secondary_muscle': 'Caderas',
                'intensity_level': 'Básico (Intensidad Baja)',
                'biomechanics': 'Cadena abierta sin peso corporal sobre la articulación de la rodilla.',
              },
              {
                'name': 'Press de pecho con mancuernas en banco plano',
                'sets': 3,
                'reps': '10-12',
                'primary_muscle': 'Pectorales',
                'secondary_muscle': 'Tríceps',
                'intensity_level': 'Intermedio (Intensidad Media)',
                'biomechanics': 'Pies apoyados planos sin tensión en rodillas.',
              },
              {
                'name': 'Plancha frontal isométrica en antebrazos',
                'sets': 3,
                'reps': '30-45 seg',
                'primary_muscle': 'Core / Abdomen',
                'secondary_muscle': 'Estabilizadores',
                'intensity_level': 'Intermedio (Intensidad Media)',
                'biomechanics': 'Cuerpo alineado sin flexión de rodilla.',
              },
            ]);
            current['title'] = 'Torso y Cadena Posterior Suave (Adaptado por $zoneLabel)';
          } else if (lowerKey.contains('hombro')) {
            safeExercises.addAll([
              {
                'name': 'Sentadilla libre asistida con peso corporal',
                'sets': 3,
                'reps': '12-15',
                'primary_muscle': 'Cuádriceps',
                'secondary_muscle': 'Glúteos',
                'intensity_level': 'Básico (Intensidad Baja)',
                'biomechanics': 'Brazos relajados al frente o cruzados al pecho sin tensión en hombros.',
              },
              {
                'name': 'Prensa de piernas inclinada (o Sentadilla en silla)',
                'sets': 3,
                'reps': '10-12',
                'primary_muscle': 'Cuádriceps',
                'secondary_muscle': 'Isquiotibiales',
                'intensity_level': 'Intermedio (Intensidad Media)',
                'biomechanics': 'Cero participación de la articulación glenohumeral.',
              },
              {
                'name': 'Puente de glúteos en suelo',
                'sets': 3,
                'reps': '12-15',
                'primary_muscle': 'Glúteos',
                'secondary_muscle': 'Isquiotibiales',
                'intensity_level': 'Básico (Intensidad Baja)',
                'biomechanics': 'Manos en el suelo a los costados sin empuje.',
              },
              {
                'name': 'Curl de bíceps con mancuernas y codos pegados al cuerpo',
                'sets': 3,
                'reps': '12',
                'primary_muscle': 'Bíceps',
                'secondary_muscle': 'Antebrazos',
                'intensity_level': 'Básico (Intensidad Baja)',
                'biomechanics': 'Codos fijados a las costillas; anula cualquier elevación o abducción del hombro.',
              },
            ]);
            current['title'] = 'Piernas y Glúteos (Adaptado por $zoneLabel)';
          } else if (lowerKey.contains('lumbar') || lowerKey.contains('espalda')) {
            safeExercises.addAll([
              {
                'name': 'Remo con mancuernas con pecho apoyado en banco inclinado',
                'sets': 3,
                'reps': '10-12',
                'primary_muscle': 'Dorsales',
                'secondary_muscle': 'Bíceps',
                'intensity_level': 'Intermedio (Intensidad Media)',
                'biomechanics': 'Soporte esternal total; cero momento flexor o carga en vértebras lumbares.',
              },
              {
                'name': 'Press de pecho en banco plano con piernas flexionadas',
                'sets': 3,
                'reps': '10-12',
                'primary_muscle': 'Pectorales',
                'secondary_muscle': 'Tríceps',
                'intensity_level': 'Intermedio (Intensidad Media)',
                'biomechanics': 'Zona lumbar plana sobre el banco sin arqueo excesivo.',
              },
              {
                'name': 'Sentadilla isométrica en pared con espalda apoyada (Wall Sit)',
                'sets': 3,
                'reps': '30-40 seg',
                'primary_muscle': 'Cuádriceps',
                'secondary_muscle': 'Glúteos',
                'intensity_level': 'Intermedio (Intensidad Media)',
                'biomechanics': 'Columna completamente descargada y apoyada contra la pared.',
              },
              {
                'name': 'Bird Dog controlado con pausa isométrica',
                'sets': 3,
                'reps': '10 por lado',
                'primary_muscle': 'Estabilizadores Profundos',
                'secondary_muscle': 'Glúteos',
                'intensity_level': 'Básico (Intensidad Baja)',
                'biomechanics': 'Columna en posición neutra estricta sin hiperlordosis.',
              },
            ]);
            current['title'] = 'Ejercicios con Soporte de Espalda (Adaptado por $zoneLabel)';
          } else {
            // Adaptación general segura
            safeExercises.addAll([
              {
                'name': 'Press con mancuernas en banco plano con apoyo',
                'sets': 3,
                'reps': '10-12',
                'primary_muscle': 'Pectorales',
                'secondary_muscle': 'Tríceps',
                'intensity_level': 'Básico (Intensidad Baja)',
                'biomechanics': 'Movimiento guiado y controlado con apoyo completo.',
              },
              {
                'name': 'Remo sentado con soporte con bandas o mancuernas',
                'sets': 3,
                'reps': '10-12',
                'primary_muscle': 'Dorsales',
                'secondary_muscle': 'Bíceps',
                'intensity_level': 'Básico (Intensidad Baja)',
                'biomechanics': 'Soporte firme con cero sobrecarga articular.',
              },
              {
                'name': 'Crunch en colchoneta con control respiratorio',
                'sets': 3,
                'reps': '12-15',
                'primary_muscle': 'Abdomen',
                'secondary_muscle': 'Core',
                'intensity_level': 'Básico (Intensidad Baja)',
                'biomechanics': 'Tensión controlada en flexión suave.',
              },
            ]);
            current['title'] = 'Rutina Segura Adaptada (Molestia en $zoneLabel)';
          }

          current['exercises'] = safeExercises;
          current['adaptation_note'] = 'Adaptado por molestia en $zoneLabel (Cero sobrecarga articular)';
          current['affected_joint'] = zoneLabel;
          current['is_adapted_injury'] = true;
          daysList[i] = current;
          adaptedCount++;
        }
      }
    }

    if (adaptedCount > 0) {
      week!['days'] = daysList;
      notifyListeners();
      try {
        await DBHelper.instance.saveWeeklyPlan(jsonEncode(week!));
      } catch (_) {}
      try {
        const storage = FlutterSecureStorage();
        await storage.write(key: 'cached_weekly_plan_v1', value: jsonEncode(week!));
      } catch (_) {}
    }
    return adaptedCount;
  }

  void notifyUpdate() {
    notifyListeners();
  }

  String get nextCycleDateStr {
    final n = nextCycleMonday;
    final nMonth = n.month < 10 ? '0${n.month}' : '${n.month}';
    return 'Lunes ${n.day}/$nMonth';
  }

  List<String> get activeTrainingDayNames {
    final list = <String>[];
    for (final d in days) {
      final ex = d['exercises'];
      if (ex is List && ex.isNotEmpty) {
        final name = d['weekday_name']?.toString() ?? '';
        if (name.isNotEmpty && !list.contains(name)) {
          list.add(name);
        }
      }
    }
    return list;
  }

  List<String> get activeRestDayNames {
    final list = <String>[];
    for (final d in days) {
      final ex = d['exercises'];
      if (ex is! List || ex.isEmpty) {
        final name = d['weekday_name']?.toString() ?? '';
        if (name.isNotEmpty && !list.contains(name)) {
          list.add(name);
        }
      }
    }
    return list;
  }

  bool get isPlanExpired {
    if (week == null) return false;
    if (week?['is_expired'] == true) return true;
    final mondayStr = week?['week_monday'] as String?;
    if (mondayStr != null) {
      final planMonday = DateTime.tryParse(mondayStr);
      if (planMonday != null && currentWeekMonday.isAfter(planMonday)) {
        return true;
      }
    }
    final createdAtStr = week?['created_at'] as String?;
    if (createdAtStr != null) {
      final created = DateTime.tryParse(createdAtStr);
      if (created != null) {
        final createdMonday = DateTime(created.year, created.month, created.day)
            .subtract(Duration(days: created.weekday - 1));
        if (currentWeekMonday.isAfter(createdMonday)) {
          return true;
        }
      }
    }
    return false;
  }

  bool get hasActivePlan {
    if (isPlanExpired) return false;
    return week != null && days.any((d) => (d['exercises'] as List?)?.isNotEmpty == true);
  }

  String? _loadedCedula;

  void resetForUser([String? cedula]) {
    _loadedCedula = cedula;
    week = null;
    upcomingWeek = null;
    _pending = null;
    _completedDaysSet.clear();
    _workoutStats = {
      'current_streak': 0,
      'best_streak': 0,
      'total_sessions': 0,
      'last_rpe': 7,
      'last_feeling': 'Con energía',
    };
    isLoading = false;
    loadedFromCache = false;
    notifyListeners();
  }

  Future<void> ensureLoaded(UserProfile? profile) {
    final targetCedula = profile?.cedula ?? AuthService.instance.loggedInUser?.cedula;
    if (_loadedCedula != null && targetCedula != null && _loadedCedula != targetCedula) {
      resetForUser(targetCedula);
    }
    if (week != null && !isPlanExpired) {
      isLoading = false;
      return Future<void>.value();
    }
    if (_pending != null) return _pending!;
    _pending = _load(profile);
    return _pending!;
  }

  Future<void> _load(UserProfile? profile) async {
    lastError = null;
    final cedula = profile?.cedula ?? AuthService.instance.loggedInUser?.cedula;
    _loadedCedula = cedula;
    try {
      final cachedJson = await DBHelper.instance
          .getCachedWeeklyPlan(cedula: cedula)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (cachedJson != null && cachedJson.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson);
          if (decoded is Map<String, dynamic>) {
            final mondayStr = decoded['week_monday'] as String?;
            if (mondayStr != null) {
              final planMonday = DateTime.tryParse(mondayStr);
              if (planMonday != null && currentWeekMonday.isAfter(planMonday)) {
                decoded['is_expired'] = true;
              }
            } else {
              final createdAtStr = decoded['created_at'] as String?;
              if (createdAtStr != null) {
                final created = DateTime.tryParse(createdAtStr);
                if (created != null) {
                  final createdMonday = DateTime(created.year, created.month, created.day)
                      .subtract(Duration(days: created.weekday - 1));
                  if (currentWeekMonday.isAfter(createdMonday)) {
                    decoded['is_expired'] = true;
                  }
                }
              }
            }
            week = decoded;
            loadedFromCache = true;
          }
        } catch (_) {}
      }
    } catch (_) {}

    try {
      final cachedUpcomingJson = await DBHelper.instance
          .getCachedUpcomingPlan(cedula: cedula)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (cachedUpcomingJson != null && cachedUpcomingJson.trim().isNotEmpty) {
        try {
          final decodedUp = jsonDecode(cachedUpcomingJson);
          if (decodedUp is Map<String, dynamic>) {
            upcomingWeek = decodedUp;
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Auto-promoción inteligente: cuando la fecha de inicio del ciclo futuro llega (today >= upDate),
    // se promueve automáticamente a ciclo activo principal
    if (upcomingWeek != null) {
      final upStartStr = upcomingWeek!['cycle_start_date'] as String? ??
          upcomingWeek!['week_monday'] as String?;
      if (upStartStr != null) {
        final upDate = DateTime.tryParse(upStartStr);
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);
        if (upDate != null && (todayDate.isAfter(upDate) || todayDate.isAtSameMomentAs(upDate))) {
          week = upcomingWeek;
          upcomingWeek = null;
          try {
            await DBHelper.instance.saveWeeklyPlan(jsonEncode(week!), cedula: cedula);
            await DBHelper.instance.clearUpcomingPlanCache(cedula: cedula);
          } catch (_) {}
        }
      }
    }


    try {
      const storage = FlutterSecureStorage();
      final prefKey = (cedula != null && cedula.isNotEmpty)
          ? 'user_preferences_$cedula'
          : 'user_preferences_v1';
      var prefStr = await storage.read(key: prefKey);
      prefStr ??= await storage.read(key: 'user_preferences_v1');
      if (prefStr != null && prefStr.trim().isNotEmpty) {
        final pref = jsonDecode(prefStr);
        if (pref is Map) {
          if (pref['goal'] != null) _userGoal = pref['goal'].toString();
          if (pref['level'] != null) _userLevel = pref['level'].toString();
          if (pref['intensity'] != null) _userIntensity = pref['intensity'].toString();
        }
      }
    } catch (_) {}

    try {
      _workoutStats = await DBHelper.instance.getWorkoutStats(cedula: cedula);
      _completedDaysSet = await DBHelper.instance.getCompletedDays(cedula: cedula);
    } catch (_) {}


    isLoading = false;
    _pending = null;
    notifyListeners();
  }

  Future<void> updateUserPreferences({
    String? goal,
    String? level,
    String? intensity,
  }) async {
    bool changed = false;
    if (goal != null && goal.trim().isNotEmpty && goal != _userGoal) {
      _userGoal = goal.trim();
      changed = true;
    }
    if (level != null && level.trim().isNotEmpty && level != _userLevel) {
      _userLevel = level.trim();
      changed = true;
    }
    if (intensity != null && intensity.trim().isNotEmpty && intensity != _userIntensity) {
      _userIntensity = intensity.trim();
      changed = true;
    }
    if (changed) {
      notifyListeners();
      try {
        const storage = FlutterSecureStorage();
        await storage.write(
          key: 'user_preferences_v1',
          value: jsonEncode({
            'goal': _userGoal,
            'level': _userLevel,
            'intensity': _userIntensity,
          }),
        );
      } catch (_) {}
    }
  }

  Future<void> refreshWorkoutStats() async {
    final cedula = AuthService.instance.loggedInUser?.cedula;
    _workoutStats = await DBHelper.instance.getWorkoutStats(cedula: cedula);
    _completedDaysSet = await DBHelper.instance.getCompletedDays(cedula: cedula);
    notifyListeners();
  }

  Map<String, dynamic> _buildLocalFallbackWeek({
    required String goal,
    required String experienceLevel,
    required String intensityPreference,
  }) {
    final hint = '$intensityPreference $experienceLevel $goal'.toLowerCase();
    final isLow = hint.contains('baja') ||
        hint.contains('bajo') ||
        hint.contains('principiante') ||
        hint.contains('novato');
    final isHigh = hint.contains('alta') ||
        hint.contains('alto') ||
        hint.contains('avanzado');
    final lvlLabel = isLow
        ? 'Básico (Intensidad Baja)'
        : (isHigh
            ? 'Avanzado (Intensidad Alta)'
            : 'Intermedio (Intensidad Media)');
    const baseGif =
        'https://raw.githubusercontent.com/JahelCuadrado/ExerciseGymGifsDB/main/';

    final sessions = [
      {
        'title': 'Tren Inferior (Piernas y Glúteos) · $lvlLabel',
        'exercises': [
          {
            'name': isLow
                ? 'Sentadilla asistida con peso corporal'
                : (isHigh
                    ? 'Sentadilla profunda con barra'
                    : 'Sentadilla goblet con mancuerna'),
            'sets': isLow ? 3 : 4,
            'reps': '10-12',
            'primary_muscle': 'Cuádriceps',
            'secondary_muscle': 'Glúteos',
            'intensity_level': lvlLabel,
            'gif_url': isLow
                ? '${baseGif}Quads/Bodyweight-Squat.gif'
                : '${baseGif}Quads/Dumbbell-Goblet-Squat.gif',
          },
          {
            'name': isLow
                ? 'Puente de glúteos en suelo'
                : 'Peso muerto rumano con mancuernas',
            'sets': 3,
            'reps': '12',
            'primary_muscle': 'Glúteos',
            'secondary_muscle': 'Isquiotibiales',
            'intensity_level': lvlLabel,
            'gif_url': isLow
                ? '${baseGif}Hamstrings/Glute-Bridge-with-Abduction- Bodyweight.gif'
                : '${baseGif}Hamstrings/Dumbbell-Romanian-Deadlift.gif',
          },
          {
            'name': 'Elevación de talones de pie',
            'sets': 3,
            'reps': '15',
            'primary_muscle': 'Pantorrillas',
            'secondary_muscle': 'Sóleo',
            'intensity_level': lvlLabel,
            'gif_url': '${baseGif}Calves/Standing-Calf-Raise.gif',
          },
        ],
      },
      {
        'title': 'Tren Superior (Pecho y Espalda) · $lvlLabel',
        'exercises': [
          {
            'name': isLow
                ? 'Flexiones inclinadas con apoyo'
                : 'Press de pecho con mancuernas',
            'sets': 3,
            'reps': '10-12',
            'primary_muscle': 'Pectorales',
            'secondary_muscle': 'Tríceps',
            'intensity_level': lvlLabel,
            'gif_url': isLow
                ? '${baseGif}Chest/Incline-Push-Up.gif'
                : '${baseGif}Chest/Dumbbell-Bench-Press.gif',
          },
          {
            'name': isLow
                ? 'Remo sentado en polea o con banda'
                : 'Remo con mancuerna a una mano',
            'sets': 3,
            'reps': '12',
            'primary_muscle': 'Dorsales',
            'secondary_muscle': 'Bíceps',
            'intensity_level': lvlLabel,
            'gif_url': isLow
                ? '${baseGif}Back/Cable-Seated-Row.gif'
                : '${baseGif}Back/Dumbbell-Bent-Over-Row.gif',
          },
          {
            'name': 'Press de hombros sentado con mancuernas',
            'sets': 3,
            'reps': '10-12',
            'primary_muscle': 'Deltoides',
            'secondary_muscle': 'Tríceps',
            'intensity_level': lvlLabel,
            'gif_url': '${baseGif}Shoulders/Dumbbell-Seated-Shoulder-Press.gif',
          },
        ],
      },
      {
        'title': 'Tren Inferior (Recuperación 48h Superada) · $lvlLabel',
        'exercises': [
          {
            'name': isLow
                ? 'Zancada estática asistida sin peso'
                : 'Prensa de piernas en máquina',
            'sets': 3,
            'reps': isLow ? '10 por pierna' : '10-12',
            'primary_muscle': 'Cuádriceps',
            'secondary_muscle': 'Glúteos',
            'intensity_level': lvlLabel,
            'gif_url': isLow
                ? '${baseGif}Quads/Bodyweight-Walking-Lunge.gif'
                : '${baseGif}Quads/Sled-45-degree-Leg-Press.gif',
          },
          {
            'name': 'Curl femoral tumbado en máquina',
            'sets': 3,
            'reps': '12',
            'primary_muscle': 'Isquiotibiales',
            'secondary_muscle': 'Glúteos',
            'intensity_level': lvlLabel,
            'gif_url': '${baseGif}Hamstrings/Lever-Lying-Leg-Curl.gif',
          },
          {
            'name': 'Plancha abdominal isométrica',
            'sets': 3,
            'reps': '30 s',
            'primary_muscle': 'Core',
            'secondary_muscle': 'Recto abdominal',
            'intensity_level': lvlLabel,
            'gif_url': '${baseGif}Abdominals/Front-Plank.gif',
          },
        ],
      },
      {
        'title': 'Hombros, Brazos y Core · $lvlLabel',
        'exercises': [
          {
            'name': 'Elevaciones laterales con mancuernas',
            'sets': 3,
            'reps': '12',
            'primary_muscle': 'Deltoides',
            'secondary_muscle': 'Trapecio',
            'intensity_level': lvlLabel,
            'gif_url': '${baseGif}Shoulders/Dumbbell-Lateral-Raise.gif',
          },
          {
            'name': 'Curl de bíceps con mancuernas',
            'sets': 3,
            'reps': '12',
            'primary_muscle': 'Bíceps',
            'secondary_muscle': 'Antebrazo',
            'intensity_level': lvlLabel,
            'gif_url': '${baseGif}Biceps/Dumbbell-Bicep-Curl.gif',
          },
          {
            'name': 'Crunch abdominal controlado en suelo',
            'sets': 3,
            'reps': '12-15',
            'primary_muscle': 'Abdominales',
            'secondary_muscle': 'Core',
            'intensity_level': lvlLabel,
            'gif_url': '${baseGif}Abdominals/Crunch-Floor.gif',
          },
        ],
      },
      {
        'title': 'Acondicionamiento Funcional Integral · $lvlLabel',
        'exercises': [
          {
            'name': isLow
                ? 'Subida al cajón baja (Step-up suave)'
                : 'Zancadas con mancuernas',
            'sets': 3,
            'reps': '10 por lado',
            'primary_muscle': 'Cuádriceps',
            'secondary_muscle': 'Glúteos',
            'intensity_level': lvlLabel,
            'gif_url': '${baseGif}Quads/Dumbbell-Step-up.gif',
          },
          {
            'name': 'Jalón al pecho en polea alta',
            'sets': 3,
            'reps': '12',
            'primary_muscle': 'Dorsales',
            'secondary_muscle': 'Bíceps',
            'intensity_level': lvlLabel,
            'gif_url': '${baseGif}Back/Cable-Pulldown.gif',
          },
          {
            'name': 'Elevación de piernas tumbado',
            'sets': 3,
            'reps': '12',
            'primary_muscle': 'Abdominales',
            'secondary_muscle': 'Core',
            'intensity_level': lvlLabel,
            'gif_url': '${baseGif}Abdominals/Lying-Leg-Raise.gif',
          },
        ],
      },
      {
        'title': 'Movilidad Articular y Recuperación',
        'exercises': [
          {
            'name': 'Estiramiento dinámico y movilidad de cadera',
            'sets': 3,
            'reps': '40 s',
            'primary_muscle': 'Movilidad',
            'secondary_muscle': 'Zona Lumbar',
            'intensity_level': 'Básico (Intensidad Baja)',
            'gif_url': '${baseGif}Calves/Butterfly-Yoga-Pose.gif',
          },
        ],
      },
      {
        'title': 'Descanso Activo y Regeneración',
        'exercises': [
          {
            'name': 'Caminata suave o bicicleta estática sin resistencia',
            'sets': 1,
            'reps': '20 min',
            'primary_muscle': 'Cardio Bajo Impacto',
            'secondary_muscle': 'Articulaciones',
            'intensity_level': 'Básico (Intensidad Baja)',
            'gif_url': '${baseGif}Cardio/Walking-on-Incline-Treadmill.gif',
          },
        ],
      },
    ];

    final daysList = List.generate(7, (idx) {
      final s = sessions[idx];
      return {
        'weekday': idx,
        'weekday_name': _weekdayNames[idx],
        'title': s['title'],
        'is_training': idx < 5,
        'exercises': s['exercises'],
        'nutrition': [
          {
            'title': 'Desayuno',
            'items': [
              'Avena con yogur natural o huevos revueltos',
              'Fruta fresca de temporada',
              'Agua 400 ml',
            ],
          },
          {
            'title': 'Almuerzo',
            'items': [
              'Proteína magra 150 g (pollo, pescado o carne magra)',
              'Arroz integral, papa o batata 1 taza cocida',
              'Ensalada fresca variada con aceite de oliva',
            ],
          },
          {
            'title': 'Merienda',
            'items': ['Fruta entera y puñado de frutos secos o yogur griego'],
          },
          {
            'title': 'Cena',
            'items': [
              'Proteína ligera 130 g',
              'Vegetales al vapor o salteados',
            ],
          },
        ],
        'synergy':
            'Plan alternado con 48-72h de recuperación muscular y nutrición ajustada al gasto energético del día.',
      };
    });

    return {
      'provider': 'fallback_local',
      'days': daysList,
      'training_days': _weekdayNames.sublist(0, 5),
    };
  }

  Future<void> _fetchAndSave(
    UserProfile? profile, {
    String goal = 'Mejorar condición física general',
    String experienceLevel = 'Intermedio',
    String intensityPreference = 'Medio',
    bool equipmentAvailable = true,
  }) async {
    final safeAge = (profile?.age ?? 25).clamp(12, 100);
    final safeWeight = (profile?.weight ?? 70.0).clamp(30.0, 300.0);
    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/api/plans/weekly'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'goal': goal,
              'level': experienceLevel.toLowerCase(),
              'experience_level': experienceLevel,
              'intensity': intensityPreference,
              'intensity_preference': intensityPreference,
              'age': safeAge,
              'weight': safeWeight,
              'food_allergies': profile?.foodAllergies,
              'current_injuries': profile?.currentInjuries,
              'areas_to_avoid': profile?.areasToAvoid,
              'equipment_available': equipmentAvailable,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          week = data;
          loadedFromCache = false;
          lastError = null;
          await DBHelper.instance.saveWeeklyPlan(response.body);
          return;
        }
      }
      // Si el servidor devolvió error (ej. 422/500/503), generamos plan local seguro
      week ??= _buildLocalFallbackWeek(
        goal: goal,
        experienceLevel: experienceLevel,
        intensityPreference: intensityPreference,
      );
      lastError = null;
      await DBHelper.instance.saveWeeklyPlan(jsonEncode(week));
    } catch (e) {
      week ??= _buildLocalFallbackWeek(
        goal: goal,
        experienceLevel: experienceLevel,
        intensityPreference: intensityPreference,
      );
      lastError = null;
      try {
        await DBHelper.instance.saveWeeklyPlan(jsonEncode(week));
      } catch (_) {}
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

  Future<Map<String, dynamic>> injectCustomPlanForToday(Map<String, dynamic> structuredPlan) async {
    final title = structuredPlan['title'] ?? 'Sesión Personalizada Coach IA';
    final exercises = structuredPlan['exercises'] ?? [];
    final nutrition = structuredPlan['nutrition'] ?? {};
    final rawRecommended = structuredPlan['recommended_days'];
    final Map<String, int> dayNameToIndex = {
      'lunes': 0,
      'martes': 1,
      'miércoles': 2,
      'miercoles': 2,
      'jueves': 3,
      'viernes': 4,
      'sábado': 5,
      'sabado': 5,
      'domingo': 6,
    };

    final List<int> requestedIndices = [];
    if (rawRecommended is List && rawRecommended.isNotEmpty) {
      for (final d in rawRecommended) {
        final key = d.toString().trim().toLowerCase();
        if (dayNameToIndex.containsKey(key)) {
          requestedIndices.add(dayNameToIndex[key]!);
        }
      }
    }
    if (requestedIndices.isEmpty) {
      requestedIndices.addAll([0, 1, 2, 3, 4]); // Lunes a Viernes por defecto
    }

    final defaultNutrition = {
      'desayuno': 'Proteína y carbohidratos complejos según objetivo.',
      'almuerzo': 'Comida balanceada: proteína magra, vegetales y carbohidratos.',
      'cena': 'Cena ligera alta en proteína para síntesis miofibrilar.',
    };

    final recoveryRule = structuredPlan['recovery_rule'] as String? ??
        'Sesión programada por el Coach IA respetando 48-72h de recuperación muscular.';

    final List<String> assignedDayNames = [];
    bool scheduledInNextCycle = false;
    int preservedRoutinesCount = 0;

    final rawDaysSchedule = structuredPlan['days_schedule'];
    if (rawDaysSchedule is Map && rawDaysSchedule.isNotEmpty) {
      final daysMap = Map<String, dynamic>.from(rawDaysSchedule);
      final List<Map<String, dynamic>> newDays = [];
      const weekNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

      for (int i = 0; i < 7; i++) {
        final dName = weekNames[i];
        final dayData = daysMap[dName] ??
            daysMap[dName.toLowerCase()] ??
            daysMap[dName.replaceAll('é', 'e')];
        if (dayData is Map) {
          final isRest = dayData['is_rest'] == true;
          final dTitle = dayData['title']?.toString() ??
              (isRest ? 'Día de Descanso y Supercompensación' : title);
          final dExercises = (dayData['exercises'] as List?) ?? [];
          final bool isTraining = !isRest && dExercises.isNotEmpty;
          if (isTraining && !assignedDayNames.contains(_weekdayNames[i])) {
            assignedDayNames.add(_weekdayNames[i]);
          }
          newDays.add({
            'weekday': i,
            'weekday_name': _weekdayNames[i],
            'title': dTitle,
            'is_training': isTraining,
            'exercises': dExercises,
            'nutrition': isTraining ? nutrition : defaultNutrition,
            'synergy': isRest
                ? (dayData['rest_advice']?.toString() ??
                    'Día de supercompensación y descanso neuromuscular.')
                : recoveryRule,
          });
        } else {
          newDays.add({
            'weekday': i,
            'weekday_name': _weekdayNames[i],
            'title': (i == 5 || i == 6)
                ? 'Descanso y Supercompensación Muscular'
                : 'Sesión de Acondicionamiento',
            'is_training': false,
            'exercises': [],
            'nutrition': defaultNutrition,
            'synergy': 'Día de regeneración muscular.',
          });
        }
      }

      final bool isFutureCycle = structuredPlan['is_future_cycle'] == true;
      final bool replaceActive = structuredPlan['replace_active_cycle'] == true;
      final bool shouldScheduleUpcoming = (isFutureCycle && !replaceActive && hasActivePlan);

      if (shouldScheduleUpcoming) {
        upcomingWeek = {
          'id': 'coach_upcoming_${DateTime.now().millisecondsSinceEpoch}',
          'goal': title,
          'week_monday': structuredPlan['cycle_start_date'] ?? nextCycleMonday.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'cycle_start_date': structuredPlan['cycle_start_date'],
          'cycle_end_date': structuredPlan['cycle_end_date'],
          'cycle_range_str': structuredPlan['cycle_range_str'],
          'is_upcoming': true,
          'days': newDays,
        };

        isLoading = false;
        _pending = null;
        lastError = null;
        notifyListeners();
        try {
          final userCedula = AuthService.instance.loggedInUser?.cedula;
          await DBHelper.instance.saveUpcomingPlan(jsonEncode(upcomingWeek!), cedula: userCedula);
        } catch (_) {}

        return {
          'assigned_days': assignedDayNames,
          'scheduled_in_next_cycle': true,
          'cycle_range_str': structuredPlan['cycle_range_str'] ?? '',
          'preserved_routines_count': (week?['days'] as List?)?.length ?? 0,
        };
      }

      week = {
        'id': 'coach_plan_${DateTime.now().millisecondsSinceEpoch}',
        'goal': title,
        'week_monday': currentWeekMonday.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'days': newDays,
      };

      isLoading = false;
      _pending = null;
      lastError = null;
      notifyListeners();
      try {
        final userCedula = AuthService.instance.loggedInUser?.cedula;
        await DBHelper.instance.saveWeeklyPlan(jsonEncode(week!), cedula: userCedula);
      } catch (_) {}


      return {
        'assigned_days': assignedDayNames,
        'scheduled_in_next_cycle': false,
        'preserved_routines_count': 0,
      };
    }


    if (week == null) {
      // Si no hay plan previo, se inicializa la semana normalmente
      final targetSet = requestedIndices.toSet();
      week = {
        'id': 'coach_plan_${DateTime.now().millisecondsSinceEpoch}',
        'goal': title,
        'week_monday': currentWeekMonday.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'days': List.generate(7, (i) {
          final isTarget = targetSet.contains(i);
          if (isTarget) assignedDayNames.add(_weekdayNames[i]);
          return {
            'weekday': i,
            'weekday_name': _weekdayNames[i],
            'title': isTarget
                ? title
                : (i == 5 || i == 6)
                    ? 'Descanso y Supercompensación Muscular'
                    : 'Acondicionamiento y Recuperación Activa',
            'is_training': isTarget && (exercises as List).isNotEmpty,
            'exercises': isTarget ? exercises : [],
            'nutrition': isTarget ? nutrition : defaultNutrition,
            'synergy': isTarget
                ? recoveryRule
                : 'Día de recuperación y supercompensación muscular.',
          };
        }),
      };
    } else {
      // PRESERVACIÓN ESTRICTA: No sobreescribir rutinas ni nutrición ya planificadas
      final currentDays = List.from(week!['days'] ?? []);

      for (final reqIdx in requestedIndices) {
        int targetIdx = reqIdx;
        final currentEntryIdx = currentDays.indexWhere((d) => d['weekday'] == targetIdx);
        final bool isOccupied = currentEntryIdx != -1 &&
            ((currentDays[currentEntryIdx]['exercises'] as List?)?.isNotEmpty == true ||
                currentDays[currentEntryIdx]['is_training'] == true);

        if (isOccupied) {
          preservedRoutinesCount++;
          // Buscar la siguiente fecha disponible (día libre en la semana)
          int nextFree = -1;
          for (int offset = 1; offset < 7; offset++) {
            final testIdx = (reqIdx + offset) % 7;
            final testEntryIdx = currentDays.indexWhere((d) => d['weekday'] == testIdx);
            final bool testOccupied = testEntryIdx != -1 &&
                ((currentDays[testEntryIdx]['exercises'] as List?)?.isNotEmpty == true ||
                    currentDays[testEntryIdx]['is_training'] == true);
            if (!testOccupied) {
              nextFree = testIdx;
              break;
            }
          }

          if (nextFree != -1) {
            targetIdx = nextFree;
          } else {
            // Toda la semana está ocupada: programar para el siguiente ciclo disponible
            scheduledInNextCycle = true;
            targetIdx = reqIdx; // Asignado a la posición del próximo ciclo
          }
        }

        final existingIdx = currentDays.indexWhere((d) => d['weekday'] == targetIdx);
        dynamic mergedNutrition = nutrition;
        if (existingIdx != -1 && currentDays[existingIdx]['nutrition'] != null) {
          final existingNutr = currentDays[existingIdx]['nutrition'];
          if (existingNutr is Map && existingNutr.isNotEmpty && nutrition is Map) {
            mergedNutrition = Map<String, dynamic>.from(existingNutr)..addAll(Map<String, dynamic>.from(nutrition));
          }
        }

        final newDay = {
          'weekday': targetIdx,
          'weekday_name': _weekdayNames[targetIdx.clamp(0, 6)],
          'title': title,
          'is_training': (exercises as List).isNotEmpty,
          'exercises': exercises,
          'nutrition': (mergedNutrition is Map && mergedNutrition.isNotEmpty) ||
                  (mergedNutrition is List && mergedNutrition.isNotEmpty)
              ? mergedNutrition
              : defaultNutrition,
          'synergy': recoveryRule,
          if (scheduledInNextCycle) 'scheduled_cycle': nextCycleDateStr,
        };

        if (existingIdx != -1) {
          // Solo si estaba libre o en siguiente ciclo disponible
          currentDays[existingIdx] = newDay;
        } else {
          currentDays.add(newDay);
        }

        final dayLabel = scheduledInNextCycle
            ? '${_weekdayNames[targetIdx]} (Próximo ciclo: $nextCycleDateStr)'
            : _weekdayNames[targetIdx];
        if (!assignedDayNames.contains(dayLabel)) {
          assignedDayNames.add(dayLabel);
        }
      }

      week!['days'] = currentDays;
    }

    isLoading = false;
    _pending = null;
    lastError = null;
    notifyListeners();
    try {
      final userCedula = AuthService.instance.loggedInUser?.cedula;
      await DBHelper.instance.saveWeeklyPlan(jsonEncode(week), cedula: userCedula);
    } catch (_) {}

    return {
      'assigned_days': assignedDayNames,
      'scheduled_in_next_cycle': scheduledInNextCycle,
      'preserved_routines_count': preservedRoutinesCount,
    };
  }

  Future<void> clearWeeklyPlan() async {
    week = null;
    loadedFromCache = false;
    lastError = null;
    notifyListeners();
    try {
      final userCedula = AuthService.instance.loggedInUser?.cedula;
      await DBHelper.instance.saveWeeklyPlan('', cedula: userCedula);
      await DBHelper.instance.saveCompletedDays({}, cedula: userCedula);
    } catch (_) {}
  }


  Future<void> activateUpcomingPlanNow() async {
    if (upcomingWeek == null) return;
    week = Map<String, dynamic>.from(upcomingWeek!);
    upcomingWeek = null;
    notifyListeners();
    try {
      await DBHelper.instance.saveWeeklyPlan(jsonEncode(week!));
      await DBHelper.instance.clearUpcomingPlanCache();
    } catch (_) {}
  }

  Future<void> clearUpcomingPlan() async {
    upcomingWeek = null;
    notifyListeners();
    try {
      await DBHelper.instance.clearUpcomingPlanCache();
    } catch (_) {}
  }
}


