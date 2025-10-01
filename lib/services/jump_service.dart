import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class JumpEvent {
  final DateTime start;       // approx takeoff onset
  final DateTime airborneAt;  // when freefall detected
  final DateTime landing;     // impact time
  final Duration airTime;     // landing - airborneAt
  final double peakTakeoffG;
  final double peakLandingG;

  const JumpEvent({
    required this.start,
    required this.airborneAt,
    required this.landing,
    required this.airTime,
    required this.peakTakeoffG,
    required this.peakLandingG,
  });
}

enum _State { idle, impulse, airborne, cooldown }

class _Ema {
  final double alpha;
  double? _y;
  _Ema(this.alpha);
  double next(double x) {
    _y = (_y == null) ? x : alpha * x + (1 - alpha) * _y!;
    return _y!;
  }
  double get value => _y ?? 0;
  void reset() => _y = null;
}

class JumpService with ChangeNotifier {
  // Public API
  final _events = StreamController<JumpEvent>.broadcast();
  Stream<JumpEvent> get events => _events.stream;
  final ValueNotifier<int> jumpCount = ValueNotifier<int>(0);

  // Subscriptions
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  // Config (ajuste si besoin)
  static const double g = 9.80665;
  Duration sampleEvery = const Duration(milliseconds: 8);    // ~125 Hz
  double takeoffHi = 1.25;       // g
  double freefallLo = 0.55;      // g
  double landingHi = 1.60;       // g
  Duration minAir = const Duration(milliseconds: 90);
  Duration maxAir = const Duration(milliseconds: 2500);
  Duration impulseTimeout = const Duration(milliseconds: 500);
  Duration cooldown = const Duration(milliseconds: 200);
  double gyroTakeoffMax = 12.0;  // rad/s approx; borne pour limiter faux positifs

  // Filters
  final _emaFast = _Ema(0.45);  // lissage rapide
  final _emaSlow = _Ema(0.08);  // tendance/gravity drift

  // State
  _State _state = _State.idle;
  DateTime _lastSample = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _tImpulse;
  DateTime? _tAir;
  DateTime? _tLand;
  double _peakTakeoff = 0;
  double _peakLanding = 0;
  double _gyroNorm = 0;

  bool get isRunning => _accSub != null;

  void start() {
    if (isRunning) return;
    _resetAll();
    _accSub = accelerometerEventStream().listen(_onAccel, onError: (_) {});
    _gyroSub = gyroscopeEventStream().listen((e) {
      _gyroNorm = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    }, onError: (_) {});
  }

  void stop() {
    _accSub?.cancel(); _accSub = null;
    _gyroSub?.cancel(); _gyroSub = null;
    _resetAll();
  }

  void _onAccel(AccelerometerEvent e) {
    final now = DateTime.now();
    if (now.difference(_lastSample) < sampleEvery) return;
    _lastSample = now;

    // Module en g
    final accG = sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / g;

    // Filtres
    final smooth = _emaFast.next(accG);
    final trend = _emaSlow.next(accG);
    final highPass = smooth - trend; // utile si tu veux des heuristiques sur impulsions

    switch (_state) {
      case _State.idle:
      // Départ: assez d'accélération et pas un grand moulinet de poignet
        if (accG > takeoffHi && _gyroNorm < gyroTakeoffMax) {
          _state = _State.impulse;
          _tImpulse = now;
          _peakTakeoff = accG;
        }
        break;

      case _State.impulse:
        _peakTakeoff = max(_peakTakeoff, accG);

        // Entrée en "quasi apesanteur"
        if (accG < freefallLo) {
          _state = _State.airborne;
          _tAir = now;
        }

        // Abandon si rien de concluant
        if (_tImpulse != null &&
            now.difference(_tImpulse!) > impulseTimeout &&
            (accG > 0.9 && accG < 1.1)) {
          _resetToIdle();
        }
        break;

      case _State.airborne:
        final air = (_tAir == null) ? Duration.zero : now.difference(_tAir!);
        if (air > maxAir) {
          // Probablement bruit + perte de détection d'impact
          _resetToIdle();
          break;
        }

        // Impact
        if (accG > landingHi) {
          _peakLanding = accG;
          _tLand = now;

          if (_tAir != null) {
            final airTime = _tLand!.difference(_tAir!);
            if (airTime >= minAir) {
              final evt = JumpEvent(
                start: _tImpulse ?? _tAir!,
                airborneAt: _tAir!,
                landing: _tLand!,
                airTime: airTime,
                peakTakeoffG: _peakTakeoff,
                peakLandingG: _peakLanding,
              );
              if (!_events.isClosed) _events.add(evt);
              jumpCount.value += 1;
              notifyListeners();
              _state = _State.cooldown;
            } else {
              _resetToIdle(); // pas un vrai saut
            }
          } else {
            _resetToIdle();
          }
        }
        break;

      case _State.cooldown:
        if (_tLand != null && now.difference(_tLand!) > cooldown) {
          _resetToIdle();
        }
        break;
    }

    // l’avantage de highPass est dispo si tu veux compléter par des heuristiques
    // ex: ignorer des spikes trop brefs: if (highPass.abs() < 0.05) ...
  }

  void _resetToIdle() {
    _state = _State.idle;
    _tImpulse = null;
    _tAir = null;
    _tLand = null;
    _peakTakeoff = 0;
    _peakLanding = 0;
  }

  void _resetAll() {
    _resetToIdle();
    _emaFast.reset();
    _emaSlow.reset();
    _gyroNorm = 0;
  }

  @override
  void dispose() {
    stop();
    _events.close();
    jumpCount.dispose();
    super.dispose();
  }
}
