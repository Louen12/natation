import 'package:flutter/material.dart';

enum Stroke {
  freestyle('NL', Icons.waves),
  backstroke('Dos', Icons.rotate_left),
  breaststroke('Brasse', Icons.accessibility_new),
  butterfly('Papillon', Icons.air),
  medley('4N', Icons.all_inclusive);

  final String label;
  final IconData icon;
  const Stroke(this.label, this.icon);
}

class TrainingSet {
  final int distance;
  final Stroke stroke;
  final int repetitions;
  final String? comment;
  final String? intensity;

  const TrainingSet({
    required this.distance,
    required this.stroke,
    this.repetitions = 1,
    this.comment,
    this.intensity,
  });

  int get totalDistance => distance * repetitions;
}

class TrainingSession {
  final String id;
  final String title;
  final DateTime date;
  final List<TrainingSet> warmUp;
  final List<TrainingSet> mainSet;
  final List<TrainingSet> coolDown;
  final String? notes;

  const TrainingSession({
    required this.id,
    required this.title,
    required this.date,
    this.warmUp = const [],
    this.mainSet = const [],
    this.coolDown = const [],
    this.notes,
  });

  int get totalDistance => [
        ...warmUp,
        ...mainSet,
        ...coolDown,
      ].fold(0, (p, e) => p + e.totalDistance);
}

final sampleSessions = <TrainingSession>[
  TrainingSession(
    id: 'S1',
    title: 'Endurance aérobie',
    date: DateTime.now(),
    warmUp: const [
      TrainingSet(distance: 200, stroke: Stroke.freestyle, comment: 'Souple'),
      TrainingSet(distance: 50, stroke: Stroke.medley, repetitions: 4, comment: 'Technique 4N'),
    ],
    mainSet: const [
      TrainingSet(distance: 400, stroke: Stroke.freestyle, intensity: 'EN1', comment: 'Rythme constant'),
      TrainingSet(distance: 100, stroke: Stroke.freestyle, repetitions: 4, intensity: 'EN2', comment: 'Resp 3 temps'),
      TrainingSet(distance: 50, stroke: Stroke.freestyle, repetitions: 8, intensity: 'EN2', comment: '1 vite / 1 souple'),
    ],
    coolDown: const [
      TrainingSet(distance: 100, stroke: Stroke.backstroke, comment: 'Récup'),
    ],
    notes: 'Bien hydrater. Objectif technique : amplitude.',
  ),
  TrainingSession(
    id: 'S2',
    title: 'Vitesse + Technique',
    date: DateTime.now().subtract(const Duration(days: 1)),
    warmUp: const [
      TrainingSet(distance: 300, stroke: Stroke.freestyle, comment: 'Progressif'),
      TrainingSet(distance: 50, stroke: Stroke.butterfly, repetitions: 4, comment: 'Bras / Jambes alterné'),
    ],
    mainSet: const [
      TrainingSet(distance: 50, stroke: Stroke.freestyle, repetitions: 6, intensity: 'SP1', comment: '25 vite / 25 souple'),
      TrainingSet(distance: 25, stroke: Stroke.butterfly, repetitions: 4, intensity: 'SP2', comment: 'Max'),
    ],
    coolDown: const [
      TrainingSet(distance: 200, stroke: Stroke.medley, comment: 'Souple 4N'),
    ],
    notes: 'Travail de fréquence bras élevée sur papillon.',
  ),
  TrainingSession(id: 's3', title: 'entrainement Pylométrique', date: DateTime.now())
];
