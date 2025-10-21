import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';

class VmaRepository {
  Future<Database> get _db async => AppDatabase().database;

  Future<void> insertResult(int palier, double vma) async {
    final db = await _db;
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
    final db = await _db;
    return await db.query('results', orderBy: 'date DESC');
  }

  Future<void> clearResults() async {
    final db = await _db;
    await db.delete('results');
  }

  Future<void> deleteOneResult(int id) async {
    final db = await _db;
    await db.delete('results', where: 'id = ?', whereArgs: [id]);
  }
}