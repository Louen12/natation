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

  /// Réinitialise le statut "fait" de tous les exercices du programme.
  Future<void> resetAllDone() async {
    final db = await _db;
    await db.update('exercises', {'is_done': 0});
  }
}
