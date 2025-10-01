import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/sensor_service.dart';

/// États du cycle d'une répétition
enum Phase { idle, goingDown, bottom, goingUp }

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // === Plan FIXE (non modifiable dans l'UI) ================================
  static const WorkoutPlan plan = WorkoutPlan.defaultPlan;

  // === État de la session ==================================================
  int currentSet = 1;
  int currentReps = 0;
  bool inRest = false;
  int restRemaining = 0;

  // === Capteur & comptage ==================================================
  final _sensor = SensorService(alpha: 0.9);
  StreamSubscription<double>? _sensorSub;
  Phase _phase = Phase.idle;
  double value = 0; // magnitude filtrée affichée pour debug

  // Seuils ADAPTATIFS (calculés à la calibration)
  double _downThresh = 0.0;
  double _upThresh = 0.0;

  // Anti double-comptage
  static const Duration _minDelayBetweenReps = Duration(milliseconds: 900);
  DateTime _lastRep = DateTime.fromMillisecondsSinceEpoch(0);

  // Anti-bounce autour du bas
  static const Duration _minBottomHold = Duration(milliseconds: 120);
  DateTime _bottomAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Timer de repos
  Timer? _restTimer;

  @override
  void dispose() {
    _sensorSub?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  // ---------------------- Calibration ------------------------------------
  /// Calibre automatiquement les seuils à partir de 1s immobile.
  /// On mesure μ et σ de la magnitude filtrée au repos,
  /// puis: down = μ - kσ, up = μ + kσ
  Future<void> _calibrate() async {
    final samples = <double>[];
    final sub = _sensor.magnitudeStream.listen(samples.add);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    await sub.cancel();

    if (samples.isEmpty) return;
    final mu = samples.reduce((a, b) => a + b) / samples.length;
    final varSum = samples.fold<double>(0.0, (s, v) => s + math.pow(v - mu, 2));
    final sigma = math.sqrt(varSum / samples.length);

    const k = 2.0; // plus grand => seuils plus exigeants
    _downThresh = mu - k * sigma;
    _upThresh = mu + k * sigma;

    // garde-fous (la magnitude est souvent autour de ~0 au repos sur userAccelerometer)
    // On impose un min d'écart pour éviter d'être trop sensible.
    final minGap = 0.15; // en g approximatif (acc units)
    if ((_upThresh - mu) < minGap) _upThresh = mu + minGap;
    if ((mu - _downThresh) < minGap) _downThresh = mu - minGap;
  }

  // ---------------------- Contrôles séance --------------------------------
  void _startWorkout() async {
    setState(() {
      currentSet = 1;
      currentReps = 0;
      inRest = false;
      restRemaining = 0;
      _phase = Phase.idle;
    });

    // Calibration (téléphone immobile 1 seconde)
    await _calibrate();

    _startSensor();
  }

  void _startSensor() {
    _sensorSub?.cancel();
    _phase = Phase.idle;
    _sensorSub = _sensor.magnitudeStream.listen((v) {
      value = v;
      if (inRest) return; // on ignore pendant le repos

      switch (_phase) {
        case Phase.idle:
        // Descente détectée ssi on passe SOUS le seuil "down"
          if (value < _downThresh) _phase = Phase.goingDown;
          break;

        case Phase.goingDown:
        // On a atteint le bas quand on remonte AU-DESSUS de down
          if (value >= _downThresh) {
            _phase = Phase.bottom;
            _bottomAt = DateTime.now();
          }
          break;

        case Phase.bottom:
        // Petite pause anti-rebond, puis on attend la remontée franchissant "up"
          if (DateTime.now().difference(_bottomAt) >= _minBottomHold &&
              value > _upThresh) {
            _phase = Phase.goingUp;
          }
          break;

        case Phase.goingUp:
        // Fin de montée lorsqu'on retombe sous up -> fin de cycle
          if (value <= _upThresh) {
            final now = DateTime.now();
            final okDelay = now.difference(_lastRep) >= _minDelayBetweenReps;

            _phase = Phase.idle; // on réarme toujours le cycle

            if (okDelay) {
              _lastRep = now;
              setState(() => currentReps++);
              if (currentReps >= plan.repsPerSet) _onSetFinished();
            }
          }
          break;
      }

      // rafraîchit l'affichage (debug)
      setState(() {});
    });
  }

  void _onSetFinished() {
    _sensorSub?.cancel();
    if (currentSet >= plan.sets) {
      // Fin de l'entraînement
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Bravo'),
          content: const Text('Tu as terminé toutes les séries !'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _stopWorkout();
              },
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

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => restRemaining--);
      if (restRemaining <= 0) {
        timer.cancel();
        setState(() {
          inRest = false;
          currentSet++;
          currentReps = 0;
          _phase = Phase.idle;
        });
        _startSensor();
      }
    });
  }

  void _stopWorkout() {
    _sensorSub?.cancel();
    _restTimer?.cancel();
    setState(() {
      currentSet = 1;
      currentReps = 0;
      inRest = false;
      restRemaining = 0;
      _phase = Phase.idle;
    });
  }

  // --------------------------- UI -----------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tractions - Séries')),
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
                      'Astuce: poche poitrine / brassard. Rester immobile 1s après "Démarrer" (calibration).',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
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
                  label: const Text('Stop'),
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
              Text(
                '$restRemaining s',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
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
              // Debug utile pour régler si besoin
              Text(
                'Phase: $_phase • value: ${value.toStringAsFixed(3)}\n'
                    'down=${_downThresh.toStringAsFixed(3)} • up=${_upThresh.toStringAsFixed(3)}',
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
