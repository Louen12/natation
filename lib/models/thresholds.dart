class Thresholds {
  final double down;
  final double up;

  const Thresholds({required this.down, required this.up});

  // Valeurs par défaut pour tractions (à ajuster si besoin)
  static const pullUps = Thresholds(down: -0.8, up: 1.2);

  Thresholds copyWith({double? down, double? up}) =>
      Thresholds(down: down ?? this.down, up: up ?? this.up);
}
