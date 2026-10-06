import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

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
    final db = await instance.database;
    await db.delete('cached_plan');
    await db.insert('cached_plan', {
      'plan_json': jsonString,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String?> getCachedWeeklyPlan() async {
    final db = await instance.database;
    final result = await db.query('cached_plan', limit: 1);
    if (result.isNotEmpty) {
      return result.first['plan_json'] as String;
    }
    return null;
  }
}
