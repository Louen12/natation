import 'dart:math';

import 'package:flutter/material.dart';
import 'package:natation/services/jump_metrics.dart';
import 'package:natation/services/jump_service.dart';
import 'package:provider/provider.dart';
import '../widgets/ExerciseCard.dart';
import '../widgets/draggable_nav_bar.dart';
import '../services/tts_service.dart';

class JumpExercisePage extends StatefulWidget {
  const JumpExercisePage({super.key});

  @override
  State<JumpExercisePage> createState() => _JumpExercisePageState();
}

class _JumpExercisePageState extends State<JumpExercisePage> {
  final TTSService _ttsService = TTSService();
  final GlobalKey<ExerciseCardState> _cardKey = GlobalKey<ExerciseCardState>();

  final String _exerciseText =
      "Pour cette séance, nous allons faire des SAUTS VERTICAUX. "
      "Sautez aussi haut que possible ! L'application détectera la hauteur, "
      "la puissance et estimera les calories brûlées.";

  bool _isSpeaking = false;
  bool _showLeo = false;
  bool _isPlaying = false;
  bool _showInstructions = true;
  bool _isStopped = false;

  int _jumpCount = 0;
  double _totalHeight = 0;
  double _totalCalories = 0;
  double _maxHeight = 0;
  double _totalPower = 0;
  DateTime? _sessionStartTime;
  Duration _totalSessionTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _ttsService.setOnStateChanged(_updateSpeakingState);
  }

  void _updateSpeakingState() {
    setState(() {
      _isSpeaking = _ttsService.isSpeaking;
    });
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      _showInstructions = !_isPlaying;
      _isStopped = false; // Réinitialiser l'état d'arrêt
    });

    if (_isPlaying) {
      _startExercise();
      _cardKey.currentState?.startTimer();
    } else {
      // En pause, arrêter tout
      _ttsService.stop();
      _cardKey.currentState?.stopTimer();
    }
  }

  void _startExercise() {
    if (_sessionStartTime == null) {
      _sessionStartTime = DateTime.now();
      // Message de début
      _ttsService.speak("C'est parti ! Commencez vos sauts verticaux !");
    }
  }

  void _stopExercise() {
    // Arrêter tout
    _ttsService.stop();

    // Arrêter le timer de l'ExerciseCard
    _cardKey.currentState?.stopTimer();

    // Calculer le temps total au moment de l'arrêt
    if (_sessionStartTime != null) {
      _totalSessionTime = DateTime.now().difference(_sessionStartTime!);
    }

    // Mettre à jour l'état
    setState(() {
      _isPlaying = false;
      _showInstructions = true;
      _showLeo = false; // Cacher Gros Léo
      _isStopped = true; // Marquer comme arrêté
    });

    _showResults();
  }

  void _showResults() {
    final totalMinutes = _totalSessionTime.inMinutes;
    final totalSeconds = _totalSessionTime.inSeconds % 60;
    final formattedTotalTime = '${totalMinutes.toString().padLeft(2, '0')}:${totalSeconds.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Résultats de l\'exercice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResultRow('Nombre de sauts', '$_jumpCount'),
              _buildResultRow('Hauteur totale', '${_totalHeight.toStringAsFixed(1)} cm'),
              _buildResultRow('Calories brûlées', '${_totalCalories.toStringAsFixed(1)} kcal'),
              _buildResultRow('Hauteur max', '${_maxHeight.toStringAsFixed(1)} cm'),
              _buildResultRow('Puissance moyenne', '${_totalPower.toStringAsFixed(2)} g'),
              _buildResultRow('Temps total', formattedTotalTime),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _reloadExercise();
              },
              child: const Text('Reload Exercise'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getBestTime() {
    if (_totalSessionTime.inSeconds > 0) {
      final minutes = _totalSessionTime.inMinutes;
      final seconds = _totalSessionTime.inSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return "00:00";
  }

  void _reloadExercise() {
    _ttsService.stop(); // Arrêter le TTS

    // Réinitialiser le timer de l'ExerciseCard
    _cardKey.currentState?.resetTimer();

    setState(() {
      _jumpCount = 0;
      _totalHeight = 0;
      _totalCalories = 0;
      _maxHeight = 0;
      _totalPower = 0;
      _isPlaying = false;
      _showInstructions = true;
      _showLeo = false;
      _isStopped = false; // Réinitialiser l'état d'arrêt
      _sessionStartTime = null;
      _totalSessionTime = Duration.zero;
    });
  }

  void _onJumpDetected(double height, double calories, double power) {
    setState(() {
      _jumpCount++;
      _totalHeight += height;
      _totalCalories += calories;
      _totalPower += power;
      if (height > _maxHeight) _maxHeight = height;
    });

    // Text-to-speech selon le nombre de sauts
    _speakMotivation();

    // Démarrer le timer pour Gros Léo après 3 sauts
    if (_jumpCount >= 3) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showLeo = true;
          });
          // Gros Léo parle
          _ttsService.speak("Gros Léo est fier de toi ! Continue comme ça !");
        }
      });
    }
  }

  void _speakMotivation() {
    if (_jumpCount <= 2) {
      _ttsService.speak("C'est mou ! Allez, saute plus haut ! Tu veux maigrir ou pas ? Tu veux rester comme Choji à vie ?!");
    } else if (_jumpCount <= 5) {
      _ttsService.speak("Ça va mieux ! Continue à sauter ! Tu veux maigrir ou pas ? Tu veux rester comme Choji à vie ?!");
    } else if (_jumpCount <= 8) {
      _ttsService.speak("Excellent ! Tu es sur la bonne voie !");
    } else {
      _ttsService.speak("Presque fini ! Tu es formidable !");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => JumpService(massKg: 72)..start(),
        child: _JumpView(
          cardKey: _cardKey,
          isPlaying: _isPlaying,
          showInstructions: _showInstructions,
          showLeo: _showLeo,
          isStopped: _isStopped,
          jumpCount: _jumpCount,
          onJumpDetected: _onJumpDetected,
          onPlayPause: _togglePlayPause,
          onStop: _stopExercise,
          onSpeak: () async {
            await _ttsService.speak(_exerciseText);
            _updateSpeakingState();
          },
          onStopSpeak: () async {
            await _ttsService.stop();
            _updateSpeakingState();
          },
          isSpeaking: _isSpeaking,
          bestTime: _getBestTime(),
        ),
      ),
    );
  }
}

class _JumpView extends StatelessWidget {
  final GlobalKey<ExerciseCardState> cardKey;
  final bool isPlaying;
  final bool showInstructions;
  final bool showLeo;
  final bool isStopped;
  final int jumpCount;
  final Function(double height, double calories, double power)? onJumpDetected;
  final VoidCallback? onPlayPause;
  final VoidCallback? onStop;
  final VoidCallback? onSpeak;
  final VoidCallback? onStopSpeak;
  final bool isSpeaking;
  final String bestTime;

  const _JumpView({
    required this.cardKey,
    required this.isPlaying,
    required this.showInstructions,
    required this.showLeo,
    required this.isStopped,
    required this.jumpCount,
    this.onJumpDetected,
    this.onPlayPause,
    this.onStop,
    this.onSpeak,
    this.onStopSpeak,
    required this.isSpeaking,
    required this.bestTime,
  });

  String _m(double v) => '${v.toStringAsFixed(2)} m';

  String _k(double v) => '${v.toStringAsFixed(2)} kcal';

  @override
  Widget build(BuildContext context) {
    final service = context.watch<JumpService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/julcik.png", fit: BoxFit.cover),
          Container(
            color: const Color.fromARGB(120, 0, 0, 0),
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ExerciseCard(
                  key: cardKey,
                  title: "NATH A FOND",
                  bestTime: bestTime,
                  repetitions: jumpCount,
                  leftImage: "assets/images/fast-cheetah.png",
                  rightImage: "assets/images/bird.png",
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  child: showInstructions
                      ? _buildInstructionBlock()
                      : _buildExerciseVisual(service),
                ),
              ],
            ),
          ),

          // DraggableNavBar
          DraggableNavBar(
            isPlaying: isPlaying,
            exerciseTitle: "Exercice de Saut",
            onPlayPause: onPlayPause ?? () {},
            onStop: onStop ?? () {},
            onNext: () {
              // TODO: Implémenter la navigation
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionBlock() {
    return Container(
      key: const ValueKey('instructions'),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Text(
            "EXERCICE DE SAUTS",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'DynaPuff',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Prépare-toi à sauter aussi haut que possible !\n"
            "L'application détectera la hauteur du saut, la puissance et estimera les calories brûlées.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: isSpeaking
                    ? null
                    : onSpeak,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Écouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6200),
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: isSpeaking
                    ? onStopSpeak
                    : null,
                icon: const Icon(Icons.stop),
                label: const Text('Arrêter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseVisual(JumpService service) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: showLeo
          ? Column(
              key: const ValueKey('leoBlock'),
              children: [
                const Text(
                  "Gros Léo est fier de toi !",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'DynaPuff',
                  ),
                ),
                Container(
                  height: 250,
                  child: Image.asset(
                    "assets/images/leo.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            )
          : Stack(
              key: const ValueKey('exerciseBlock'),
              children: [
                // Image de motivation en arrière-plan
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "C'EST MOU ALLEZ !",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DynaPuff',
                        ),
                      ),
                      Container(
                        height: 250,
                        child: Image.asset(
                          "assets/images/gros.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats en overlay - seulement si pas arrêté
                if (!isStopped)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: StreamBuilder<JumpEvent>(
                        stream: service.events,
                        builder: (_, snap) {
                          final hasData = snap.hasData;
                          final evt = snap.data;
                          double height = 0;
                          double calories = 0;
                          double power = 0;

                          if (hasData) {
                            final double airtimeSeconds =
                                evt!.airTime.inMilliseconds / 1000.0;
                            height = (9.81 * pow(airtimeSeconds / 2, 2)) * 100;
                            calories = height * 0.02;
                            power = evt.peakTakeoffG;

                            // Notifier le saut détecté
                            onJumpDetected?.call(height, calories, power);
                          }

                          return Column(
                            children: [
                              Text(
                                'Sauts: $jumpCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (hasData) ...[
                                Text(
                                  "Hauteur: ${height.toStringAsFixed(1)} cm",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Calories: ${calories.toStringAsFixed(1)} kcal",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Puissance: ${evt!.peakTakeoffG.toStringAsFixed(2)} g",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else
                                const Text(
                                  "Prêt à sauter !",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

}
