
class JumpStats {
  final int count;
  final double avgHeightM;
  final double minHeightM;
  final double maxHeightM;
  final double totalCaloriesKcal;

  const JumpStats({
    required this.count,
    required this.avgHeightM,
    required this.minHeightM,
    required this.maxHeightM,
    required this.totalCaloriesKcal,
  });

  JumpStats copyWith({
    int? count,
    double? avgHeightM,
    double? minHeightM,
    double? maxHeightM,
    double? totalCaloriesKcal,
  }) => JumpStats(
    count: count ?? this.count,
    avgHeightM: avgHeightM ?? this.avgHeightM,
    minHeightM: minHeightM ?? this.minHeightM,
    maxHeightM: maxHeightM ?? this.maxHeightM,
    totalCaloriesKcal: totalCaloriesKcal ?? this.totalCaloriesKcal,
  );

  static const empty = JumpStats(
    count: 0,
    avgHeightM: 0,
    minHeightM: double.infinity,
    maxHeightM: 0,
    totalCaloriesKcal: 0,
  );
}

class MetricsAggregator {
  final double massKg;
  final double g;
  final double muscleEfficiency; // 0.25 par défaut
  int _n = 0;
  double _mean = 0;    // Welford mean
  double _min = double.infinity;
  double _max = 0;
  double _kcal = 0;

  MetricsAggregator({
    required this.massKg,
    this.g = 9.80665,
    this.muscleEfficiency = 0.25,
  });

  // Renvoie les stats mises à jour après avoir ajouté un saut
  JumpStats addSample({required Duration airTime}) {
    final t = airTime.inMicroseconds / 1e6; // en secondes
    final h = g * t * t / 8.0;              // hauteur en mètres

    // Welford update
    _n += 1;
    final delta = h - _mean;
    _mean += delta / _n;

    if (h < _min) _min = h;
    if (h > _max) _max = h;

    final kcal = (massKg * g * h) / (muscleEfficiency * 4184.0);
    _kcal += kcal;

    return JumpStats(
      count: _n,
      avgHeightM: _mean,
      minHeightM: _min.isFinite ? _min : 0,
      maxHeightM: _max,
      totalCaloriesKcal: _kcal,
    );
  }

  JumpStats get snapshot => JumpStats(
    count: _n,
    avgHeightM: _mean,
    minHeightM: _min.isFinite ? _min : 0,
    maxHeightM: _max,
    totalCaloriesKcal: _kcal,
  );

  void reset() {
    _n = 0;
    _mean = 0;
    _min = double.infinity;
    _max = 0;
    _kcal = 0;
  }
}
