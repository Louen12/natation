import 'package:flutter/material.dart';

class RunningControls extends StatelessWidget {
  final bool running;
  final bool paused;
  final VoidCallback onStart;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;

  const RunningControls({
    super.key,
    required this.running,
    required this.paused,
    required this.onStart,
    required this.onPauseResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),

      child: Row(
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
                "maquette/giphy.gif", // ton gif dans assets
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
    );
  }
}
