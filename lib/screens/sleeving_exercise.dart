import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/ExerciseCard.dart';
import '../services/tts_service.dart';

class SleevingExercisePage extends StatefulWidget {
  final GlobalKey<ExerciseCardState> cardKey;
  final bool showInstructions;

  const SleevingExercisePage({
    super.key,
    required this.cardKey,
    this.showInstructions = true,
  });

  @override
  State<SleevingExercisePage> createState() => _SleevingExercisePageState();
}

class _SleevingExercisePageState extends State<SleevingExercisePage> {
  final TTSService _ttsService = TTSService();
  final String _exerciseText =
      "Pour cette séance, nous allons faire un GAINAGE LATÉRAL 8 fois. "
      "Commencez en position de planche latérale avec les pieds superposés. "
      "Soulevez les hanches tout en gardant le corps droit. Tenez la position.";

  bool _isSpeaking = false;
  bool _showLeo = false;
  Timer? _leoTimer;

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

  void _startLeoTimer() {
    _leoTimer?.cancel();
    _leoTimer = Timer(const Duration(seconds: 30), () {
      setState(() {
        _showLeo = true;
      });
    });
  }

  void _resetLeoState() {
    _leoTimer?.cancel();
    setState(() {
      _showLeo = false;
    });
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _leoTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SleevingExercisePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.showInstructions && !widget.showInstructions) return;

    if (!widget.showInstructions) {
      _startLeoTimer();
    } else {
      _resetLeoState();
    }
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
                  key: widget.cardKey,
                  bestTime: "09:20",
                  repetitions: 2,
                  leftImage: "assets/images/fast-cheetah.png",
                  rightImage: "assets/images/bird.png",
                ),
                const SizedBox(height: 20),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: widget.showInstructions
                      ? _buildInstructionBlock()
                      : _buildExerciseVisual(),
                ),
              ],
            ),
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
                Container(
                  height: 250,
                  child: Image.asset(
                    "assets/images/leo.png",
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
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
              ],
            )
          : Column(
              key: const ValueKey('grosBlock'),
              children: [
                Container(
                  height: 250,
                  child: Image.asset(
                    "assets/images/gros.png",
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
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
              ],
            ),
    );
  }
}
