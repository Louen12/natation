// jump_page.dart
import 'package:flutter/material.dart';
import 'package:natation/services/jump_service.dart';
import 'package:provider/provider.dart';

class JumpExercisePage extends StatelessWidget {
  const JumpExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JumpService()..start(),
      child: const _JumpView(),
    );
  }
}

class _JumpView extends StatelessWidget {
  const _JumpView();

  @override
  Widget build(BuildContext context) {
    final service = context.watch<JumpService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Détection de sauts')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: service.jumpCount,
              builder: (_, count, __) =>
                  Text('Sauts détectés: $count', style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<JumpEvent>(
                stream: service.events,
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Center(child: Text('Saute pour voir un event.'));
                  }
                  final e = snap.data!;
                  return Center(
                    child: Text(
                      'Dernier saut:\n'
                          'Airtime: ${e.airTime.inMilliseconds} ms\n'
                          'Takeoff: ${e.peakTakeoffG.toStringAsFixed(2)} g\n'
                          'Landing: ${e.peakLandingG.toStringAsFixed(2)} g',
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: service.isRunning ? null : service.start,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: service.isRunning ? service.stop : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
