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
    bool correct  = (vitesseGPS - vitesseCible).abs() < 0.5;
    return Column(
      children: [
        Text("Vitesse cible : ${vitesseCible.toStringAsFixed(1)} km/h"),
        Text("Vitesse GPS : ${vitesseGPS.toStringAsFixed(1)} km/h"),
        Icon(
          correct ? Icons.check_circle : Icons.warning,
          color: correct ? Colors.green : Colors.red,
          size: 48,
        ),
      ],
    );
  }
}
