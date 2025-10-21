import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';

class RunRepository {
  Future<Database> get _db async => AppDatabase().database;

  Future<void> insertResult({
    int? exerciseId,
    required double distanceMeters,
    required int durationSeconds,
    required bool success,
    DateTime? date,
  }) async {
    final db = await _db;
    await db.insert(
      'run_results',
      {
        'exercise_id': exerciseId,
        'distance_m': distanceMeters,
        'duration_s': durationSeconds,
        'success': success ? 1 : 0,
        'date': (date ?? DateTime.now()).toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getResults() async {
    final db = await _db;
    return await db.query('run_results', orderBy: 'date DESC');
  }

  Future<void> clearResults() async {
    final db = await _db;
    await db.delete('run_results');
  }

  Future<void> deleteOneResult(int id) async {
    final db = await _db;
    await db.delete('run_results', where: 'id = ?', whereArgs: [id]);
  }
}
