import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;
  static String? _memoryCache;
  static Set<int>? _memoryCompletedDays;
  static const String _webStorageKey = 'cached_weekly_plan_v1';
  static const String _completedDaysKey = 'cached_completed_days_v1';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  DBHelper._init();

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
  }

  Future<void> saveWeeklyPlan(String jsonString) async {
    _memoryCache = jsonString;
    if (kIsWeb) {
      try {
        await _secureStorage
            .write(key: _webStorageKey, value: jsonString)
            .timeout(const Duration(seconds: 2));
      } catch (_) {}
      return;
    }
    try {
      final db = await instance.database.timeout(const Duration(seconds: 2));
      await db.delete('cached_plan');
      await db.insert('cached_plan', {
        'plan_json': jsonString,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      try {
        await _secureStorage
            .write(key: _webStorageKey, value: jsonString)
            .timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
  }

  Future<void> clearWeeklyPlanCache() async {
    _memoryCache = null;
    if (kIsWeb) {
      try {
        await _secureStorage.delete(key: _webStorageKey);
      } catch (_) {}
      return;
    }
    try {
      final db = await instance.database;
      await db.delete('cached_plan');
    } catch (_) {
      try {
        await _secureStorage.delete(key: _webStorageKey);
      } catch (_) {}
    }
  }

  Future<String?> getCachedWeeklyPlan() async {

    if (_memoryCache != null && _memoryCache!.trim().isNotEmpty) {
      return _memoryCache;
    }
    if (kIsWeb) {
      try {
        final stored = await _secureStorage
            .read(key: _webStorageKey)
            .timeout(const Duration(seconds: 2));
        if (stored != null && stored.trim().isNotEmpty) {
          _memoryCache = stored;
          return stored;
        }
      } catch (_) {}
      return null;
    }
    try {
      final db = await instance.database.timeout(const Duration(seconds: 2));
      final result = await db.query('cached_plan', limit: 1);
      if (result.isNotEmpty) {
        final plan = result.first['plan_json'] as String;
        _memoryCache = plan;
        return plan;
      }
    } catch (_) {
      try {
        final stored = await _secureStorage
            .read(key: _webStorageKey)
            .timeout(const Duration(seconds: 2));
        if (stored != null && stored.trim().isNotEmpty) {
          _memoryCache = stored;
          return stored;
        }
      } catch (_) {}
    }
    return null;
  }

  static const String _workoutStatsKey = 'cached_workout_stats_v1';
  static const String _workoutHistoryKey = 'cached_workout_history_v1';

  Future<void> saveCompletedDays(Set<int> days) async {
    _memoryCompletedDays = Set<int>.from(days);
    final encoded = jsonEncode(days.toList());
    try {
      await _secureStorage
          .write(key: _completedDaysKey, value: encoded)
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<Set<int>> getCompletedDays() async {
    if (_memoryCompletedDays != null) {
      return _memoryCompletedDays!;
    }
    try {
      final stored = await _secureStorage
          .read(key: _completedDaysKey)
          .timeout(const Duration(seconds: 2));
      if (stored != null && stored.trim().isNotEmpty) {
        final decoded = jsonDecode(stored);
        if (decoded is List) {
          final set = decoded
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .toSet();
          _memoryCompletedDays = set;
          return set;
        }
      }
    } catch (_) {}
    return {};
  }

  Future<void> recordWorkoutSession({
    required int weekday,
    required String title,
    required int rpe,
    required String feeling,
    String? notes,
  }) async {
    final stats = await getWorkoutStats();
    int currentStreak = (stats['current_streak'] as int? ?? 0) + 1;
    int bestStreak = stats['best_streak'] as int? ?? 0;
    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }
    int totalSessions = (stats['total_sessions'] as int? ?? 0) + 1;

    final history = await getSessionHistory();
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
        key: _workoutStatsKey,
        value: jsonEncode(updatedStats),
      );
      await _secureStorage.write(
        key: _workoutHistoryKey,
        value: jsonEncode(history),
      );
    } catch (_) {}

    final completed = await getCompletedDays();
    completed.add(weekday);
    await saveCompletedDays(completed);
  }

  Future<void> removeSessionRecord(int weekday) async {
    final completed = await getCompletedDays();
    completed.remove(weekday);
    await saveCompletedDays(completed);

    final stats = await getWorkoutStats();
    int currentStreak = (stats['current_streak'] as int? ?? 1) - 1;
    if (currentStreak < 0) currentStreak = 0;
    int total = (stats['total_sessions'] as int? ?? 1) - 1;
    if (total < 0) total = 0;

    stats['current_streak'] = currentStreak;
    stats['total_sessions'] = total;

    try {
      await _secureStorage.write(
        key: _workoutStatsKey,
        value: jsonEncode(stats),
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getWorkoutStats() async {
    try {
      final stored = await _secureStorage.read(key: _workoutStatsKey);
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

  Future<List<Map<String, dynamic>>> getSessionHistory() async {
    try {
      final stored = await _secureStorage.read(key: _workoutHistoryKey);
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
