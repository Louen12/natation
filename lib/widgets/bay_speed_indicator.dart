import 'package:flutter/material.dart';

class BaySpeedIndicator extends StatelessWidget {
  final double vitesseCible;
  final double vitesseGPS;

  const BaySpeedIndicator({
    super.key,
    required this.vitesseCible,
    required this.vitesseGPS,
  });

  @override
  Widget build(BuildContext context) {
    bool correct = (vitesseGPS - vitesseCible).abs() < 0.5;
    Color color = correct ? Colors.green : Colors.red;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Vitesse cible",
          style: TextStyle(
            color: Colors.orange.shade700,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          "${vitesseCible.toStringAsFixed(1)} km/h",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          "Vitesse GPS",
          style: TextStyle(
            color: Colors.orange.shade700,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          "${vitesseGPS.toStringAsFixed(1)} km/h",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 16),
        Icon(
          correct ? Icons.check_circle : Icons.warning_amber_rounded,
          color: color,
          size: 56,
        ),
      ],
    );
  }
}
