import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/tjtq_traction.dart';
import '../services/tjtq_traction_sensor_service.dart';

/// 1 rep = descent -> bottom -> ascent validée
enum Phase { idle, descent, bottom, ascent }

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});
  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // Plan fixe
  static const TractionPlan plan = TractionPlan.defaultPlan;

  // État séance
  int currentSet = 1;
  int currentReps = 0;
  bool inRest = false;
  int restRemaining = 0;

  // Capteur (vertical projeté + lissé via le service)
  final _sensor = SensorService(alphaGravity: 0.96, alphaSmooth: 0.90);
  StreamSubscription<double>? _sub;

  // Signal (debug)
  double val = 0.0;

  // FSM
  Phase _phase = Phase.idle;
  DateTime _phaseStart = DateTime.now();

  // Seuils adaptatifs
  double base = 0.0;     // baseline lente
  double ampThresh = 0.6; // amplitude min pour valider
  double slopeEps  = 0.03; // pente mini
  double downGate  = -0.2; // porte basse
  double upGate    =  0.2; // porte haute

  // Mémoire du cycle
  double minInDescent = 0.0;
  double maxInAscent  = 0.0;

  // Anti-doublons
  static const minBottomHold = Duration(milliseconds: 50);
  static const refractory    = Duration(milliseconds: 500);
  static const maxPhaseMs    = 2500;
  DateTime _bottomAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastRep  = DateTime.fromMillisecondsSinceEpoch(0);

  // Timer repos
  Timer? _restTimer;

  // Lissage (moyenne glissante + pente rapide)
  final int _maLen = 3;     // très court
  final int _slopeLag = 1;  // pente quasi-instantanée
  final List<double> _buf = <double>[];
  double _ma = 0.0;
  double _maLagged = 0.0;

  // Streaks
  int _downStreak = 0;
  int _upStreak = 0;
  int _needStreak = 1;

  @override
  void dispose() {
    _sub?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  // -------- Calibration --------
  Future<void> _calibrate() async {
    final samples = <double>[];
    final sub = _sensor.verticalStream().listen(samples.add);
    await Future<void>.delayed(const Duration(milliseconds: 800)); // plus court
    await sub.cancel();
    if (samples.isEmpty) return;

    final mu = samples.reduce((a, b) => a + b) / samples.length;
    final varSum = samples.fold<double>(0.0, (s, v) => s + (v - mu) * (v - mu));
    final sigma = math.sqrt(varSum / samples.length);

    base = mu;

    // Portes très basses (franchissement facile)
    final gate = math.max(0.15, sigma * 1.2);
    downGate = -gate;
    upGate   =  gate;

    // Amplitude minimale très basse (s’ajustera ensuite)
    ampThresh = math.max(0.40, sigma * 1.2);

    // Pente mini très faible (accepte vite le changement de sens)
    slopeEps  = math.max(0.02, sigma * 0.25);

    // Streak
    _needStreak = 1;
  }

  // -------- Contrôles séance --------
  void _startWorkout() async {
    setState(() {
      currentSet = 1;
      currentReps = 0;
      inRest = false;
      restRemaining = 0;
      _phase = Phase.idle;
      _phaseStart = DateTime.now();
    });

    await _calibrate();
    _startSensor();
  }

  // Moyenne glissante + valeur retardée pour pente
  double _updateMA(double v) {
    _buf.add(v);
    if (_buf.length > _maLen) _buf.removeAt(0);

    _ma = _buf.fold<double>(0.0, (s, x) => s + x) / _buf.length;

    if (_buf.length >= _slopeLag) {
      final int idx = _buf.length - _slopeLag;
      final slice = _buf.sublist(0, idx);
      _maLagged = slice.isEmpty
          ? _ma
          : slice.fold<double>(0.0, (s, x) => s + x) / slice.length;
    } else {
      _maLagged = _ma;
    }
    return _ma;
  }

  void _startSensor() {
    _sub?.cancel();
    _phase = Phase.idle;
    _phaseStart = DateTime.now();
    minInDescent = 0;
    maxInAscent  = 0;
    _buf.clear();
    _downStreak = 0;
    _upStreak   = 0;

    _sub = _sensor.verticalStream().listen((vRaw) {
      val = vRaw;
      if (inRest) return;

      // baseline lente
      base = base * 0.995 + val * 0.005;

      final currentMA = _updateMA(val);
      final slope = currentMA - _maLagged;

      final now = DateTime.now();
      final dtMs = now.difference(_phaseStart).inMilliseconds;

      // streaks
      if (slope < -slopeEps) {
        _downStreak++; _upStreak = 0;
      } else if (slope > slopeEps) {
        _upStreak++; _downStreak = 0;
      } else {
        _downStreak = 0; _upStreak = 0;
      }

      switch (_phase) {
        case Phase.idle:
          if ((currentMA - base) < downGate && _downStreak >= _needStreak) {
            _phase = Phase.descent;
            _phaseStart = now;
            minInDescent = currentMA;
            _downStreak = 0;
          }
          break;

        case Phase.descent:
          if (currentMA < minInDescent) minInDescent = currentMA;
          if (_upStreak >= _needStreak) {
            _phase = Phase.bottom;
            _phaseStart = now;
            _bottomAt = now;
            _upStreak = 0;
          }
          if (dtMs > maxPhaseMs) _resetToIdle(now);
          break;

        case Phase.bottom:
          if (now.difference(_bottomAt) >= minBottomHold &&
              (currentMA - base) > upGate && // porte haute
              _upStreak >= _needStreak) {
            _phase = Phase.ascent;
            _phaseStart = now;
            maxInAscent = currentMA;
            _upStreak = 0;
          }
          if (dtMs > maxPhaseMs) _resetToIdle(now);
          break;

        case Phase.ascent:
          if (currentMA > maxInAscent) maxInAscent = currentMA;

          // Fin de montée = pente re-négative (ou retombée sous upGate)
          final ascentDone = _downStreak >= _needStreak ||
              (currentMA - base) < (upGate * 0.5); // sortie souple

          if (ascentDone) {
            final amp = (maxInAscent - minInDescent).abs();
            final refractoryOk = now.difference(_lastRep) >= refractory;

            // accepte si >= 60% du seuil ou seuil atteint
            final reachedMain = amp >= ampThresh;
            final reachedSoft = amp >= ampThresh * 0.60;

            if ((reachedMain || reachedSoft) && refractoryOk) {
              _lastRep = now;
              setState(() => currentReps++);

              // Ajustements doux : rapprocher ampThresh de ce que tu fais
              final target = math.max(ampThresh * 0.85, amp);
              ampThresh = 0.6 * ampThresh + 0.4 * target;
              base = base * 0.9 + ((minInDescent + maxInAscent) / 2.0) * 0.1;

              if (currentReps >= plan.repsPerSet) {
                _onSetFinished();
                return;
              }
            }

            _resetToIdle(now);
          }

          if (dtMs > maxPhaseMs) _resetToIdle(now);
          break;
      }

      setState(() {});
    });
  }

  void _resetToIdle(DateTime now) {
    _phase = Phase.idle;
    _phaseStart = now;
    minInDescent = 0;
    maxInAscent = 0;
    _downStreak = 0;
    _upStreak = 0;
  }

  void _onSetFinished() {
    _sub?.cancel();
    if (currentSet >= plan.sets) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Bravo'),
          content: const Text('Tu as terminé toutes les séries !'),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); _stopWorkout(); },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _startRest();
    }
  }

  void _startRest() {
    setState(() {
      inRest = true;
      restRemaining = plan.restSeconds;
    });
    _sub?.cancel();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => restRemaining--);
      if (restRemaining <= 0) {
        t.cancel();
        setState(() {
          inRest = false;
          currentSet++;
          currentReps = 0;
          _phase = Phase.idle;
          _phaseStart = DateTime.now();
        });
        _startSensor();
      }
    });
  }

  void _stopWorkout() {
    _sub?.cancel();
    _restTimer?.cancel();
    setState(() {
      currentSet = 1;
      currentReps = 0;
      inRest = false;
      restRemaining = 0;
      _phase = Phase.idle;
      _phaseStart = DateTime.now();
    });
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tractions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text('Plan fixe', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '${plan.sets} séries × ${plan.repsPerSet} reps • Repos ${plan.restSeconds}s',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Conseil: poche poitrine ou brassard.\n'
                          'Restez immobile 1s après "Démarrer" pour calibrer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _startWorkout,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Démarrer'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _stopWorkout,
                  icon: const Icon(Icons.stop),
                  label: const Text('Réinitialiser'),
                ),
              ],
            ),

            const Divider(height: 32),

            Text(
              'Série $currentSet / ${plan.sets}',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            if (inRest) ...[
              const Text('Repos', textAlign: TextAlign.center),
              Text('$restRemaining s',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: plan.restSeconds == 0
                    ? 1
                    : (plan.restSeconds - restRemaining) / plan.restSeconds,
              ),
            ] else ...[
              const Text('Répétitions', textAlign: TextAlign.center),
              Text(
                '$currentReps / ${plan.repsPerSet}',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'phase=$_phase  val=${val.toStringAsFixed(2)} base=${base.toStringAsFixed(2)}\n'
                    'gates: down=${downGate.toStringAsFixed(2)} up=${upGate.toStringAsFixed(2)}  '
                    'ampMin=${ampThresh.toStringAsFixed(2)} slope>${slopeEps.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
