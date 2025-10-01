import 'package:flutter/material.dart';
import '../widgets/ExerciseCard.dart';

class SleevingExercisePage extends StatelessWidget {
  final GlobalKey<ExerciseCardState> cardKey;

  const SleevingExercisePage({super.key, required this.cardKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/julcik.png", fit: BoxFit.cover),
          Container(
            color: const Color.fromARGB(120, 0, 0, 0),
            child: Column(
              children: [
                ExerciseCard(
                  key: cardKey,
                  title: "Nath à fond",
                  bestTime: "00:45",
                  repetitions: 3,
                  leftImage: "assets/images/fast-cheetah.png",
                  rightImage: "assets/images/bird.png",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

