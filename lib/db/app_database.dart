import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Base de données applicative (SQLite/IndexedDB selon plateforme)
class AppDatabase {
  // Singleton
  static final AppDatabase _instance = AppDatabase._internal();
  AppDatabase._internal();
  factory AppDatabase() => _instance;

  static const _dbName = 'fitness.db';
  static const _dbVersion = 6;

  Database? _db;

  /// Accès unique à l’instance de base
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    // Sélection de la factory selon la plateforme
    String dbPath;
    if (kIsWeb) {
      // Web : IndexedDB via FFI web
      databaseFactory = databaseFactoryFfiWeb;
      dbPath = _dbName; // nom logique suffisant
    } else {
      // Desktop (macOS/Linux/Windows) : FFI
      try {
        if (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows) {
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
        }
      } catch (_) {
        // iOS/Android : factory par défaut
      }

      // Chemin du fichier DB (mobile/desktop)
      final dir = await getDatabasesPath();
      dbPath = p.join(dir, _dbName);
    }

    final db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        // Active les FK si supportés (SQLite)
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _createSessionsSchema(db);
      },
      onUpgrade: (db, oldV, newV) async {
        // Si un jour _dbVersion augmente, ajouter ici les migrations versionnées.
      },
      onUpgrade: (db, oldV, newV) async {
        await _updateSchema(db, oldV, newV);
      },
      onOpen: (db) async {
        // S’assure que le schéma est compatible (ajouts non destructifs)
        await _ensureSchemaCompatibility(db);
      },
    );

    return db;
  }

  /// Schéma des exercices + positions
  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercises (
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
      CREATE TABLE IF NOT EXISTS positions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        time INTEGER,
        rest INTEGER,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      );
    ''');
    
    await db.execute('''
          CREATE TABLE traction_plans(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sets INTEGER NOT NULL,
            reps_per_set INTEGER NOT NULL,
            rest_seconds INTEGER NOT NULL
          );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_positions_exercise_id ON positions(exercise_id);',
    );
  }

  /// Schéma des séances d’exercices (pompes/tractions)
  Future<void> _createSessionsSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercise_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_type TEXT NOT NULL,
        sets_planned INTEGER NOT NULL,
        reps_per_set_planned INTEGER NOT NULL,
        rest_seconds_planned INTEGER NOT NULL,
        sets_completed INTEGER NOT NULL,
        total_reps INTEGER NOT NULL,
        started_at_ms INTEGER NOT NULL,
        ended_at_ms INTEGER NOT NULL,
        notes TEXT
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_type ON exercise_sessions (exercise_type);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_started ON exercise_sessions (started_at_ms DESC);');
  }

  /// Vérifie/ajoute les colonnes et tables manquantes de façon non destructive
  Future<void> _ensureSchemaCompatibility(Database db) async {
    // 1) Colonnes is_done / is_failed sur exercises
    final exerciseCols = await db.rawQuery('PRAGMA table_info(exercises);');
    final hasIsDone = exerciseCols.any((c) => (c['name'] ?? '').toString() == 'is_done');
    final hasIsFailed = exerciseCols.any((c) => (c['name'] ?? '').toString() == 'is_failed');

    if (!hasIsDone) {
      await db.execute('ALTER TABLE exercises ADD COLUMN is_done INTEGER NOT NULL DEFAULT 0;');
    }
    if (!hasIsFailed) {
      await db.execute('ALTER TABLE exercises ADD COLUMN is_failed INTEGER NOT NULL DEFAULT 0;');
    }

    // 2) Table exercise_sessions (si fichier historique sans cette table)
    final sessionTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='exercise_sessions';",
    );
    if (sessionTable.isEmpty) {
      await _createSessionsSchema(db);
    }

    // 3) Table positions / index (si manquants)
    final positionsTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='positions';",
    );
    if (positionsTable.isEmpty) {
      await _createSchema(db); // recrée aussi l’index
    } else {
      // S’assure que l’index existe
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_positions_exercise_id ON positions(exercise_id);',
      );
    }
  }

  Future<void> _updateSchema(Database db, int oldVersion, int newVersion) async {
    // Implémentez ici les mises à jour de schéma si nécessaire
    await db.execute('''
          CREATE TABLE results_vma(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            palier INTEGER,
            vma REAL,
            date TEXT
          );
        ''');
  }
}

/// Modèle d'une séance d'exercice (pompes/tractions)
class ExerciseSession {
  final int? id;
  final String exerciseType; // 'traction' | 'pompe'
  final int setsPlanned;
  final int repsPerSetPlanned;
  final int restSecondsPlanned;
  final int setsCompleted; // nb de séries terminées
  final int totalReps; // total de répétitions effectuées (toutes séries confondues)
  final DateTime startedAt;
  final DateTime endedAt;
  final String? notes;

  const ExerciseSession({
    this.id,
    required this.exerciseType,
    required this.setsPlanned,
    required this.repsPerSetPlanned,
    required this.restSecondsPlanned,
    required this.setsCompleted,
    required this.totalReps,
    required this.startedAt,
    required this.endedAt,
    this.notes,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'exercise_type': exerciseType,
        'sets_planned': setsPlanned,
        'reps_per_set_planned': repsPerSetPlanned,
        'rest_seconds_planned': restSecondsPlanned,
        'sets_completed': setsCompleted,
        'total_reps': totalReps,
        'started_at_ms': startedAt.millisecondsSinceEpoch,
        'ended_at_ms': endedAt.millisecondsSinceEpoch,
        'notes': notes,
      };

  static ExerciseSession fromMap(Map<String, Object?> row) => ExerciseSession(
        id: row['id'] as int?,
        exerciseType: row['exercise_type'] as String,
        setsPlanned: row['sets_planned'] as int,
        repsPerSetPlanned: row['reps_per_set_planned'] as int,
        restSecondsPlanned: row['rest_seconds_planned'] as int,
        setsCompleted: row['sets_completed'] as int,
        totalReps: row['total_reps'] as int,
        startedAt: DateTime.fromMillisecondsSinceEpoch(row['started_at_ms'] as int),
        endedAt: DateTime.fromMillisecondsSinceEpoch(row['ended_at_ms'] as int),
        notes: row['notes'] as String?,
      );
}

/// DAO minimal pour manipuler les séances
class SessionDao {
  static const String table = 'exercise_sessions';

  static Future<int> insert(ExerciseSession session) async {
    final db = await AppDatabase().database;
    return db.insert(
      table,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // NB: ConflictAlgorithm.replace écrase sur clé primaire identique.
  }

  static Future<List<ExerciseSession>> listAll() async {
    final db = await AppDatabase().database;
    final rows = await db.query(table, orderBy: 'started_at_ms DESC');
    return rows.map((r) => ExerciseSession.fromMap(r)).toList();
  }

  static Future<List<ExerciseSession>> listByType(String type) async {
    final db = await AppDatabase().database;
    final rows = await db.query(
      table,
      where: 'exercise_type = ?',
      whereArgs: [type],
      orderBy: 'started_at_ms DESC',
    );
    return rows.map((r) => ExerciseSession.fromMap(r)).toList();
  }

  static Future<void> deleteAll() async {
    final db = await AppDatabase().database;
    await db.delete(table);
  }
}
