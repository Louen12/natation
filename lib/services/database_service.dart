import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vma_results.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE results(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            palier INTEGER,
            vma REAL,
            date TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertResult(int palier, double vma) async {
    final db = await database;
    await db.insert(
      'results',
      {
        'palier': palier,
        'vma': vma,
        'date': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getResults() async {
    final db = await database;
    return await db.query('results', orderBy: 'date DESC');
  }

  Future<void> clearResults() async {
    final db = await database;
    await db.delete('results');
  }
}
