import 'package:flutter/material.dart';
import '../models/thresholds.dart';

class ThresholdSliders extends StatelessWidget {
  final Thresholds thresholds;
  final ValueChanged<Thresholds> onChanged;

  const ThresholdSliders({
    super.key,
    required this.thresholds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Text('down'),
            Expanded(
              child: Slider(
                value: thresholds.down,
                min: -3,
                max: 0,
                onChanged: (v) => onChanged(thresholds.copyWith(down: v)),
              ),
            ),
            Text(thresholds.down.toStringAsFixed(2)),
          ],
        ),
        Row(
          children: [
            const Text('up   '),
            Expanded(
              child: Slider(
                value: thresholds.up,
                min: 0,
                max: 3,
                onChanged: (v) => onChanged(thresholds.copyWith(up: v)),
              ),
            ),
            Text(thresholds.up.toStringAsFixed(2)),
          ],
        ),
      ],
    );
  }
}
