import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/counter_notifier.dart';
import '../widgets/threshold_sliders.dart';

class CounterPage extends ConsumerWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(counterProvider);
    final notifier = ref.read(counterProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Compteur de tractions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FilledButton.icon(
                  onPressed: notifier.start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Démarrer'),
                ),
                OutlinedButton.icon(
                  onPressed: notifier.stop,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
                OutlinedButton.icon(
                  onPressed: notifier.reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Répétitions', style: Theme.of(context).textTheme.titleLarge),
            Text('${state.reps}', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 12),
            Text(
              'Phase: ${state.phase} • zLP: ${state.z.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(height: 32),
            ThresholdSliders(
              thresholds: state.thresholds,
              onChanged: notifier.updateThresholds,
            ),
            const SizedBox(height: 12),
            Text(
              'Conseil: Mettre votre téléphone dans votre poche pour de meilleurs résultats.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
