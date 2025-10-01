import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/exercise.dart';

class ExerciseApi {
  static Future<List<Exercise>> fetchExercises() async {
    // Simule le temps réseau
    // A modifier quand on fera une vraie requête HTTP vers le mockapi
    await Future.delayed(const Duration(seconds: 2));

    // Lecture du fichier local comme si c'était une réponse HTTP
    final jsonStr = await rootBundle.loadString('assets/db.json');
    final Map<String, dynamic> data = jsonDecode(jsonStr);

    final List<dynamic> list = data['exercice'] ?? [];
    return list
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
