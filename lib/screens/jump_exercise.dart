import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:natation/services/jump_service.dart';
import 'package:provider/provider.dart';
import '../widgets/ExerciseCard.dart';
import '../widgets/draggable_nav_bar.dart';
import '../services/tts_service.dart';
import '../repositories/jump_repository.dart';
import '../models/jump_session.dart';

class JumpExercisePage extends StatefulWidget {
  const JumpExercisePage({super.key});

  @override
  State<JumpExercisePage> createState() => _JumpExercisePageState();
}

class _JumpExercisePageState extends State<JumpExercisePage> {
  final TTSService _ttsService = TTSService();
  final GlobalKey<ExerciseCardState> _cardKey = GlobalKey<ExerciseCardState>();
  final JumpRepository _repository = JumpRepository();
  
  final String _exerciseText =
      "Pour cette séance, nous allons faire des SAUTS VERTICAUX. "
      "Sautez aussi haut que possible ! L'application détectera la hauteur, "
      "la puissance et estimera les calories brûlées.";

  bool _isSpeaking = false;
  bool _isPlaying = false;
  int _jumpCount = 0;
  double _totalHeight = 0;
  double _totalCalories = 0;
  double _maxHeight = 0;
  double _totalPower = 0;
  DateTime? _sessionStartTime;
  Duration _totalSessionTime = Duration.zero;
  StreamSubscription<JumpEvent>? _jumpSubscription;

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
    _jumpSubscription?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    _cardKey.currentState?.toggleTimer();
    
    if (_isPlaying) {
      _startExercise();
    } else {
      _ttsService.stop();
    }
  }

  void _startExercise() {
    if (_sessionStartTime == null) {
      _sessionStartTime = DateTime.now();
      // Message de début
      _ttsService.speak("C'est parti ! Commencez vos sauts verticaux !");
    }
    
    // Écouter les événements de saut
    _jumpSubscription?.cancel();
    _jumpSubscription = Provider.of<JumpService>(context, listen: false).events.listen((jumpEvent) {
      _onJumpDetected(jumpEvent);
    });
  }

  void _stopExercise() {
    // Arrêter tout
    _ttsService.stop();
    _jumpSubscription?.cancel();
    
    // Arrêter le timer de l'ExerciseCard
    _cardKey.currentState?.stopTimer();
    
    // Calculer le temps total au moment de l'arrêt
    if (_sessionStartTime != null) {
      _totalSessionTime = DateTime.now().difference(_sessionStartTime!);
    }
    
    // Sauvegarder la session
    _saveSession();
    
    // Mettre à jour l'état
    setState(() {
      _isPlaying = false;
    });
    
    _showResults();
  }

  void _saveSession() async {
    if (_sessionStartTime != null && _jumpCount > 0) {
      final session = JumpSession(
        startTime: _sessionStartTime!,
        endTime: DateTime.now(),
        duration: _totalSessionTime,
        repetitions: _jumpCount,
        totalHeight: _totalHeight,
        maxHeight: _maxHeight,
        totalCalories: _totalCalories,
        averagePower: _totalPower / _jumpCount,
        notes: 'Session de sauts verticaux',
      );
      
      try {
        await _repository.insertSession(session);
        print('Session de sauts sauvegardée: ${session.toMap()}');
      } catch (e) {
        print('Erreur lors de la sauvegarde: $e');
      }
    }
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
      _sessionStartTime = null;
      _totalSessionTime = Duration.zero;
    });
  }

  void _onJumpDetected(JumpEvent jumpEvent) {
    final double airtimeSeconds = jumpEvent.airTime.inMilliseconds / 1000.0;
    final double height = (9.81 * pow(airtimeSeconds / 2, 2)) * 100;
    final double calories = height * 0.02;
    final double power = jumpEvent.peakTakeoffG;

    setState(() {
      _jumpCount++;
      _totalHeight += height;
      _totalCalories += calories;
      _totalPower += power;
      if (height > _maxHeight) _maxHeight = height;
    });

    // Text-to-speech selon le nombre de sauts
    _speakMotivation();
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
        create: (_) => JumpService(massKg: 70.0)..start(),
        child: _JumpView(
          cardKey: _cardKey,
          isPlaying: _isPlaying,
          jumpCount: _jumpCount,
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

// Juste un wrapper pour ne pas polluer ton arbre avec le provider scope
class ProviderScope extends StatelessWidget {
  final Widget child;
  const ProviderScope({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

class _JumpView extends StatelessWidget {
  final GlobalKey<ExerciseCardState> cardKey;
  final bool isPlaying;
  final int jumpCount;
  final VoidCallback? onPlayPause;
  final VoidCallback? onStop;
  final VoidCallback? onSpeak;
  final VoidCallback? onStopSpeak;
  final bool isSpeaking;
  final String bestTime;

  const _JumpView({
    required this.cardKey,
    required this.isPlaying,
    required this.jumpCount,
    this.onPlayPause,
    this.onStop,
    this.onSpeak,
    this.onStopSpeak,
    required this.isSpeaking,
    required this.bestTime,
  });

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
                  child: isPlaying
                      ? _buildExerciseVisual(service)
                      : _buildInstructionBlock(),
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
    return Container(
      key: const ValueKey('exercise'),
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatLine(
                      "Hauteur du saut :",
                      hasData ? "${height.toStringAsFixed(1)} cm" : "--",
                    ),
                    _buildStatLine(
                      "Calories brûlées :",
                      hasData ? "${calories.toStringAsFixed(1)} kcal" : "--",
                    ),
                    _buildStatLine(
                      "Nombre de sauts :",
                      "$jumpCount",
                    ),
                    _buildStatLine(
                      "Puissance estimée :",
                      hasData
                          ? "${evt!.peakTakeoffG.toStringAsFixed(2)} g"
                          : "--",
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: hasData ? 1.0 : 0.8,
                child: Image.asset(
                  "assets/images/refObscur.png",
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        "$label $value",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'DynaPuff',
        ),
      ),
    );
  }
}
