import 'package:flutter/material.dart';
import '../widgets/ExerciseCard.dart';

class SleevingExercisePage extends StatefulWidget {
  const SleevingExercisePage({super.key});

  @override
  State<SleevingExercisePage> createState() => _SleevingExercisePageState();
}

class _SleevingExercisePageState extends State<SleevingExercisePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercice de gainage')),
      body: Center(
        child: ExerciseCard(
          title: "4 couleurs",
          bestTime: "00:45",
          time: "-:--",
          repetitions: 3,
          leftImage: "assets/images/fast-cheetah.png",
          rightImage: "assets/images/bird.png",
        ),
      ),
    );
  }
}
