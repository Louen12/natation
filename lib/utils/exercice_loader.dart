import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exercice.dart';

class EntrainementData {
  final Bio bio;
  final List<Exercice> exercices;
  EntrainementData({required this.bio, required this.exercices});
}

Future<EntrainementData> loadEntrainementFromAsset(String path) async {
  final data = await rootBundle.loadString(path);
  final Map<String, dynamic> jsonMap = json.decode(data);
  final bio = Bio.fromJson(jsonMap['bio']);
  final exercices = (jsonMap['exercice'] as List)
      .map((e) => Exercice.fromJson(e as Map<String, dynamic>))
      .toList();
  return EntrainementData(bio: bio, exercices: exercices);
}

