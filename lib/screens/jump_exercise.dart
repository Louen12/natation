// jump_page.dart
import 'package:flutter/material.dart';
import 'package:natation/services/jump_metrics.dart';
import 'package:natation/services/jump_service.dart';
import 'package:provider/provider.dart';

class JumpExercisePage extends StatelessWidget {
  const JumpExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      //TODO: adjust massKg with user profile
      create: (_) => JumpService(massKg: 72)..start(),
      child: const _JumpView(),
    );
  }
}

class _JumpView extends StatelessWidget {
  const _JumpView();

  String _m(double v) => '${v.toStringAsFixed(2)} m';

  String _k(double v) => '${v.toStringAsFixed(2)} kcal';

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
              builder: (_, count, __) => Text(
                'Sauts détectés: $count',
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(height: 8),

            ValueListenableBuilder<JumpStats>(
              valueListenable: service.stats,
              builder: (_, s, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Moyenne hauteur: ${_m(s.avgHeightM)}'),
                  Text('Plus haut:         ${_m(s.maxHeightM)}'),
                  Text('Plus bas:          ${_m(s.minHeightM)}'),
                  Text('Calories totales:  ${_k(s.totalCaloriesKcal)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<JumpEvent>(
                stream: service.events,
                builder: (_, snap) {
                  if (!snap.hasData)
                    return const Center(child: Text('Saute pour commencer.'));
                  final e = snap.data!;
                  return Center(
                    child: Text(
                      'Dernier saut: ${e.airTime.inMilliseconds} ms en l’air\n'
                      'Takeoff: ${e.peakTakeoffG.toStringAsFixed(2)} g  '
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
