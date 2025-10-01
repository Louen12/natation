/// Plan d'entraînement
class WorkoutPlan {
  final int sets;        // nb de séries
  final int repsPerSet;  // nb de répétitions par série
  final int restSeconds; // repos entre séries (en secondes)

  const WorkoutPlan({
    required this.sets,
    required this.repsPerSet,
    required this.restSeconds,
  });

  /// TESTS
  static const WorkoutPlan defaultPlan = WorkoutPlan(
    sets: 3,
    repsPerSet: 8,
    restSeconds: 90,
  );
}
