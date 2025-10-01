import 'package:flutter/material.dart';
import '../widgets/ExerciseCard.dart';
import '../services/tts_service.dart';

class SleevingExercisePage extends StatefulWidget {
  const SleevingExercisePage({super.key});

  @override
  State<SleevingExercisePage> createState() => _SleevingExercisePageState();
}

class _SleevingExercisePageState extends State<SleevingExercisePage> {
  final TTSService _ttsService = TTSService();
  final String _exerciseText =
      "Pour cette séance, nous allons faire un GAINAGE LATÉRAL 8 fois. Commencez en position de planche latérale avec les pieds superposés. Soulevez les hanches tout en gardant le corps droit. Tenez la position.";

  bool _isSpeaking = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercice de gainage')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExerciseCard(
              title: "4 couleurs",
              bestTime: "00:45",
              time: "-:--",
              repetitions: 3,
              leftImage: "assets/images/fast-cheetah.png",
              rightImage: "assets/images/bird.png",
            ),
            const SizedBox(height: 20),
            Container(
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500 , fontFamily: 'DynaPuff'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Commencez en position de planche latérale avec les pieds superposés. Soulevez les hanches tout en gardant le corps droit. Tenez la position.",
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
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: ElevatedButton.icon(
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
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: ElevatedButton.icon(
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
                      ),
                    ],
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
