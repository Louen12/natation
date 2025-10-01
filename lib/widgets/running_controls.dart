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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: running ? null : onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Lancer'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: running ? onPauseResume : null,
              icon: Icon(paused ? Icons.play_arrow : Icons.pause),
              label: Text(paused ? 'Reprendre' : 'Pause'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: running ? onStop : null,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
