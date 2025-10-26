import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';

import '../models/traction.dart';
import '../models/exercise.dart';
import '../repositories/exercice_repository.dart';
import '../services/traction_sensor_service.dart';
import '../widgets/tjtq_circle_button.dart';
import '../widgets/tjtq_card.dart';
import '../widgets/tjtq_congrats_popup.dart';

/// Machine à états:
/// idle -> descent -> bottom -> ascent -> rep validée
enum Phase { idle, descent, bottom, ascent }

/// Page de suivi des tractions.
/// - Lit le plan Traction (series/reps/repos) dans assets/entrainement.json
///   -> pas de repo traction_plans, pas de SQLite
/// - Récupère aussi l'Exercise "Traction" passé via Navigator pour pouvoir le marquer done.
/// - Lit le flux capteur via SensorService pour compter les reps.
/// - Gère séries, repos, annonces TTS, popup "GOOD JOB!" à la fin.
class TractionPage extends StatefulWidget {
  const TractionPage({super.key});

  @override
  State<TractionPage> createState() => _TractionPageState();
}

class _TractionPageState extends State<TractionPage> {
  // -----------------------
  // Config / plan
  // -----------------------

  /// Repo global des exercices pour pouvoir setDone(ex.id, true)
  final _exerciseRepo = ExerciseRepository();

  /// Plan de traction lu depuis le JSON (sets/reps/restSeconds)
  TractionPlan? plan;

  /// Pendant qu'on charge le JSON au début
  bool _loadingPlan = true;

  /// L'exercice "Traction" qu'on a passé via Navigator
  /// (sert juste à marquer done en base quand terminé)
  Exercise? exercise;

  // -----------------------
  // Etat de séance
  // -----------------------

  int currentSet = 1;        // Série en cours (1-based)
  int currentReps = 0;       // Répétitions validées dans la série courante
  bool inRest = false;       // Est-ce qu'on est en repos entre deux séries
  int restRemaining = 0;     // Compte à rebours du repos (en secondes)
  bool isTractionRunning = false;

  // -----------------------
  // Capteurs / Signal
  // -----------------------

  /// Service capteur: vertical projeté + lissages internes.
  final _sensor = SensorService(alphaGravity: 0.96, alphaSmooth: 0.90);

  /// Abonnement au flux capteur.
  StreamSubscription<double>? _sub;

  /// Dernière valeur brute (debug)
  double val = 0.0;

  // -----------------------
  // FSM (détection de cycles)
  // -----------------------

  Phase _phase = Phase.idle;
  DateTime _phaseStart = DateTime.now();      // Début de la phase courante
  DateTime _tractionStarted = DateTime.now(); // Début de la séance (pour le laxisme)

  // Seuils adaptatifs
  double base = 0.0;        // Ligne de base glissante
  double ampThresh = 0.6;   // Amplitude mini pour valider une rep
  double slopeEps = 0.03;   // Pente mini pour compter une tendance
  double downGate = -0.2;   // Seuil directionnel descente
  double upGate = 0.2;      // Seuil directionnel montée

  // Mémoire du cycle courant
  double minInDescent = 0.0; // Min observé en descente
  double maxInAscent = 0.0;  // Max observé en montée

  // Anti-doublons
  static const minBottomHold = Duration(milliseconds: 50); // hold bas mini
  static const refractory    = Duration(milliseconds: 500); // anti double rep
  static const maxPhaseMs    = 2500; // timeout de phase
  DateTime _bottomAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastRep  = DateTime.fromMillisecondsSinceEpoch(0);

  // -----------------------
  // Lissage / pente
  // -----------------------

  final int _maLen = 3;    // taille fenêtre moving average
  final int _slopeLag = 1; // décalage pour approximer la pente
  final List<double> _buf = <double>[];
  double _ma = 0.0;
  double _maLagged = 0.0;

  // streak direction (pour filtrer les mini oscillations)
  int _downStreak = 0;
  int _upStreak = 0;
  int _needStreak = 1;

  // -----------------------
  // Repos
  // -----------------------

  Timer? _restTimer;

  // -----------------------
  // TTS
  // -----------------------

  final FlutterTts _tts = FlutterTts();
  bool _ttsBusy = false;

  // -----------------------
  // Cycle de vie
  // -----------------------

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// 1. lit le plan Traction dans assets/entrainement.json
  /// 2. init le TTS
  /// 3. enlève le loader
  Future<void> _bootstrap() async {
    TractionPlan? parsedPlan;

    try {
      // lis le JSON des exos
      final raw = await rootBundle.loadString('entrainement.json');
      final Map<String, dynamic> root = json.decode(raw) as Map<String, dynamic>;
      final exercices = root['exercice'];

      if (exercices is List) {
        // on cherche l'objet dont name == "Traction"
        final tractionEntry = exercices.firstWhere(
          (e) => e is Map<String, dynamic> && e['name'] == 'Traction',
          orElse: () => null,
        );

        if (tractionEntry is Map<String, dynamic>) {
          int? toInt(dynamic v) {
            if (v == null) return null;
            if (v is int) return v;
            if (v is double) return v.round();
            if (v is String && v.trim().isNotEmpty) return int.tryParse(v);
            return null;
          }

          final sets        = toInt(tractionEntry['steps']) ?? 0; // exemple: 3
          final repsPerSet  = toInt(tractionEntry['reps']) ?? 0;  // exemple: 15
          final restSeconds = toInt(tractionEntry['rest']) ?? 0;  // exemple: "60"

          parsedPlan = TractionPlan(
            id: null,
            sets: sets,
            repsPerSet: repsPerSet,
            restSeconds: restSeconds,
          );
        }
      }
    } catch (e, st) {
      debugPrint('[TRACTION] erreur lecture entrainement.json: $e');
      debugPrint('[TRACTION] stack: $st');
      parsedPlan = null;
    }

    plan = parsedPlan;

    await _initTts();

    if (!mounted) return;
    setState(() {
      _loadingPlan = false;
    });
  }

  /// comme YogaPage : on chope l'Exercise (Traction) passé via Navigator
  /// pour setDone(ex.id, true) à la fin
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (exercise == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Exercise) {
        exercise = args;
      } else {
        debugPrint('Aucun Exercise passé à TractionPage');
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _restTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  // -----------------------
  // TTS utils
  // -----------------------

  Future<void> _initTts() async {
    await _tts.setLanguage("fr-FR");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    try {
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      // certains devices crashent sinon, donc on ignore
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

  /// On prend ~800ms d'échantillons quand t'es accroché à la barre sans bouger
  /// pour estimer:
  /// - base
  /// - seuil descente/montée
  /// - amplitude min
  /// -> ça rend la détection plus stable
  Future<void> _calibrate() async {
    final samples = <double>[];
    final sub = _sensor.verticalStream().listen(samples.add);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await sub.cancel();
    if (samples.isEmpty) return;

    final mu = samples.reduce((a, b) => a + b) / samples.length;
    final varSum = samples.fold<double>(
      0.0,
      (s, v) => s + (v - mu) * (v - mu),
    );
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
  // Laxisme (début de séance + premières reps)
  // -----------------------

  /// plus t'es tôt dans la séance, plus on assouplit les seuils
  /// => évite de "perdre" les 1ères reps
  double _leniencyScale() {
    final since = DateTime.now().difference(_tractionStarted);
    if (since < const Duration(seconds: 25) && currentReps < 2) return 0.5;
    if (since < const Duration(seconds: 45) && currentReps < 4) return 0.75;
    return 1.0;
  }

  // -----------------------
  // Contrôle séance
  // -----------------------

  Future<void> _startTraction() async {
    // sécurité: pas de plan => pas de start
    if (plan == null) return;

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
  // Lissage + pente
  // -----------------------

  double _updateMA(double v) {
    _buf.add(v);
    if (_buf.length > _maLen) _buf.removeAt(0);
    _ma = _buf.fold<double>(0.0, (s, x) => s + x) / _buf.length;

    if (_buf.length >= _slopeLag) {
      final int idx = _buf.length - _slopeLag;
      final slice = _buf.sublist(0, idx);
      _maLagged =
          slice.isEmpty
              ? _ma
              : slice.fold<double>(0.0, (s, x) => s + x) / slice.length;
    } else {
      _maLagged = _ma;
    }
    return _ma;
  }

  // -----------------------
  // FSM capteur
  // -----------------------

  void _startSensor() {
    _sub?.cancel();

    // reset FSM
    _phase = Phase.idle;
    _phaseStart = DateTime.now();
    minInDescent = 0;
    maxInAscent = 0;
    _buf.clear();
    _downStreak = 0;
    _upStreak = 0;

    _sub = _sensor.verticalStream().listen((vRaw) {
      if (inRest) return; // on ignore le flux si repos
      val = vRaw;

      // base se décale lentement
      base = base * 0.995 + val * 0.005;

      // lissage + pente
      final currentMA = _updateMA(val);
      final slope = currentMA - _maLagged;

      final now = DateTime.now();
      final dtMs = now.difference(_phaseStart).inMilliseconds;

      // laxisme
      final k = _leniencyScale();
      final gDown = downGate * k;
      final gUp = upGate * k;
      final aThresh = ampThresh * k;
      final sEps = slopeEps * k;

      // durées dynamiques
      final refracMs = (refractory.inMilliseconds * (0.5 + 0.5 * k)).round();
      final refractoryNow = Duration(milliseconds: refracMs);
      final maxPhaseNow = (maxPhaseMs * (1.0 + (1.0 - k))).round();

      // streak direction
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

      // FSM
      switch (_phase) {
        case Phase.idle:
          // début descente ?
          if ((currentMA - base) < gDown && _downStreak >= _needStreak) {
            _phase = Phase.descent;
            _phaseStart = now;
            minInDescent = currentMA;
            _downStreak = 0;
          }
          break;

        case Phase.descent:
          // track min
          if (currentMA < minInDescent) minInDescent = currentMA;

          // bottom ?
          if (_upStreak >= _needStreak) {
            _phase = Phase.bottom;
            _phaseStart = now;
            _bottomAt = now;
            _upStreak = 0;
          }

          // timeout
          if (dtMs > maxPhaseNow) _resetToIdle(now);
          break;

        case Phase.bottom:
          // montée ?
          if (now.difference(_bottomAt) >= minBottomHold &&
              (currentMA - base) > gUp &&
              _upStreak >= _needStreak) {
            _phase = Phase.ascent;
            _phaseStart = now;
            maxInAscent = currentMA;
            _upStreak = 0;
          }

          // timeout
          if (dtMs > maxPhaseNow) _resetToIdle(now);
          break;

        case Phase.ascent:
          // track max
          if (currentMA > maxInAscent) maxInAscent = currentMA;

          // fin montée ?
          final ascentDone =
              _downStreak >= _needStreak ||
              (currentMA - base) < (gUp * 0.5);

          if (ascentDone) {
            // amplitude du mouvement
            final amp = (maxInAscent - minInDescent).abs();

            // tolérance douce pour début de séance
            final softRatio = (k < 1.0) ? 0.40 : 0.60;
            final reachedMain = amp >= aThresh;
            final reachedSoft = amp >= aThresh * softRatio;

            // anti double comptage
            final refractoryOk =
                now.difference(_lastRep) >= refractoryNow;

            // rep validée ?
            if ((reachedMain || reachedSoft) && refractoryOk) {
              _lastRep = now;
              setState(() => currentReps++);

              // on update nos seuils à partir de ce qu'on a vu
              final target = math.max(ampThresh * 0.85, amp);
              ampThresh = 0.6 * ampThresh + 0.4 * target;
              base = base * 0.9 +
                  ((minInDescent + maxInAscent) / 2.0) * 0.1;

              // série finie ?
              if (plan != null &&
                  currentReps >= plan!.repsPerSet) {
                _onSetFinished();
                return;
              }
            }

            // nouveau cycle
            _resetToIdle(now);
          }

          // timeout
          if (dtMs > maxPhaseNow) _resetToIdle(now);
          break;
      }

      // rafraîchir l'UI
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

  /// Fin de série:
  /// - si dernière série => popup GOOD JOB + on marque l'exo comme fait
  /// - sinon => repos
  void _onSetFinished() {
    _sub?.cancel();
    if (plan == null) return;

    if (currentSet >= plan!.sets) {
      // toutes les séries faites -> fin séance
      _speak("Séance terminée. Bravo !");

      final ex = exercise;
      if (ex != null) {
        _exerciseRepo.setDone(ex.id, true); // comme Yoga
      } else {
        debugPrint("Impossible de marquer Traction comme faite: exercise == null");
      }

      showModalBottomSheet(
        context: context,
        isDismissible: false,
        backgroundColor: Colors.transparent,
        builder: (_) => CongratsPopup(
          title: "GOOD JOB!",
          stars: 5,
          buttonText: "TJTQ",
          onClose: () {
            Navigator.pop(context); // ferme le bottom sheet
            _stopTraction();
            Navigator.pop(context, true); // retourne au programme
          },
        ),
      );
    } else {
      // on a encore des séries
      _speak("Série $currentSet terminée. Repos de ${plan!.restSeconds} secondes.");
      _startRest();
    }
  }

  /// repos entre deux séries
  void _startRest() {
    if (plan == null) return;

    setState(() {
      inRest = true;
      restRemaining = plan!.restSeconds;
    });
    _sub?.cancel();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => restRemaining--);

      // annonce vocale 3,2,1
      if (restRemaining == 3 ||
          restRemaining == 2 ||
          restRemaining == 1) {
        _speak("$restRemaining");
      }

      // fin du repos
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
    // état 1 : on charge encore le plan du JSON
    if (_loadingPlan) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // état 2 : chargement fini mais pas de plan trouvé dans le JSON
    if (plan == null) {
      debugPrint("[TRACTION] plan est null après lecture du JSON");
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "Aucun plan de tractions configuré.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Ajoute 'Traction' dans assets/entrainement.json "
                    "avec reps / steps / rest.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // retour au programme
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Retour"),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // état 3 : on a un plan => UI normale d'entraînement
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // fond scrollable (explication exercice)
            Positioned.fill(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20)
                    .copyWith(top: 320, bottom: 120),
                children: [
                  Text(
                    "TRACTIONS x${plan!.repsPerSet}",
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
                  const Center(
                    child: Icon(
                      Icons.fitness_center,
                      size: 120,
                      color: Colors.grey,
                    ),
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

            // carte stats séries/reps/repos
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
                totalRepetitions: plan!.repsPerSet,
                totalSeries: plan!.sets,
                repos: restRemaining,
                leftImage: "assets/images/guepard.png",
                rightImage: "assets/images/mesange.png",
              ),
            ),

            // barre d'actions en bas
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
