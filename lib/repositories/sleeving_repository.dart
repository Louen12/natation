import 'package:sqflite/sqflite.dart';
import '../models/sleeving_session.dart';
import '../services/database_service.dart';

class SleevingRepository {
  static final SleevingRepository _instance = SleevingRepository._internal();
  factory SleevingRepository() => _instance;
  SleevingRepository._internal();

  final DatabaseService _dbService = DatabaseService();

  Future<Database> get database async => await _dbService.database;

  // CRUD Operations
  Future<int> insertSession(SleevingSession session) async {
    final db = await database;
    return await db.insert('sleeving_sessions', session.toMap());
  }

  Future<List<SleevingSession>> getAllSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sleeving_sessions',
      orderBy: 'start_time DESC',
    );
    return List.generate(maps.length, (i) => SleevingSession.fromMap(maps[i]));
  }

  Future<SleevingSession?> getSessionById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sleeving_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SleevingSession.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSession(SleevingSession session) async {
    final db = await database;
    return await db.update(
      'sleeving_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete(
      'sleeving_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;
    
    // Total sessions
    final totalSessions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sleeving_sessions')
    ) ?? 0;

    // Total repetitions
    final totalRepetitions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(repetitions) FROM sleeving_sessions')
    ) ?? 0;

    // Completed sessions (repetitions >= target)
    final completedSessions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sleeving_sessions WHERE repetitions >= target_repetitions')
    ) ?? 0;

    // Average hold time
    final averageHoldTime = Sqflite.firstIntValue(
      await db.rawQuery('SELECT AVG(average_hold_time) FROM sleeving_sessions')
    ) ?? 0;

    // Best session (most repetitions)
    final bestRepetitions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT MAX(repetitions) FROM sleeving_sessions')
    ) ?? 0;

    return {
      'totalSessions': totalSessions,
      'totalRepetitions': totalRepetitions,
      'completedSessions': completedSessions,
      'averageHoldTime': Duration(milliseconds: averageHoldTime),
      'bestRepetitions': bestRepetitions,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
