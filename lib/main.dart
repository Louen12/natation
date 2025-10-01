import 'package:flutter/material.dart';
import 'screens/traction_page.dart';
import 'models/traction.dart';

void main() {
  // Création plan personnalisé
  const customPlan = TractionPlan(
    sets: 4,
    repsPerSet: 10,
    restSeconds: 20,
  );

  runApp(MyApp(plan: customPlan));
}

class MyApp extends StatelessWidget {
  final TractionPlan plan;

  const MyApp({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TractionPage(plan: plan),
    );
  }
}
