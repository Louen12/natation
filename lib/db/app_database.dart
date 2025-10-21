import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  AppDatabase._internal();
  factory AppDatabase() => _instance;

  static const _dbName = 'fitness.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final docDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docDir.path, _dbName);

    final db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldV, newV) async {},
      onOpen: (db) async {
        await _ensureSchemaCompatibility(db);
      },
    );
    return db;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        reps INTEGER,
        steps INTEGER,
        rest INTEGER,
        distance REAL,
        time_objective INTEGER,
        duration INTEGER,
        jump_number INTEGER,
        height_objective INTEGER,
        time INTEGER,
        type TEXT,
        is_done INTEGER NOT NULL DEFAULT 0,
        is_failed INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE positions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        time INTEGER,
        rest INTEGER,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      );
    ''');

    await db.execute(
      'CREATE INDEX idx_positions_exercise_id ON positions(exercise_id);',
    );

    await db.execute('''
          CREATE TABLE results_vma(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            palier INTEGER,
            vma REAL,
            date TEXT
          )
        ''');
  }

  /// ajoute la colonne is_done si absente
  Future<void> _ensureSchemaCompatibility(Database db) async {
    // Vérifie la présence de la colonne is_done
    final cols = await db.rawQuery('PRAGMA table_info(exercises);');
    final hasIsDone = cols.any((c) {
      final name = (c['name'] ?? '').toString();
      return name == 'is_done';
    });

    if (!hasIsDone) {
      await db.execute(
        'ALTER TABLE exercises ADD COLUMN is_done INTEGER NOT NULL DEFAULT 0;',
      );
      await db.execute(
        'ALTER TABLE exercises ADD COLUMN is_failed INTEGER NOT NULL DEFAULT 0;',
      );
    }
  }
}
