import 'package:flutter/material.dart';
import 'package:natation/screens/sleeving_exercise.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SleevingExercisePage(),
        ),
      ),
    );
  }
}
