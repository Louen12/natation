import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/traction.dart';
import '../services/traction_sensor_service.dart';
import '../widgets/tjtq_circle_button.dart';
import '../widgets/tjtq_card.dart';

/// Machine à états pour une traction:
/// idle -> descent -> bottom -> ascent -> rep validée
enum Phase { idle, descent, bottom, ascent }

class TractionPage extends StatefulWidget {
  const TractionPage({super.key});
  @override
  State<TractionPage> createState() => _TractionPageState();
}

class _TractionPageState extends State<TractionPage> {
  // Plan d’entraînement (démo)
  static const TractionPlan plan = TractionPlan.defaultPlan;

  // Etat courant de la séance
  int currentSet = 1;        // série en cours (1-based)
  int currentReps = 0;       // reps validées dans la série courante
  bool inRest = false;       // vrai pendant le repos entre séries
  int restRemaining = 0;     // secondes restantes de repos
  bool isTractionRunning = false;

  // Service capteurs: vertical projeté + lissage interne
  final _sensor = SensorService(alphaGravity: 0.96, alphaSmooth: 0.90);
  StreamSubscription<double>? _sub;

  // Dernière valeur brute/smoothed pour debug
  double val = 0.0;

  // Machine à états
  Phase _phase = Phase.idle;
  DateTime _phaseStart = DateTime.now();     // début de la phase courante
  DateTime _tractionStarted = DateTime.now(); // début de la séance (pour le laxisme)

  // Seuils adaptatifs (coeur du comptage)
  double base = 0.0;       // ligne de base glissante
  double ampThresh = 0.6;  // amplitude minimale pour valider une rep
  double slopeEps = 0.03;  // pente minimale pour compter trend up/down
  double downGate = -0.2;  // seuil de démarrage descente
  double upGate = 0.2;     // seuil de démarrage montée

  // Mémoire du cycle courant
  double minInDescent = 0.0; // minimum vu en descente
  double maxInAscent = 0.0;  // maximum vu en montée

  // Anti-doublons et garde-fous
  static const minBottomHold = Duration(milliseconds: 50); // micro-pause en bas
  static const refractory = Duration(milliseconds: 500);   // anti-double comptage
  static const maxPhaseMs = 2500;                          // timeout d’une phase
  DateTime _bottomAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastRep = DateTime.fromMillisecondsSinceEpoch(0);

  // Timer de repos entre séries
  Timer? _restTimer;

  // Lissage simple (moyenne glissante + décalage pour pente)
  final int _maLen = 3;          // taille de fenêtre MA
  final int _slopeLag = 1;       // décalage pour approx. la pente
  final List<double> _buf = <double>[]; // buffer des dernières valeurs
  double _ma = 0.0;              // moyenne courante
  double _maLagged = 0.0;        // moyenne décalée

  // Streaks de pente pour filtrer les micro-oscillations
  int _downStreak = 0;
  int _upStreak = 0;
  int _needStreak = 1; // nombre min. d’échantillons consécutifs dans un sens

  @override
  void dispose() {
    _sub?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  // -------- Calibration --------
  // Capture un court échantillon à l’arrêt pour estimer:
  // - base (ligne de base)
  // - amplitude et seuils directionnels en fonction du bruit (sigma)
  Future<void> _calibrate() async {
    final samples = <double>[];
    final sub = _sensor.verticalStream().listen(samples.add);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await sub.cancel();
    if (samples.isEmpty) return;

    // moyenne et écart-type approximatifs
    final mu = samples.reduce((a, b) => a + b) / samples.length;
    final varSum = samples.fold<double>(0.0, (s, v) => s + (v - mu) * (v - mu));
    final sigma = math.sqrt(varSum / samples.length);

    // seuils basés sur le bruit mesuré
    base = mu;
    final gate = math.max(0.15, sigma * 1.2);
    downGate = -gate;
    upGate = gate;
    ampThresh = math.max(0.40, sigma * 1.2);
    slopeEps = math.max(0.02, sigma * 0.25);
    _needStreak = 1;
  }

  // -------- Laxisme progressif --------
  // Assouplit les seuils au début de séance pour éviter la rep "perdue"
  // Retourne un facteur k dans [0.5; 1.0] multipliant les seuils.
  double _leniencyScale() {
    final since = DateTime.now().difference(_tractionStarted);
    if (since < const Duration(seconds: 25) && currentReps < 2) return 0.5;
    if (since < const Duration(seconds: 45) && currentReps < 4) return 0.75;
    return 1.0;
  }

  // -------- Contrôles séance --------
  void _startTraction() async {
    // Remise à zéro de la séance
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

    await _calibrate(); // calibrage initial
    _startSensor();     // démarrage du flux capteur
  }

  void _stopTraction() {
    _sub?.cancel();
    _restTimer?.cancel();
    // Retour à l’état initial
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

  // Moyenne glissante + moyenne décalée pour approximer la pente
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

  // Démarre l’écoute capteur et la logique de détection de reps
  void _startSensor() {
    _sub?.cancel();

    // Réinitialisation de la FSM et des buffers
    _phase = Phase.idle;
    _phaseStart = DateTime.now();
    minInDescent = 0;
    maxInAscent = 0;
    _buf.clear();
    _downStreak = 0;
    _upStreak = 0;

    _sub = _sensor.verticalStream().listen((vRaw) {
      val = vRaw;
      if (inRest) return; // ignore les données pendant le repos

      // Mise à jour lente de la base pour suivre une dérive éventuelle
      base = base * 0.995 + val * 0.005;

      // Lissage + pente
      final currentMA = _updateMA(val);
      final slope = currentMA - _maLagged;

      final now = DateTime.now();
      final dtMs = now.difference(_phaseStart).inMilliseconds;

      // Application du laxisme
      final k = _leniencyScale();
      final gDown = downGate * k;
      final gUp = upGate * k;
      final aThresh = ampThresh * k;
      final sEps = slopeEps * k;

      // Réfractaire ajusté et timeout de phase ajusté
      final refracMs = (refractory.inMilliseconds * (0.5 + 0.5 * k)).round();
      final refractoryNow = Duration(milliseconds: refracMs);
      final maxPhaseNow = (maxPhaseMs * (1.0 + (1.0 - k))).round();

      // Comptage des streaks de pente
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

      // Machine à états
      switch (_phase) {
        case Phase.idle:
        // Début de descente si on passe sous le seuil bas
          if ((currentMA - base) < gDown && _downStreak >= _needStreak) {
            _phase = Phase.descent;
            _phaseStart = now;
            minInDescent = currentMA;
            _downStreak = 0;
          }
          break;

        case Phase.descent:
        // Suivi du minimum pendant la descente
          if (currentMA < minInDescent) minInDescent = currentMA;

          // Passage en bas lorsque la pente s’inverse (streak up)
          if (_upStreak >= _needStreak) {
            _phase = Phase.bottom;
            _phaseStart = now;
            _bottomAt = now;
            _upStreak = 0;
          }

          // Sécurité: on annule si la phase dure trop longtemps
          if (dtMs > maxPhaseNow) _resetToIdle(now);
          break;

        case Phase.bottom:
        // Petite tenue en bas + départ de montée au-dessus du seuil haut
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
        // Suivi du maximum pendant la montée
          if (currentMA > maxInAscent) maxInAscent = currentMA;

          // Fin de montée: soit pente qui repasse à la baisse, soit retour sous moitié du seuil haut
          final ascentDone =
              _downStreak >= _needStreak || (currentMA - base) < (gUp * 0.5);

          if (ascentDone) {
            // Amplitude du cycle courant
            final amp = (maxInAscent - minInDescent).abs();

            // Seuil "soft" plus indulgent au démarrage
            final softRatio = (k < 1.0) ? 0.40 : 0.60;
            final reachedMain = amp >= aThresh;
            final reachedSoft = amp >= aThresh * softRatio;

            // Anti-double comptage
            final refractoryOk = now.difference(_lastRep) >= refractoryNow;

            // Validation de la rep
            if ((reachedMain || reachedSoft) && refractoryOk) {
              _lastRep = now;
              setState(() => currentReps++);

              // Adaptation de l’amplitude de référence et de la base
              final target = math.max(ampThresh * 0.85, amp);
              ampThresh = 0.6 * ampThresh + 0.4 * target;
              base = base * 0.9 + ((minInDescent + maxInAscent) / 2.0) * 0.1;

              // Fin de série
              if (currentReps >= plan.repsPerSet) {
                _onSetFinished();
                return;
              }
            }
            // Retour à l’état idle pour un nouveau cycle
            _resetToIdle(now);
          }
          if (dtMs > maxPhaseNow) _resetToIdle(now);
          break;
      }

      // Rafraîchit l’UI (affichage debug, compteurs)
      setState(() {});
    });
  }

  // Remise à zéro de la FSM et des marqueurs entre cycles
  void _resetToIdle(DateTime now) {
    _phase = Phase.idle;
    _phaseStart = now;
    minInDescent = 0;
    maxInAscent = 0;
    _downStreak = 0;
    _upStreak = 0;
  }

  // Fin d’une série: soit fin de séance, soit démarrage du repos
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

  // Lance le repos entre deux séries
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
    // Remarque: pour que le contenu "passe sous" la carte découpée,
    // préférer une mise en page en Stack (ListView en fond, carte au-dessus).
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Carte d’exercice (forme personnalisée via ClipPath)
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: ExerciseCard(
                title: "NATH A FOND",
                bestTime: null,
                time: null,
                repetitions: currentReps,
                series: currentSet,
                totalRepetitions: plan.repsPerSet,
                totalSeries: plan.sets,
                repos: restRemaining, // si le widget l’affiche
                leftImage: "assets/images/guepard.png",
                rightImage: "assets/images/mesange.png",
              ),
            ),

            // Contenu défilant de la page
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
                          size: 120, color: Colors.grey),
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
                  ],
                ),
              ),
            ),

            // Barre d’actions en bas
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
