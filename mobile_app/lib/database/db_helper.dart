import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mobile_app/services/auth_service.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;
  static String? _memoryCache;
  static String? _memoryUpcomingCache;
  static Set<int>? _memoryCompletedDays;
  static const String _webStorageKey = 'cached_weekly_plan_v1';
  static const String _upcomingStorageKey = 'cached_upcoming_plan_v1';
  static const String _completedDaysKey = 'cached_completed_days_v1';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Cache en memoria aislado por cédula de usuario
  static final Map<String, String> _userPlanCache = {};
  static final Map<String, String> _userUpcomingCache = {};
  static final Map<String, String> _userArchetypeCache = {};
  static final Map<String, Set<int>> _userCompletedDaysCache = {};

  DBHelper._init();

  String _effectiveCedula(String? cedula) {
    if (cedula != null && cedula.trim().isNotEmpty) {
      return cedula.trim();
    }
    return AuthService.instance.loggedInUser?.cedula.trim() ?? 'default';
  }

  Future<void> saveUserArchetype(String cedula, String archetype, {String? quizDataJson}) async {
    final userCedula = _effectiveCedula(cedula);
    _userArchetypeCache[userCedula] = archetype;
    try {
      await _secureStorage.write(key: 'biopsycho_archetype_$userCedula', value: archetype);
      await _secureStorage.write(key: 'biopsycho_quiz_completed_$userCedula', value: 'true');
      await _secureStorage.write(key: 'biopsycho_archetype', value: archetype);
      await _secureStorage.write(key: 'biopsycho_quiz_completed', value: 'true');
      if (quizDataJson != null && quizDataJson.isNotEmpty) {
        await _secureStorage.write(key: 'biopsycho_data_$userCedula', value: quizDataJson);
        await _secureStorage.write(key: 'biopsycho_data', value: quizDataJson);
      }
    } catch (_) {}
  }

  Future<String?> getUserArchetype(String? cedula) async {
    final userCedula = _effectiveCedula(cedula);
    if (_userArchetypeCache.containsKey(userCedula) && _userArchetypeCache[userCedula]!.isNotEmpty) {
      return _userArchetypeCache[userCedula];
    }
    try {
      final val = await _secureStorage.read(key: 'biopsycho_archetype_$userCedula');
      if (val != null && val.isNotEmpty) {
        _userArchetypeCache[userCedula] = val;
        return val;
      }
    } catch (_) {}
    try {
      final val = await _secureStorage.read(key: 'biopsycho_archetype');
      if (val != null && val.isNotEmpty) {
        _userArchetypeCache[userCedula] = val;
        return val;
      }
    } catch (_) {}
    return null;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fitness_coach.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE cached_plan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_json TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS cached_upcoming_plan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_json TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
  }

  Future<void> saveWeeklyPlan(String jsonString, {String? cedula}) async {
    final userCedula = _effectiveCedula(cedula);
    _memoryCache = jsonString;
    _userPlanCache[userCedula] = jsonString;
    final userKey = 'cached_weekly_plan_$userCedula';

    try {
      await _secureStorage
          .write(key: userKey, value: jsonString)
          .timeout(const Duration(seconds: 2));
      await _secureStorage
          .write(key: _webStorageKey, value: jsonString)
          .timeout(const Duration(seconds: 2));
    } catch (_) {}

    if (kIsWeb) return;

    try {
      final db = await instance.database.timeout(const Duration(seconds: 2));
      await db.delete('cached_plan');
      await db.insert('cached_plan', {
        'plan_json': jsonString,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> clearWeeklyPlanCache({String? cedula}) async {
    final userCedula = _effectiveCedula(cedula);
    _memoryCache = null;
    _userPlanCache.remove(userCedula);
    try {
      await _secureStorage.delete(key: 'cached_weekly_plan_$userCedula');
      await _secureStorage.delete(key: _webStorageKey);
    } catch (_) {}
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      await db.delete('cached_plan');
    } catch (_) {}
  }

  void clearMemoryCache() {
    _memoryCache = null;
    _memoryUpcomingCache = null;
    _memoryCompletedDays = null;
    _userPlanCache.clear();
    _userUpcomingCache.clear();
    _userArchetypeCache.clear();
    _userCompletedDaysCache.clear();
  }

  Future<String?> getCachedWeeklyPlan({String? cedula}) async {
    final userCedula = _effectiveCedula(cedula);
    if (_userPlanCache.containsKey(userCedula) && _userPlanCache[userCedula]!.trim().isNotEmpty) {
      return _userPlanCache[userCedula];
    }

    try {
      final userKey = 'cached_weekly_plan_$userCedula';
      final stored = await _secureStorage
          .read(key: userKey)
          .timeout(const Duration(seconds: 2));
      if (stored != null && stored.trim().isNotEmpty) {
        _userPlanCache[userCedula] = stored;
        return stored;
      }
    } catch (_) {}

    if (userCedula == 'default') {
      if (_memoryCache != null && _memoryCache!.trim().isNotEmpty) {
        return _memoryCache;
      }
      try {
        final stored = await _secureStorage
            .read(key: _webStorageKey)
            .timeout(const Duration(seconds: 2));
        if (stored != null && stored.trim().isNotEmpty) {
          return stored;
        }
      } catch (_) {}
    }
    return null;
  }


  Future<void> saveUpcomingPlan(String jsonString, {String? cedula}) async {
    final userCedula = _effectiveCedula(cedula);
    _memoryUpcomingCache = jsonString;
    _userUpcomingCache[userCedula] = jsonString;
    final userKey = 'cached_upcoming_plan_$userCedula';

    try {
      await _secureStorage
          .write(key: userKey, value: jsonString)
          .timeout(const Duration(seconds: 2));
      await _secureStorage
          .write(key: _upcomingStorageKey, value: jsonString)
          .timeout(const Duration(seconds: 2));
    } catch (_) {}

    if (kIsWeb) return;

    try {
      final db = await instance.database.timeout(const Duration(seconds: 2));
      await db.delete('cached_upcoming_plan');
      await db.insert('cached_upcoming_plan', {
        'plan_json': jsonString,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> clearUpcomingPlanCache({String? cedula}) async {
    final userCedula = _effectiveCedula(cedula);
    _memoryUpcomingCache = null;
    _userUpcomingCache.remove(userCedula);
    try {
      await _secureStorage.delete(key: 'cached_upcoming_plan_$userCedula');
      await _secureStorage.delete(key: _upcomingStorageKey);
    } catch (_) {}
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      await db.delete('cached_upcoming_plan');
    } catch (_) {}
  }

  Future<String?> getCachedUpcomingPlan({String? cedula}) async {
    final userCedula = _effectiveCedula(cedula);
    if (_userUpcomingCache.containsKey(userCedula) && _userUpcomingCache[userCedula]!.trim().isNotEmpty) {
      return _userUpcomingCache[userCedula];
    }

    try {
      final userKey = 'cached_upcoming_plan_$userCedula';
      final stored = await _secureStorage
          .read(key: userKey)
          .timeout(const Duration(seconds: 2));
      if (stored != null && stored.trim().isNotEmpty) {
        _userUpcomingCache[userCedula] = stored;
        return stored;
      }
    } catch (_) {}

    if (userCedula == 'default') {
      if (_memoryUpcomingCache != null && _memoryUpcomingCache!.trim().isNotEmpty) {
        return _memoryUpcomingCache;
      }
      try {
        final stored = await _secureStorage
            .read(key: _upcomingStorageKey)
            .timeout(const Duration(seconds: 2));
        if (stored != null && stored.trim().isNotEmpty) {
          return stored;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveCompletedDays(Set<int> days, {String? cedula}) async {
    final userCedula = _effectiveCedula(cedula);
    _memoryCompletedDays = Set<int>.from(days);
    _userCompletedDaysCache[userCedula] = Set<int>.from(days);
    final encoded = jsonEncode(days.toList());
    try {
      await _secureStorage
          .write(key: 'cached_completed_days_$userCedula', value: encoded)
          .timeout(const Duration(seconds: 2));
      if (userCedula == 'default') {
        await _secureStorage
            .write(key: _completedDaysKey, value: encoded)
            .timeout(const Duration(seconds: 2));
      }
    } catch (_) {}
  }

  Future<Set<int>> getCompletedDays({String? cedula}) async {
    final userCedula = _effectiveCedula(cedula);
    if (_userCompletedDaysCache.containsKey(userCedula)) {
      return _userCompletedDaysCache[userCedula]!;
    }
    try {
      final stored = await _secureStorage
          .read(key: 'cached_completed_days_$userCedula')
          .timeout(const Duration(seconds: 2));
      if (stored != null && stored.trim().isNotEmpty) {
        final decoded = jsonDecode(stored);
        if (decoded is List) {
          final set = decoded
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .toSet();
          _userCompletedDaysCache[userCedula] = set;
          return set;
        }
      }
    } catch (_) {}

    if (userCedula == 'default' && _memoryCompletedDays != null) {
      return _memoryCompletedDays!;
    }
    return {};
  }

  Future<void> recordWorkoutSession({
    required int weekday,
    required String title,
    required int rpe,
    required String feeling,
    String? notes,
    String? cedula,
  }) async {
    final userCedula = _effectiveCedula(cedula);
    final stats = await getWorkoutStats(cedula: userCedula);
    int currentStreak = (stats['current_streak'] as int? ?? 0) + 1;
    int bestStreak = stats['best_streak'] as int? ?? 0;
    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }
    int totalSessions = (stats['total_sessions'] as int? ?? 0) + 1;

    final history = await getSessionHistory(cedula: userCedula);
    history.insert(0, {
      'weekday': weekday,
      'title': title,
      'rpe': rpe,
      'feeling': feeling,
      'notes': notes ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (history.length > 30) {
      history.removeRange(30, history.length);
    }

    final updatedStats = {
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'total_sessions': totalSessions,
      'last_rpe': rpe,
      'last_feeling': feeling,
      'last_completed_at': DateTime.now().toIso8601String(),
    };

    try {
      await _secureStorage.write(
        key: 'cached_workout_stats_$userCedula',
        value: jsonEncode(updatedStats),
      );
      await _secureStorage.write(
        key: 'cached_workout_history_$userCedula',
        value: jsonEncode(history),
      );
    } catch (_) {}

    final completed = await getCompletedDays(cedula: userCedula);
    completed.add(weekday);
    await saveCompletedDays(completed, cedula: userCedula);
  }

  Future<void> removeSessionRecord(int weekday, {String? cedula}) async {
    final userCedula = _effectiveCedula(cedula);
    final completed = await getCompletedDays(cedula: userCedula);
    completed.remove(weekday);
    await saveCompletedDays(completed, cedula: userCedula);

    final stats = await getWorkoutStats(cedula: userCedula);
    int currentStreak = (stats['current_streak'] as int? ?? 1) - 1;
    if (currentStreak < 0) currentStreak = 0;
    int total = (stats['total_sessions'] as int? ?? 1) - 1;
    if (total < 0) total = 0;

    stats['current_streak'] = currentStreak;
    stats['total_sessions'] = total;

    try {
      await _secureStorage.write(
        key: 'cached_workout_stats_$userCedula',
        value: jsonEncode(stats),
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getWorkoutStats({String? cedula}) async {
    final userCedula = _effectiveCedula(cedula);
    try {
      final stored = await _secureStorage.read(key: 'cached_workout_stats_$userCedula');
      if (stored != null && stored.trim().isNotEmpty) {
        final decoded = jsonDecode(stored);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (_) {}
    return {
      'current_streak': 0,
      'best_streak': 0,
      'total_sessions': 0,
      'last_rpe': 7,
      'last_feeling': 'Normal',
      'last_completed_at': null,
    };
  }

  Future<List<Map<String, dynamic>>> getSessionHistory({String? cedula}) async {
    final userCedula = _effectiveCedula(cedula);
    try {
      final stored = await _secureStorage.read(key: 'cached_workout_history_$userCedula');
      if (stored != null && stored.trim().isNotEmpty) {
        final decoded = jsonDecode(stored);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
