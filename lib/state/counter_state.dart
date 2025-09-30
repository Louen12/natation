import '../logic/rep_fsm.dart';
import '../models/thresholds.dart';

class CounterState {
  final int reps;
  final double z;              // dernière valeur filtrée
  final Thresholds thresholds; // down/up
  final Phase phase;

  const CounterState({
    required this.reps,
    required this.z,
    required this.thresholds,
    required this.phase,
  });

  factory CounterState.initial() => const CounterState(
    reps: 0,
    z: 0,
    thresholds: Thresholds.pullUps,
    phase: Phase.idle,
  );

  CounterState copyWith({
    int? reps,
    double? z,
    Thresholds? thresholds,
    Phase? phase,
  }) {
    return CounterState(
      reps: reps ?? this.reps,
      z: z ?? this.z,
      thresholds: thresholds ?? this.thresholds,
      phase: phase ?? this.phase,
    );
  }
}
