import 'package:flutter/material.dart';
import 'package:natation/services/jump_service.dart';
import 'package:provider/provider.dart';

class JumpExercisePage extends StatelessWidget {
  const JumpExercisePage({super.key});

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
    final service = context.watch<JumpService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Jump detector')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Compteur des sauts avec ValueListenableBuilder
            ValueListenableBuilder<int>(
              valueListenable: service.jumpCount,
              builder: (_, count, __) => Text(
                'Sauts détectés: $count',
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(height: 12),

            // Réagir aux événements ponctuels
            Expanded(
              child: StreamBuilder<JumpEvent>(
                stream: service.events,
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Center(child: Text('Bouge-toi et saute.'));
                  }
                  final evt = snap.data!;
                  return Center(
                    child: Text(
                      'Dernier saut:\n'
                          '- airtime: ${evt.airTimeMs.inMilliseconds} ms\n'
                          '- takeoff: ${evt.peakTakeoffG.toStringAsFixed(2)} g\n'
                          '- landing: ${evt.peakLandingG.toStringAsFixed(2)} g',
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
