import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/traction.dart';
import '../services/traction_sensor_service.dart';
import '../widgets/tjtq_circle_button.dart';
import '../widgets/tjtq_card.dart';
import '../widgets/tjtq_congrats_popup.dart';

/// Machine à états:
/// idle -> descent -> bottom -> ascent -> rep validée
enum Phase { idle, descent, bottom, ascent }

/// Page de suivi des tractions.
/// - Reçoit un [TractionPlan] depuis l'appelant (ex: main.dart).
/// - Lit un flux capteur via [SensorService] et détecte les répétitions.
/// - Gère la progression séries/reps, les temps de repos et des annonces vocales TTS.
/// - Présente une carte visuelle (ExerciseCard) et un contenu défilant en arrière-plan.
class TractionPage extends StatefulWidget {
  final TractionPlan plan;

  const TractionPage({super.key, required this.plan});

  @override
  State<TractionPage> createState() => _TractionPageState();
}

class _TractionPageState extends State<TractionPage> {
  // -----------------------
  // Configuration / Plan
  // -----------------------

  /// Plan de la séance fourni par le parent.
  late TractionPlan plan;

  // -----------------------
  // Etat de séance
  // -----------------------

  int currentSet = 1;        // Série en cours (1-based)
  int currentReps = 0;       // Répétitions validées dans la série courante
  bool inRest = false;       // Indique si on est dans un intervalle de repos
  int restRemaining = 0;     // Compte à rebours de repos (secondes)
  bool isTractionRunning = false;

  // -----------------------
  // Capteurs / Signal
  // -----------------------

  /// Service capteur: vertical projeté + lissages internes.
  final _sensor = SensorService(alphaGravity: 0.96, alphaSmooth: 0.90);

  /// Abonnement au flux capteur.
  StreamSubscription<double>? _sub;

  /// Dernière valeur (utile en debug).
  double val = 0.0;

  // -----------------------
  // FSM (détection de cycles)
  // -----------------------

  Phase _phase = Phase.idle;
  DateTime _phaseStart = DateTime.now();      // Début de la phase courante
  DateTime _tractionStarted = DateTime.now(); // Début de la séance (pour le laxisme)

  // Seuils adaptatifs
  double base = 0.0;      // Ligne de base glissante
  double ampThresh = 0.6; // Amplitude minimale pour valider une rep
  double slopeEps = 0.03; // Pente minimale pour compter une tendance
  double downGate = -0.2; // Seuil directionnel pour déclencher la descente
  double upGate = 0.2;    // Seuil directionnel pour déclencher la montée

  // Mémoire du cycle courant
  double minInDescent = 0.0; // Minimum observé en descente
  double maxInAscent = 0.0;  // Maximum observé en montée

  // Garde-fous anti-doublons
  static const minBottomHold = Duration(milliseconds: 50); // Tenue minimale en bas
  static const refractory = Duration(milliseconds: 500);   // Fenêtre réfractaire après rep
  static const maxPhaseMs = 2500;                          // Timeout de phase
  DateTime _bottomAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastRep = DateTime.fromMillisecondsSinceEpoch(0);

  // -----------------------
  // Lissage (moyenne glissante) et pente
  // -----------------------

  final int _maLen = 3;    // Taille de fenêtre MA
  final int _slopeLag = 1; // Décalage pour approximer la pente
  final List<double> _buf = <double>[];
  double _ma = 0.0;
  double _maLagged = 0.0;

  // Streaks de pente (filtrage oscillations)
  int _downStreak = 0;
  int _upStreak = 0;
  int _needStreak = 1; // Nombre minimal d'échantillons consécutifs dans une direction

  // -----------------------
  // Repos (timer)
  // -----------------------

  Timer? _restTimer;

  // -----------------------
  // Text-to-Speech (TTS)
  // -----------------------

  final FlutterTts _tts = FlutterTts();
  bool _ttsBusy = false;

  // -----------------------
  // Cycle de vie
  // -----------------------

  @override
  void initState() {
    super.initState();
    plan = widget.plan;
    _initTts();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _restTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  // -----------------------
  // Initialisation TTS
  // -----------------------

  Future<void> _initTts() async {
    await _tts.setLanguage("fr-FR");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    // Évite chevauchements
    try {
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
    }
  }

  Future<void> _speak(String text) async {
    if (_ttsBusy) return;
    _ttsBusy = true;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } finally {
      _ttsBusy = false;
    }
  }

  // -----------------------
  // Calibration capteur
  // -----------------------

  /// Échantillonne brièvement à l'arrêt pour estimer:
  /// - base (ligne de base),
  /// - seuils directionnels (downGate/upGate),
  /// - amplitude cible (ampThresh),
  /// en fonction du bruit mesuré (sigma).
  Future<void> _calibrate() async {
    final samples = <double>[];
    final sub = _sensor.verticalStream().listen(samples.add);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await sub.cancel();
    if (samples.isEmpty) return;

    final mu = samples.reduce((a, b) => a + b) / samples.length;
    final varSum = samples.fold<double>(0.0, (s, v) => s + (v - mu) * (v - mu));
    final sigma = math.sqrt(varSum / samples.length);

    base = mu;
    final gate = math.max(0.15, sigma * 1.2);
    downGate = -gate;
    upGate = gate;
    ampThresh = math.max(0.40, sigma * 1.2);
    slopeEps = math.max(0.02, sigma * 0.25);
    _needStreak = 1;
  }

  // -----------------------
  // Laxisme progressif (assouplissement des seuils au démarrage)
  // -----------------------

  /// Retourne un facteur k dans [0.5; 1.0] appliqué aux seuils pour faciliter
  /// les premières répétitions et éviter une rep "perdue" au début.
  double _leniencyScale() {
    final since = DateTime.now().difference(_tractionStarted);
    if (since < const Duration(seconds: 25) && currentReps < 2) return 0.5;
    if (since < const Duration(seconds: 45) && currentReps < 4) return 0.75;
    return 1.0;
  }

  // -----------------------
  // Contrôles de séance
  // -----------------------

  /// Démarre une séance:
  /// - réinitialise les compteurs,
  /// - calibre,
  /// - lance l'écoute capteur.
  Future<void> _startTraction() async {
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
    _speak("Séance démarrée.");
    _startSensor();
  }

  /// Arrête la séance et remet l'état à zéro.
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
    _speak("Séance arrêtée.");
  }

  // -----------------------
  // Lissage et pente (MA + moyenne décalée)
  // -----------------------

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

  // -----------------------
  // Ecoute capteur et FSM
  // -----------------------

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
      if (inRest) return; // Ignore pendant le repos
      val = vRaw;

      // Mise à jour lente de la base
      base = base * 0.995 + val * 0.005;

      // Lissage et pente
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

      // Fenêtre réfractaire et timeout de phase ajustés au laxisme
      final refracMs = (refractory.inMilliseconds * (0.5 + 0.5 * k)).round();
      final refractoryNow = Duration(milliseconds: refracMs);
      final maxPhaseNow = (maxPhaseMs * (1.0 + (1.0 - k))).round();

      // Streaks de pente
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
        // Début de descente si passage sous le seuil bas
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

          // Passage en bas: inversion de pente (streak up)
          if (_upStreak >= _needStreak) {
            _phase = Phase.bottom;
            _phaseStart = now;
            _bottomAt = now;
            _upStreak = 0;
          }

          // Sécurité: annule si la phase dure trop longtemps
          if (dtMs > maxPhaseNow) _resetToIdle(now);
          break;

        case Phase.bottom:
        // Tenue minimale en bas + départ de montée au-dessus du seuil haut
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

          // Fin de montée:
          // - pente qui repasse à la baisse, ou
          // - retour sous la moitié du seuil haut
          final ascentDone =
              _downStreak >= _needStreak || (currentMA - base) < (gUp * 0.5);

          if (ascentDone) {
            // Amplitude observée sur le cycle courant
            final amp = (maxInAscent - minInDescent).abs();

            // Seuil "soft" plus indulgent si k < 1.0
            final softRatio = (k < 1.0) ? 0.40 : 0.60;
            final reachedMain = amp >= aThresh;
            final reachedSoft = amp >= aThresh * softRatio;

            // Anti double-comptage via fenêtre réfractaire
            final refractoryOk = now.difference(_lastRep) >= refractoryNow;

            // Validation de la répétition
            if ((reachedMain || reachedSoft) && refractoryOk) {
              _lastRep = now;
              setState(() => currentReps++);

              // Adaptation de l'amplitude de référence et de la base
              final target = math.max(ampThresh * 0.85, amp);
              ampThresh = 0.6 * ampThresh + 0.4 * target;
              base = base * 0.9 + ((minInDescent + maxInAscent) / 2.0) * 0.1;

              // Fin de série si quota atteint
              if (currentReps >= plan.repsPerSet) {
                _onSetFinished();
                return;
              }
            }

            // Nouveau cycle
            _resetToIdle(now);
          }

          if (dtMs > maxPhaseNow) _resetToIdle(now);
          break;
      }

      // Rafraîchit l'UI (compteurs)
      setState(() {});
    });
  }

  /// Remise à zéro de la FSM et des marqueurs de cycle.
  void _resetToIdle(DateTime now) {
    _phase = Phase.idle;
    _phaseStart = now;
    minInDescent = 0;
    maxInAscent = 0;
    _downStreak = 0;
    _upStreak = 0;
  }

  /// Fin de série:
  /// - si dernière série: affiche le popup et annonce la fin de séance,
  /// - sinon: lance le repos et annonce sa durée.
  void _onSetFinished() {
    _sub?.cancel();
    if (currentSet >= plan.sets) {
      _speak("Séance terminée. Bravo !");
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        backgroundColor: Colors.transparent,
        builder: (_) => CongratsPopup(
          title: "GOOD JOB!",
          stars: 5,
          buttonText: "team VICO",
          onClose: () {
            Navigator.pop(context);
            _stopTraction();
          },
        ),
      );
    } else {
      _speak("Série $currentSet terminée. Repos de ${plan.restSeconds} secondes.");
      _startRest();
    }
  }

  /// Démarre le repos entre deux séries avec un compte à rebours.
  /// Annonce les 3 dernières secondes puis la reprise.
  void _startRest() {
    setState(() {
      inRest = true;
      restRemaining = plan.restSeconds;
    });
    _sub?.cancel();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => restRemaining--);

      // Annonce des 3 dernières secondes
      if (restRemaining == 3 || restRemaining == 2 || restRemaining == 1) {
        _speak("$restRemaining");
      }

      if (restRemaining <= 0) {
        t.cancel();
        setState(() {
          inRest = false;
          currentSet++;
          currentReps = 0;
          _phase = Phase.idle;
          _phaseStart = DateTime.now();
        });
        _speak("Reprise. Série $currentSet.");
        _startSensor();
      }
    });
  }

  // -----------------------
  // UI
  // -----------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 1) Contenu de fond
            Positioned.fill(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20)
                    .copyWith(top: 320, bottom: 120), // Laisse la place carte et au footer
                children: [
                  Text(
                    "TRACTIONS x${plan.repsPerSet}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    child: Icon(Icons.fitness_center, size: 120, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Muscles sollicités",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Dos, biceps, abdominaux",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // 2) Carte d'exercice au-dessus
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: ExerciseCard(
                title: "NATH A FOND",
                bestTime: null,
                time: null,
                repetitions: currentReps,
                series: currentSet,
                totalRepetitions: plan.repsPerSet,
                totalSeries: plan.sets,
                repos: restRemaining,
                leftImage: "assets/images/guepard.png",
                rightImage: "assets/images/mesange.png",
              ),
            ),

            // 3) Barre d’actions en bas
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }
}
