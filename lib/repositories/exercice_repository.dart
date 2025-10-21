import 'package:natation/models/exercice_perfomance.dart';
import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';
import '../models/exercise.dart';

class ExerciseRepository {
  Future<Database> get _db async => AppDatabase().database;

  /// Créer les exercices en base de données uniquement si la table exercises est vide.
  Future<void> seedIfEmpty(List<Exercise> items) async {
    final db = await _db;
    final cnt =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM exercises'),
        ) ??
        0;
    if (cnt == 0) {
      final batch = db.batch();
      for (final e in items) {
        batch.insert(
          'exercises',
          e.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }
  }

  /// Récupère tous les exercices.
  Future<List<Exercise>> getAll() async {
    final db = await _db;
    final rows = await db.query('exercises', orderBy: 'id ASC');
    return rows.map((m) => Exercise.fromMap(m)).toList();
  }

  /// Met à jour le statut "fait" d'un exercice.
  Future<void> setDone(int id, bool done) async {
    final db = await _db;
    await db.update(
      'exercises',
      {'is_done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Récupère un exercice par son ID.
  Future<Exercise?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Exercise.fromMap(rows.first);
  }

  /// Récupère un exercice par son Nom
  Future<Exercise?> getByName(int name) async {
    final db = await _db;
    final rows = await db.query(
      'exercises',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Exercise.fromMap(rows.first);
  }

  /// Met à jour le statut "réussie" d'un exercice.
  Future<void> setFailed(int id, bool failed) async {
    final db = await _db;
    await db.update(
      'exercises',
      {'is_failed': failed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Réinitialise le statut "fait" de tous les exercices du programme.
  Future<void> resetAllDone() async {
    final db = await _db;
    await db.update('exercises', {'is_done': 0});
  }

  Future<void> savePerformance(ExercisePerformance perf) async {
    final db = await _db;
    
    // Vérifier si la table existe, sinon la créer
    try {
      await db.rawQuery('SELECT 1 FROM exercise_performances LIMIT 1');
    } catch (e) {
      // Table n'existe pas, la créer
      await db.execute('''CREATE TABLE exercise_performances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER,
        date TEXT,
        repetitions INTEGER,
        duration INTEGER,
        average_hold_time INTEGER,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id)
      );''');
    }
    
    await db.insert('exercise_performances', perf.toMap());
  }
}
