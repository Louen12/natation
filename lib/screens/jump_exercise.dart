import 'dart:math';
import 'package:flutter/material.dart';
import 'package:natation/services/jump_service.dart';
import 'package:provider/provider.dart';
import '../widgets/ExerciseCard.dart';

class JumpExercisePage extends StatefulWidget {
  final GlobalKey<ExerciseCardState> cardKey;
  final bool isPlaying;

  const JumpExercisePage({
    super.key,
    required this.cardKey,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => JumpService()..start(),
        child: const _JumpView(),
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
  const _JumpView();

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => JumpService()..start(),
        child: _JumpView(cardKey: widget.cardKey, isPlaying: widget.isPlaying),
      ),
    );
  }
}

class ProviderScope extends StatelessWidget {
  final Widget child;
  const ProviderScope({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

class _JumpView extends StatelessWidget {
  final GlobalKey<ExerciseCardState> cardKey;
  final bool isPlaying;

  const _JumpView({required this.cardKey, required this.isPlaying});

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
                  bestTime: "09:20",
                  repetitions: service.jumpCount.value,
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
      child: const Column(
        children: [
          Text(
            "EXERCICE DE SAUTS",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'DynaPuff',
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Prépare-toi à sauter aussi haut que possible !\n"
            "L’application détectera la hauteur du saut, la puissance et estimera les calories brûlées.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
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
          if (hasData) {
            final double airtimeSeconds =
                evt!.airTimeMs.inMilliseconds / 1000.0;
            height = (9.81 * pow(airtimeSeconds / 2, 2)) * 100;
            calories = height * 0.02;
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
                      "${service.jumpCount.value}",
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
