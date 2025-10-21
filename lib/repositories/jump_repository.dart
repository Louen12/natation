import 'package:sqflite/sqflite.dart';
import '../models/jump_session.dart';
import '../services/database_service.dart';

class JumpRepository {
  static final JumpRepository _instance = JumpRepository._internal();
  factory JumpRepository() => _instance;
  JumpRepository._internal();

  final DatabaseService _dbService = DatabaseService();

  Future<Database> get database async => await _dbService.database;

  // CRUD Operations
  Future<int> insertSession(JumpSession session) async {
    final db = await database;
    return await db.insert('jump_sessions', session.toMap());
  }

  Future<List<JumpSession>> getAllSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'jump_sessions',
      orderBy: 'start_time DESC',
    );
    return List.generate(maps.length, (i) => JumpSession.fromMap(maps[i]));
  }

  Future<JumpSession?> getSessionById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'jump_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return JumpSession.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSession(JumpSession session) async {
    final db = await database;
    return await db.update(
      'jump_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete(
      'jump_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;
    
    // Total sessions
    final totalSessions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM jump_sessions')
    ) ?? 0;

    // Total repetitions
    final totalRepetitions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(repetitions) FROM jump_sessions')
    ) ?? 0;

    // Total calories
    final totalCalories = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(total_calories) FROM jump_sessions')
    )?.toDouble() ?? 0.0;

    // Max height ever achieved
    final maxHeight = Sqflite.firstIntValue(
      await db.rawQuery('SELECT MAX(max_height) FROM jump_sessions')
    )?.toDouble() ?? 0.0;

    // Average power
    final averagePower = Sqflite.firstIntValue(
      await db.rawQuery('SELECT AVG(average_power) FROM jump_sessions')
    )?.toDouble() ?? 0.0;

    return {
      'totalSessions': totalSessions,
      'totalRepetitions': totalRepetitions,
      'totalCalories': totalCalories,
      'maxHeight': maxHeight,
      'averagePower': averagePower,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
