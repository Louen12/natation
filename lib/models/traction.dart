/// Plan d'entraînement
class TractionPlan {
  final int sets;        // nb de séries
  final int repsPerSet;  // nb de répétitions par série
  final int restSeconds; // repos entre séries (en secondes)

  const TractionPlan({
    required this.sets,
    required this.repsPerSet,
    required this.restSeconds,
  });
}
