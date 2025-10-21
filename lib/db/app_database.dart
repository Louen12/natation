import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

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
        startedAt:
            DateTime.fromMillisecondsSinceEpoch(row['started_at_ms'] as int),
        endedAt: DateTime.fromMillisecondsSinceEpoch(row['ended_at_ms'] as int),
        notes: row['notes'] as String?,
      );
}

/// Accès base de données (SQLite sur mobile/desktop, IndexedDB via FFI web)
class AppDatabase {
  static Database? _db;

  /// Récupère (et initialise si besoin) l'instance de la base.
  static Future<Database> instance() async {
    if (_db != null) return _db!;

    // Configure la factory selon la plateforme
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      // Sur web, un nom de fichier simple est suffisant
      _db = await openDatabase('app.db', version: 1, onCreate: _onCreate);
      return _db!;
    }

    // Desktop (macOS/Linux/Windows)
    try {
      // L'appel à Platform.* casse sur web; ici on n'est pas sur web.
      if (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    } catch (_) {
      // no-op: sur iOS/Android, on garde la factory par défaut
    }

    final dbDir = await getDatabasesPath();
    final path = p.join(dbDir, 'app.db');
    _db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return _db!;
  }

  static FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercise_sessions (
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
      )
    ''');
    await db.execute('CREATE INDEX idx_sessions_type ON exercise_sessions (exercise_type)');
    await db.execute('CREATE INDEX idx_sessions_started ON exercise_sessions (started_at_ms DESC)');
  }
}

/// DAO minimal pour manipuler les séances
class SessionDao {
  static const String table = 'exercise_sessions';

  static Future<int> insert(ExerciseSession session) async {
    final db = await AppDatabase.instance();
    return db.insert(table, session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<ExerciseSession>> listAll() async {
    final db = await AppDatabase.instance();
    final rows = await db.query(table, orderBy: 'started_at_ms DESC');
    return rows.map((r) => ExerciseSession.fromMap(r)).toList();
  }

  static Future<List<ExerciseSession>> listByType(String type) async {
    final db = await AppDatabase.instance();
    final rows = await db.query(
      table,
      where: 'exercise_type = ?',
      whereArgs: [type],
      orderBy: 'started_at_ms DESC',
    );
    return rows.map((r) => ExerciseSession.fromMap(r)).toList();
  }

  static Future<void> deleteAll() async {
    final db = await AppDatabase.instance();
    await db.delete(table);
  }
}
