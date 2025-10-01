import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/traction.dart';
import '../services/traction_sensor_service.dart';
import '../widgets/tjtq_circle_button.dart';
import '../widgets/tjtq_card.dart';

/// 1 rep = descent -> bottom -> ascent validée
enum Phase { idle, descent, bottom, ascent }

class TractionPage extends StatefulWidget {
  const TractionPage({super.key});
  @override
  State<TractionPage> createState() => _TractionPageState();
}

class _TractionPageState extends State<TractionPage> {
  // Plan fixe pour tests
  static const TractionPlan plan = TractionPlan.defaultPlan;

  // État séance
  int currentSet = 1;
  int currentReps = 0;
  bool inRest = false;
  int restRemaining = 0;
  bool isTractionRunning = false;

  // Capteur (vertical projeté + lissé via le service)
  final _sensor = SensorService(alphaGravity: 0.96, alphaSmooth: 0.90);
  StreamSubscription<double>? _sub;

  // Signal (debug)
  double val = 0.0;

  // FSM
  Phase _phase = Phase.idle;
  DateTime _phaseStart = DateTime.now();
  DateTime _tractionStarted = DateTime.now();

  // Seuils adaptatifs (noyau)
  double base = 0.0;
  double ampThresh = 0.6;
  double slopeEps = 0.03;
  double downGate = -0.2;
  double upGate = 0.2;

  // Mémoire du cycle
  double minInDescent = 0.0;
  double maxInAscent = 0.0;

  // Anti-doublons
  static const minBottomHold = Duration(milliseconds: 50);
  static const refractory = Duration(milliseconds: 500);
  static const maxPhaseMs = 2500;
  DateTime _bottomAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastRep = DateTime.fromMillisecondsSinceEpoch(0);

  // Timer repos
  Timer? _restTimer;

  // Lissage
  final int _maLen = 3;
  final int _slopeLag = 1;
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
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await sub.cancel();
    if (samples.isEmpty) return;

    final mu = samples.reduce((a, b) => a + b) / samples.length;
    final varSum =
        samples.fold<double>(0.0, (s, v) => s + (v - mu) * (v - mu));
    final sigma = math.sqrt(varSum / samples.length);

    base = mu;
    final gate = math.max(0.15, sigma * 1.2);
    downGate = -gate;
    upGate = gate;
    ampThresh = math.max(0.40, sigma * 1.2);
    slopeEps = math.max(0.02, sigma * 0.25);
    _needStreak = 1;
  }

  // -------- Laxisme progressif --------
  double _leniencyScale() {
    final since = DateTime.now().difference(_tractionStarted);
    if (since < const Duration(seconds: 25) && currentReps < 2) return 0.5;
    if (since < const Duration(seconds: 45) && currentReps < 4) return 0.75;
    return 1.0;
  }

  // -------- Contrôles séance --------
  void _startTraction() async {
    setState(() {
      isTractionRunning = true;
      currentSet = 1;
      currentReps = 0;
      inRest = false;
      restRemaining = 0;
      _phase = Phase.idle;
      _phaseStart = DateTime.now();
      _tractionStarted = DateTime.now();
    });

    await _calibrate();
    _startSensor();
  }

  void _stopTraction() {
    _sub?.cancel();
    _restTimer?.cancel();
    setState(() {
      isTractionRunning = false;
      currentSet = 1;
      currentReps = 0;
      inRest = false;
      restRemaining = 0;
      _phase = Phase.idle;
      _phaseStart = DateTime.now();
    });
  }

  // Moyenne glissante
  double _updateMA(double v) {
    _buf.add(v);
    if (_buf.length > _maLen) _buf.removeAt(0);
    _ma = _buf.fold<double>(0.0, (s, x) => s + x) / _buf.length;

    if (_buf.length >= _slopeLag) {
      final int idx = _buf.length - _slopeLag;
      final slice = _buf.sublist(0, idx);
      _maLagged =
          slice.isEmpty ? _ma : slice.fold<double>(0.0, (s, x) => s + x) / slice.length;
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
    maxInAscent = 0;
    _buf.clear();
    _downStreak = 0;
    _upStreak = 0;

    _sub = _sensor.verticalStream().listen((vRaw) {
      val = vRaw;
      if (inRest) return;

      base = base * 0.995 + val * 0.005;
      final currentMA = _updateMA(val);
      final slope = currentMA - _maLagged;
      final now = DateTime.now();
      final dtMs = now.difference(_phaseStart).inMilliseconds;

      final k = _leniencyScale();
      final gDown = downGate * k;
      final gUp = upGate * k;
      final aThresh = ampThresh * k;
      final sEps = slopeEps * k;

      final refracMs = (refractory.inMilliseconds * (0.5 + 0.5 * k)).round();
      final refractoryNow = Duration(milliseconds: refracMs);
      final maxPhaseNow = (maxPhaseMs * (1.0 + (1.0 - k))).round();

      if (slope < -sEps) {
        _downStreak++;
        _upStreak = 0;
      } else if (slope > sEps) {
        _upStreak++;
        _downStreak = 0;
      } else {
        _downStreak = 0;
        _upStreak = 0;
      }

      switch (_phase) {
        case Phase.idle:
          if ((currentMA - base) < gDown && _downStreak >= _needStreak) {
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
          if (dtMs > maxPhaseNow) _resetToIdle(now);
          break;
        case Phase.bottom:
          if (now.difference(_bottomAt) >= minBottomHold &&
              (currentMA - base) > gUp &&
              _upStreak >= _needStreak) {
            _phase = Phase.ascent;
            _phaseStart = now;
            maxInAscent = currentMA;
            _upStreak = 0;
          }
          if (dtMs > maxPhaseNow) _resetToIdle(now);
          break;
        case Phase.ascent:
          if (currentMA > maxInAscent) maxInAscent = currentMA;
          final ascentDone =
              _downStreak >= _needStreak || (currentMA - base) < (gUp * 0.5);

          if (ascentDone) {
            final amp = (maxInAscent - minInDescent).abs();
            final softRatio = (k < 1.0) ? 0.40 : 0.60;
            final reachedMain = amp >= aThresh;
            final reachedSoft = amp >= aThresh * softRatio;
            final refractoryOk = now.difference(_lastRep) >= refractoryNow;

            if ((reachedMain || reachedSoft) && refractoryOk) {
              _lastRep = now;
              setState(() => currentReps++);
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
          if (dtMs > maxPhaseNow) _resetToIdle(now);
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
              onPressed: () {
                Navigator.pop(context);
                _stopTraction();
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

  // -------- UI --------
  @override
  Widget build(BuildContext context) {
    final k = _leniencyScale();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 50), // <-- espace en haut
              child: ExerciseCard(
                title: "NATH A FOND",
                bestTime: "00:45",
                time: inRest ? "$restRemaining s" : "--:--",
                repetitions: currentReps,
                leftImage: "assets/images/guepard.png",
                rightImage: "assets/images/mesange.png",
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView(
                  children: [
                    Text(
                      "TRACTIONS x${plan.repsPerSet}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Accrochez-vous à la barre, bras tendus. "
                      "Montez jusqu'à ce que le menton passe au-dessus de la barre "
                      "puis redescendez doucement.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Icon(Icons.fitness_center,
                          size: 120, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Muscles sollicités",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Dos, biceps, abdominaux",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Série $currentSet / ${plan.sets}",
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
                            : (plan.restSeconds - restRemaining) /
                                plan.restSeconds,
                      ),
                    ] else ...[
                      const Text('Répétitions', textAlign: TextAlign.center),
                      Text(
                        '$currentReps / ${plan.repsPerSet}',
                        style: Theme.of(context).textTheme.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'phase=$_phase val=${val.toStringAsFixed(2)} '
                      'base=${base.toStringAsFixed(2)} k=${k.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleButton(
                    icon: Icons.fitness_center,
                    color: Colors.orange,
                    onTap: () {},
                  ),
                  CircleButton(
                    icon: isTractionRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.orange,
                    big: true,
                    onTap: isTractionRunning ? _stopTraction : _startTraction,
                  ),
                  CircleButton(
                    icon: Icons.stop,
                    color: Colors.grey,
                    onTap: _stopTraction,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
