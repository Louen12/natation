import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/tjtq_traction.dart';
import '../services/tjtq_traction_sensor_service.dart';

/// Phases du cycle (1 rep = descent -> bottom -> ascent validée)
enum Phase { idle, descent, bottom, ascent }

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});
  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // ---- Plan fixe -------------
  static const TractionPlan plan = TractionPlan.defaultPlan;

  // ---- État séance --------------------------------------------------------
  int currentSet = 1;
  int currentReps = 0;
  bool inRest = false;
  int restRemaining = 0;

  // ---- Capteur & détection ------------------------------------------------
  final _sensor = SensorService(alphaGravity: 0.96, alphaSmooth: 0.92);
  StreamSubscription<double>? _sub;

  // Signal vertical lissé (pour debug)
  double val = 0.0;
  double prev = 0.0;

  // FSM
  Phase _phase = Phase.idle;
  DateTime _phaseStart = DateTime.now();

  // Calibration / seuils adaptatifs
  double base = 0.0;         // baseline dynamique (milieu min/max)
  double ampThresh = 1.0;    // amplitude minimale pour valider une rep
  double slopeEps  = 0.1;    // pente minimale (hystérésis sur le sens)
  double downGate  = -0.6;   // porte "descente": sous base + gate -> descent
  double upGate    =  0.6;   // porte "montée": au-dessus de base + gate -> ascent

  // Mémoire min/max dans un cycle
  double minInDescent = 0.0;
  double maxInAscent  = 0.0;

  // Anti-doublons / garde-fous
  static const minBottomHold = Duration(milliseconds: 100);
  static const refractory    = Duration(milliseconds: 900); // délai entre 2 reps
  static const maxPhaseMs    = 2500;                         // max par phase
  DateTime _bottomAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastRep  = DateTime.fromMillisecondsSinceEpoch(0);

  // Timer repos
  Timer? _restTimer;

  @override
  void dispose() {
    _sub?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  // --------------------------- Calibration -------------------------------
  /// 1.2s immobile → moyenne & écart-type du signal vertical.
  /// On déduit les seuils : portes up/down, pente min, amplitude min.
  Future<void> _calibrate() async {
    final samples = <double>[];
    final sub = _sensor.verticalStream().listen(samples.add);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await sub.cancel();
    if (samples.isEmpty) return;

    final mu = samples.reduce((a, b) => a + b) / samples.length;
    final varSum = samples.fold<double>(0.0, (s, v) => s + (v - mu) * (v - mu));
    final sigma = math.sqrt(varSum / samples.length);

    base = mu;

    // Portes (hystérésis de franchissement) — plus sigma est gros, plus on exige
    final gate = math.max(0.35, sigma * 2);
    downGate = -gate;
    upGate   =  gate;

    // Amplitude minimale (écart min entre min et max d'un cycle)
    ampThresh = math.max(0.90, sigma * 3.0);

    // Pente minimale pour considérer un vrai changement de sens
    slopeEps = math.max(0.08, sigma * 0.6);
  }

  // --------------------------- Contrôles séance --------------------------
  void _startWorkout() async {
    setState(() {
      currentSet = 1;
      currentReps = 0;
      inRest = false;
      restRemaining = 0;
      _phase = Phase.idle;
      _phaseStart = DateTime.now();
    });

    // IMPORTANT: immobile ~1s après "Démarrer" (calibration)
    await _calibrate();
    _startSensor();
  }

  void _startSensor() {
    _sub?.cancel();
    _phase = Phase.idle;
    _phaseStart = DateTime.now();
    minInDescent = 0; maxInAscent = 0;

    _sub = _sensor.verticalStream().listen((v) {
      val = v;

      if (inRest) return;

      // Baseline adaptative lente (suivre dérive éventuelle)
      base = base * 0.995 + val * 0.005;

      // Signe / pente
      final slope = val - prev;
      prev = val;

      final now = DateTime.now();
      final dtMs = now.difference(_phaseStart).inMilliseconds;

      switch (_phase) {
        case Phase.idle:
        // Démarrage descente: on franchit base + porte "bas" avec pente négative
          if ((val - base) < downGate && slope < -slopeEps) {
            _phase = Phase.descent;
            _phaseStart = now;
            minInDescent = val;
          }
          break;

        case Phase.descent:
        // On mémorise le minimum local
          if (val < minInDescent) minInDescent = val;

          // Changement de sens vers la montée -> on marque le bas
          if (slope > slopeEps) {
            _phase = Phase.bottom;
            _phaseStart = now;
            _bottomAt = now;
          }

          if (dtMs > maxPhaseMs) { _resetToIdle(now); }
          break;

        case Phase.bottom:
        // Petite tenue au bas + franchissement de la porte haute
          if (now.difference(_bottomAt) >= minBottomHold &&
              (val - base) > upGate &&
              slope > slopeEps) {
            _phase = Phase.ascent;
            _phaseStart = now;
            maxInAscent = val;
          }

          if (dtMs > maxPhaseMs) { _resetToIdle(now); }
          break;

        case Phase.ascent:
        // On mémorise le maximum local
          if (val > maxInAscent) maxInAscent = val;

          // Fin de la montée: la pente redevient négative (on a passé le sommet)
          if (slope < -slopeEps) {
            final amp = (maxInAscent - minInDescent).abs();
            final refractoryOk = now.difference(_lastRep) >= refractory;

            if (amp >= ampThresh && refractoryOk) {
              _lastRep = now;
              setState(() => currentReps++);

              // Adaptation douce: on ajuste l'amplitude cible et la base
              ampThresh = 0.7 * ampThresh + 0.3 * amp;
              base = base * 0.9 + ((minInDescent + maxInAscent) / 2.0) * 0.1;

              if (currentReps >= plan.repsPerSet) { _onSetFinished(); return; }
            }

            _resetToIdle(now); // quel que soit le cas, on réarme
          }

          if (dtMs > maxPhaseMs) { _resetToIdle(now); }
          break;
      }

      // (debug UI)
      setState(() {});
    });
  }

  void _resetToIdle(DateTime now) {
    _phase = Phase.idle;
    _phaseStart = now;
    minInDescent = 0; maxInAscent = 0;
  }

  void _onSetFinished() {
    _sub?.cancel();
    if (currentSet >= plan.sets) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('🎉 Bravo'),
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

  // ----------------------------- UI ---------------------------------------
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
                    Text('Plan fixe',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '${plan.sets} séries × ${plan.repsPerSet} reps • Repos ${plan.restSeconds}s',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Conseil: Mettez votre téléphone dans votre poche. '
                          ' Après "Démarrer", restez immobile ~1s pour la calibration.',
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
              // Debug
              Text(
                'phase=$_phase  val=${val.toStringAsFixed(2)}  base=${base.toStringAsFixed(2)}\n'
                    'gates: down=${downGate.toStringAsFixed(2)}  up=${upGate.toStringAsFixed(2)}  '
                    'ampMin=${ampThresh.toStringAsFixed(2)}  slope>${slopeEps.toStringAsFixed(2)}',
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
