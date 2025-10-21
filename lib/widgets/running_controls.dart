import 'package:flutter/material.dart';

class RunningControls extends StatelessWidget {
  final bool running;
  final bool paused;
  final bool finished;
  final bool success;
  final VoidCallback onStart;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;
  final double plannedDistanceMeters;
  final int maxDurationSeconds;

  const RunningControls({
    super.key,
    required this.running,
    required this.paused,
    this.finished = false,
    this.success = false,
    required this.onStart,
    required this.onPauseResume,
    required this.onStop,
    required this.maxDurationSeconds,
    required this.plannedDistanceMeters,

  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: const BoxDecoration(
        color: Color(0xCC0D0D0D), // fond foncé
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      height: finished ? 300 : null, // S'agrandit quand c'est fini

      child: finished
          ? _buildResultView(context)
          : _buildControlsView(context),
    );
  }

  Widget _buildResultView(BuildContext context) {
    final gifPath = success
        ? "assets/images/success.gif" // GIF de succès
        : "assets/images/clash-royale-boohoo.gif"; // GIF d'échec

    final message = success ? "GOOD JOB!" : "MAYBE NEXT TIME!";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // GIF
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset(
              gifPath,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Message
        Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'DynaPuff',
          ),
        ),
        const SizedBox(height: 24),

        // Ligne de deux boutons : Rejouer et Accueil
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onStart,
              icon: const Icon(Icons.replay, color: Colors.white, size: 38),
              style: IconButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(20),
                shape: const CircleBorder(),
              ),
            ),
            const SizedBox(width: 20),
            IconButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              icon: const Icon(Icons.home, color: Colors.white, size: 32),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.all(20),
                shape: const CircleBorder(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlsView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (running)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              "Objectif: ${(plannedDistanceMeters / 1000).toStringAsFixed(2)} km en ${(maxDurationSeconds / 60).toStringAsFixed(0)} min",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: running ? onPauseResume : null,
              icon: Icon(
                paused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.all(20),
                shape: const CircleBorder(),
              ),
            ),

            running
                ? Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  "assets/images/giphy.gif", // ton gif dans assets
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                ),
              ),
            )
                : IconButton(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow, color: Colors.white, size: 38),
              style: IconButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(20),
                shape: const CircleBorder(),
              ),
            ),

            IconButton(
              onPressed: running ? onStop : null,
              icon: const Icon(Icons.stop, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.all(20),
                shape: const CircleBorder(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
