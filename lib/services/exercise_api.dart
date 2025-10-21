import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:natation/repositories/exercice_repository.dart';
import '../models/exercise.dart';

class ExerciseApi {
  static final _repo = ExerciseRepository();

  static Future<List<Exercise>> fetchExercises() async {
    // Simule un temps réseau
    // await Future.delayed(const Duration(seconds: 1));

    // Charge le JSON
    final jsonStr = await rootBundle.loadString('assets/db.json');
    final Map<String, dynamic> data = jsonDecode(jsonStr);
    final List<dynamic> list = data['exercice'] ?? [];

    final seed = list
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();

    // Seed en BDD les exercies à partir du json
    await _repo.seedIfEmpty(seed);

    return _repo.getAll();
  }
}
