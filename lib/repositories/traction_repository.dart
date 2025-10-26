import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';
import '../models/traction.dart';

class TractionRepository {
  // Raccourci pour accéder à la DB
  Future<Database> get _db async => AppDatabase().database;

  /// Récupère le dernier plan de traction en base (le plus récent).
  /// Retourne null si la table est vide.
  Future<TractionPlan?> getLatestPlan() async {
    final db = await _db;
    final rows = await db.query(
      'traction_plans',
      orderBy: 'id DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return TractionPlan.fromMap(rows.first);
  }

  /// (Optionnel) Récupérer tous les plans disponibles.
  Future<List<TractionPlan>> getAllPlans() async {
    final db = await _db;
    final rows = await db.query(
      'traction_plans',
      orderBy: 'id ASC',
    );
    return rows.map((m) => TractionPlan.fromMap(m)).toList();
  }

  /// (Optionnel) Insérer un nouveau plan (ex si tu veux un mode "personnalisé").
  Future<int> insertPlan(TractionPlan plan) async {
    final db = await _db;
    return db.insert(
      'traction_plans',
      {
        'sets': plan.sets,
        'reps_per_set': plan.repsPerSet,
        'rest_seconds': plan.restSeconds,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// (Optionnel) Mettre à jour un plan existant (si tu ajoutes un écran édition).
  Future<void> updatePlan(TractionPlan plan) async {
    if (plan.id == null) return;
    final db = await _db;
    await db.update(
      'traction_plans',
      {
        'sets': plan.sets,
        'reps_per_set': plan.repsPerSet,
        'rest_seconds': plan.restSeconds,
      },
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  /// (Optionnel) Supprimer un plan
  Future<void> deletePlan(int id) async {
    final db = await _db;
    await db.delete(
      'traction_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
