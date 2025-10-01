import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';
import '../models/exercise.dart';

class ExerciseRepository {
  Future<Database> get _db async => AppDatabase().database;

  Future<void> upsert(Exercise e) async {
    final db = await _db;
    await db.insert(
      'exercises',
      e.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

  Future<List<Exercise>> getAll() async {
    final db = await _db;
    final rows = await db.query('exercises', orderBy: 'id ASC');
    return rows.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<int> deleteById(int id) async {
    final db = await _db;
    return db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    final db = await _db;
    await db.delete('positions');
    await db.delete('exercises');
  }
}
