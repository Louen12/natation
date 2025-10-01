
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class JumpEvent {
  final DateTime start;
  final DateTime landing;
  final Duration airTimeMs;
  final double peakTakeoffG;
  final double peakLandingG;
  const JumpEvent({
    required this.start,
    required this.landing,
    required this.airTimeMs,
    required this.peakTakeoffG,
    required this.peakLandingG,
  });
}

class JumpService with ChangeNotifier {
  // Public outputs
  final _events = StreamController<JumpEvent>.broadcast();
  Stream<JumpEvent> get events => _events.stream;
  final ValueNotifier<int> jumpCount = ValueNotifier<int>(0);

  // Subscriptions
  StreamSubscription? _accSub;
  StreamSubscription? _gyroSub;

  // Configs (ajuste selon device)
  static const double g = 9.80665;
  double takeoffThresholdG = 1.20;   // début impulsion
  double freefallThresholdG = 0.50;  // quasi apesanteur
  double landingThresholdG = 1.50;   // impact
  Duration minAirMs = Duration(milliseconds: 80);
  Duration maxAirMs = Duration(milliseconds: 2500);
  Duration sampleEvery = Duration(milliseconds: 8); // ~125 Hz cible

  // State
  DateTime _lastSample = DateTime.fromMillisecondsSinceEpoch(0);
  _State _state = _State.idle;
  DateTime? _tImpulsion;
  DateTime? _tAirStart;
  double _peakTakeoffG = 0;
  double _peakLandingG = 0;

  // Optionnel: tu peux utiliser le gyro pour filtrer les faux positifs
  double _lastGyroNorm = 0;

  bool get isRunning => _accSub != null;

  void start() {
    if (isRunning) return;

    _accSub = accelerometerEvents.listen(_onAccel);
    _gyroSub = gyroscopeEvents.listen((e) {
      _lastGyroNorm = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    });
  }

  void stop() {
    _accSub?.cancel(); _accSub = null;
    _gyroSub?.cancel(); _gyroSub = null;
    _reset();
  }

  void _onAccel(AccelerometerEvent e) {
    final now = DateTime.now();
    if (now.difference(_lastSample) < sampleEvery) return;
    _lastSample = now;

    // Norme en g
    final norm = sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / g;

    switch (_state) {
      case _State.idle:
      // impulsion de départ (takeoff)
        if (norm >= takeoffThresholdG) {
          _state = _State.loading; // phase d'impulsion
          _tImpulsion = now;
          _peakTakeoffG = norm;
        }
        break;

      case _State.loading:
        _peakTakeoffG = max(_peakTakeoffG, norm);
        // entrée en apesanteur
        if (norm <= freefallThresholdG) {
          _state = _State.airborne;
          _tAirStart = now;
        }
        // abandon si plus rien ne se passe
        if (now.difference(_tImpulsion!) > Duration(milliseconds: 500) && norm < 1.0) {
          _resetToIdle();
        }
        break;

      case _State.airborne:
      // rester en l'air
        final air = now.difference(_tAirStart!);
        if (air > maxAirMs) {
          // trop long, probablement bruit: on reset
          _resetToIdle();
          break;
        }
        // atterrissage
        if (norm >= landingThresholdG) {
          _peakLandingG = norm;
          final landing = now;
          final airTime = landing.difference(_tAirStart!);
          if (airTime >= minAirMs) {
            // On émet l'événement
            final evt = JumpEvent(
              start: _tImpulsion ?? _tAirStart!,
              landing: landing,
              airTimeMs: airTime,
              peakTakeoffG: _peakTakeoffG,
              peakLandingG: _peakLandingG,
            );
            if (!_events.isClosed) _events.add(evt);
            jumpCount.value += 1;
            notifyListeners();
          }
          _resetToIdle();
        }
        break;
    }
  }

  void _resetToIdle() {
    _state = _State.idle;
    _tImpulsion = null;
    _tAirStart = null;
    _peakTakeoffG = 0;
    _peakLandingG = 0;
  }

  void _reset() {
    _resetToIdle();
  }

  @override
  void dispose() {
    stop();
    _events.close();
    jumpCount.dispose();
    super.dispose();
  }
}

enum _State { idle, loading, airborne }
