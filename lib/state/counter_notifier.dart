import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/rep_fsm.dart';
import '../models/thresholds.dart';
import '../services/sensor_service.dart';
import 'counter_state.dart';

final counterProvider =
StateNotifierProvider<CounterNotifier, CounterState>((ref) {
  return CounterNotifier(SensorService());
});

class CounterNotifier extends StateNotifier<CounterState> {
  final SensorService _sensor;
  final RepFsm _fsm = RepFsm();
  StreamSubscription<double>? _sub;

  CounterNotifier(this._sensor) : super(CounterState.initial());

  void start() {
    _sub?.cancel();
    state = CounterState.initial();
    _sub = _sensor.zStream.listen(_onZ);
  }

  void stop() {
    _sub?.cancel();
    _fsm.reset();
  }

  void reset() {
    state = state.copyWith(reps: 0);
    _fsm.reset();
  }

  void updateThresholds(Thresholds t) {
    state = state.copyWith(thresholds: t);
  }

  void _onZ(double z) {
    final th = state.thresholds;
    final gotRep = _fsm.step(z, th.down, th.up);
    state = state.copyWith(
      z: z,
      phase: _fsm.phase,
      reps: gotRep ? state.reps + 1 : state.reps,
    );
  }
}
