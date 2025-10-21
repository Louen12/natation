import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'exercise_sessions.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table pour les sauts
    await db.execute('''
      CREATE TABLE jump_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration INTEGER NOT NULL,
        repetitions INTEGER NOT NULL,
        total_height REAL NOT NULL,
        max_height REAL NOT NULL,
        total_calories REAL NOT NULL,
        average_power REAL NOT NULL,
        notes TEXT
      )
    ''');

    // Table pour le gainage
    await db.execute('''
      CREATE TABLE sleeving_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration INTEGER NOT NULL,
        repetitions INTEGER NOT NULL,
        target_repetitions INTEGER NOT NULL,
        average_hold_time INTEGER NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
