import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/ExerciseCard.dart';
import '../widgets/draggable_nav_bar.dart';
import '../services/tts_service.dart';
import '../services/timer_service.dart';
import '../services/audio_service.dart';
import '../repositories/sleeving_repository.dart';
import '../models/sleeving_session.dart';

class SleevingExercisePage extends StatefulWidget {
  const SleevingExercisePage({super.key});

  @override
  State<SleevingExercisePage> createState() => _SleevingExercisePageState();
}

class _SleevingExercisePageState extends State<SleevingExercisePage> {
  final TTSService _ttsService = TTSService();
  final AudioService _audioService = AudioService();
  final GlobalKey<ExerciseCardState> _cardKey = GlobalKey<ExerciseCardState>();
  final SleevingRepository _repository = SleevingRepository();

  final String _exerciseText =
      "Pour cette séance, nous allons faire un GAINAGE LATÉRAL 8 fois. "
      "Commencez en position de planche latérale avec les pieds superposés. "
      "Soulevez les hanches tout en gardant le corps droit. Tenez la position.";

  bool _isSpeaking = false;
  bool _showLeo = false;
  bool _isPlaying = false;
  bool _showInstructions = true;
  bool _isStopped = false;
  Timer? _leoTimer;

  // Chronomètre pour le gainage
  late TimerService _timerService;
  int _repetitions = 0;
  final int _targetRepetitions = 8;
  DateTime? _sessionStartTime;
  Duration _totalSessionTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _ttsService.setOnStateChanged(_updateSpeakingState);
    
    // Initialiser le chronomètre (10 secondes par répétition)
    _timerService = TimerService(targetDuration: const Duration(seconds: 10));
    _timerService.setOnStartBeep(() => _audioService.playStartBeep());
    _timerService.setOnEndBeep(() {
      _audioService.playEndBeep();
      _nextRepetition(); // Incrémenter automatiquement à 10s
    });
    _timerService.setOnTick(() => _audioService.playTickBeep());
  }

  void _updateSpeakingState() {
    setState(() {
      _isSpeaking = _ttsService.isSpeaking;
    });
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
      _timerService.pause();
      _ttsService.stop();
      _leoTimer?.cancel();
      _cardKey.currentState?.stopTimer();
    }
  }

  void _startExercise() {
    if (_sessionStartTime == null) {
      _sessionStartTime = DateTime.now();
      // Message de début
      _ttsService.speak("C'est parti ! Commencez votre gainage latéral !");
    }
    
    if (_repetitions < _targetRepetitions) {
      if (_timerService.isPaused) {
        _timerService.resume(); // Reprendre au lieu de redémarrer
        _ttsService.speak("Reprise de l'exercice !");
      } else {
        _timerService.start();
      }
    }
  }


  void _stopExercise() {
    // Arrêter tout
    _timerService.stop();
    _ttsService.stop();
    
    // Annuler tous les timers
    _leoTimer?.cancel();
    
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
      _showInstructions = true;
      _showLeo = false; // Cacher Gros Léo
      _isStopped = true; // Marquer comme arrêté
    });
    
    _showResults();
  }

  void _saveSession() async {
    if (_sessionStartTime != null && _repetitions > 0) {
      final averageHoldTime = Duration(
        milliseconds: _totalSessionTime.inMilliseconds ~/ _repetitions,
      );
      
      final session = SleevingSession(
        startTime: _sessionStartTime!,
        endTime: DateTime.now(),
        duration: _totalSessionTime,
        repetitions: _repetitions,
        targetRepetitions: _targetRepetitions,
        averageHoldTime: averageHoldTime,
        notes: 'Session de gainage latéral',
      );
      
      try {
        await _repository.insertSession(session);
        print('Session de gainage sauvegardée: ${session.toMap()}');
      } catch (e) {
        print('Erreur lors de la sauvegarde: $e');
      }
    }
  }

  void _nextRepetition() {
    if (_repetitions < _targetRepetitions) {
      setState(() {
        _repetitions++;
      });
      
      // Text-to-speech selon le nombre de répétitions
      _speakMotivation();
      
      // Démarrer le timer pour Gros Léo après 4 répétitions
      if (_repetitions >= 2) {
        Timer(const Duration(seconds: 10), () {
          if (mounted) {
            setState(() {
              _showLeo = true;
            });
            // Gros Léo parle
            _ttsService.speak("Gros Léo est fier de toi !");
          }
        });
      }
      
      if (_repetitions < _targetRepetitions) {
        _timerService.restart();
      } else {
        _timerService.stop();
        // Exercice terminé - calculer le temps total
        if (_sessionStartTime != null) {
          _totalSessionTime = DateTime.now().difference(_sessionStartTime!);
        }
        setState(() {
          _isPlaying = false;
          _showInstructions = true;
        });
        _ttsService.speak("Bravo ! Tu as terminé l'exercice ! Gros Léo est très fier de toi !");
        // Attendre que le TTS finisse avant d'afficher la modale
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _showResults();
          }
        });
      }
    }
  }

  void _speakMotivation() {
    if (_repetitions <= 2) {
      _ttsService.speak("C'est mou ! Allez, plus fort tu veux maigrir ou pas ? Tu veux rester comme Choji à vie ?!");
    } else if (_repetitions <= 4) {
      _ttsService.speak("Ça va mieux ! Continue tu veux maigrir ou pas ? Tu veux rester comme Choji à vie ?!");
    } else if (_repetitions <= 6) {
      _ttsService.speak("Excellent ! Tu es sur la bonne voie !");
    } else {
      _ttsService.speak("Presque fini ! Tu es formidable  !");
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
              _buildResultRow('Répétitions', '$_repetitions/$_targetRepetitions'),
              _buildResultRow('Temps total', formattedTotalTime),
              _buildResultRow('Répétitions complétées', _repetitions >= _targetRepetitions ? 'Oui' : 'Non'),
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
    _timerService.stop();
    _ttsService.stop(); // Arrêter le TTS
    
    // Réinitialiser le timer AVANT setState
    _timerService.reset();
    
    // Réinitialiser le timer de l'ExerciseCard
    _cardKey.currentState?.resetTimer();
    
    setState(() {
      _repetitions = 0;
      _isPlaying = false;
      _showInstructions = true;
      _showLeo = false;
      _isStopped = false; // Réinitialiser l'état d'arrêt
      _sessionStartTime = null;
      _totalSessionTime = Duration.zero;
    });
  }


  @override
  void dispose() {
    _ttsService.dispose();
    _timerService.dispose();
    _leoTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SleevingExercisePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Plus besoin de cette méthode car on gère les états localement
  }

  @override
  Widget build(BuildContext context) {
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
                  title: "NATH A FOND",
                  key: _cardKey,
                  bestTime: _getBestTime(),
                  repetitions: _repetitions,
                  leftImage: "assets/images/fast-cheetah.png",
                  rightImage: "assets/images/bird.png",
                ),
                const SizedBox(height: 20),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: _showInstructions
                      ? _buildInstructionBlock()
                      : _buildExerciseVisual(),
                ),
              ],
            ),
          ),
          
          // DraggableNavBar
          DraggableNavBar(
            isPlaying: _isPlaying,
            exerciseTitle: "Gainage Latéral",
            onPlayPause: _togglePlayPause,
            onStop: _stopExercise,
            onNext: _nextRepetition,
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
            "GAINAGE LATÉRAL x8",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'DynaPuff',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Commencez en position de planche latérale avec les pieds superposés. "
            "Soulevez les hanches tout en gardant le corps droit. Tenez la position.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isSpeaking
                    ? null
                    : () async {
                        await _ttsService.speak(_exerciseText);
                        _updateSpeakingState();
                      },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Écouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6200),
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSpeaking
                    ? () async {
                        await _ttsService.stop();
                        _updateSpeakingState();
                      }
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

  Widget _buildExerciseVisual() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _showLeo
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
                
                // Chronomètre en overlay - seulement si pas arrêté
                if (!_isStopped)
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
                      child: Column(
                        children: [
                          Text(
                            'Répétition ${_repetitions}/$_targetRepetitions',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AnimatedBuilder(
                            animation: _timerService,
                            builder: (context, child) {
                              return Text(
                                _timerService.formattedDuration,
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'DynaPuff',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
