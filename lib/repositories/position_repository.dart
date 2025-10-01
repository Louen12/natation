import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';
import '../models/position.dart';

class PositionRepository {
  Future<Database> get _db async => AppDatabase().database;

  Future<int> insert(Position p) async {
    final db = await _db;
    return db.insert('positions', p.toMap());
  }

  Future<List<Position>> getByExerciseId(int exerciseId) async {
    final db = await _db;
    final rows = await db.query(
      'positions',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'id ASC',
    );
    return rows.map((m) => Position.fromMap(m)).toList();
  }

  Future<int> deleteByExerciseId(int exerciseId) async {
    final db = await _db;
    return db.delete(
      'positions',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
  }
}
