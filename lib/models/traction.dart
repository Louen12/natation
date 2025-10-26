class TractionPlan {
  final int? id;          // id en base (nullable si pas encore inséré)
  final int sets;         // nb de séries
  final int repsPerSet;   // nb de répétitions par série
  final int restSeconds;  // repos entre séries (en secondes)

  const TractionPlan({
    this.id,
    required this.sets,
    required this.repsPerSet,
    required this.restSeconds,
  });

  factory TractionPlan.fromMap(Map<String, dynamic> map) {
    return TractionPlan(
      id: map['id'] as int?,
      sets: map['sets'] as int,
      repsPerSet: map['reps_per_set'] as int,
      restSeconds: map['rest_seconds'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sets': sets,
      'reps_per_set': repsPerSet,
      'rest_seconds': restSeconds,
    };
  }
}
