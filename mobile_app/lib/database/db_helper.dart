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
}
