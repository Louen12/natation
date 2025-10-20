import 'package:flutter/material.dart';
import 'package:natation/screens/jump_exercise.dart';
import 'screens/sleeving_exercise.dart';
import 'widgets/ExerciseCard.dart';
import 'widgets/draggable_nav_bar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draggable NavBar',
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isPlaying = false;
  bool isJumpPage = false;
  String exerciseTitle = "Titre de l'exercice";
  final GlobalKey<ExerciseCardState> _cardKey = GlobalKey<ExerciseCardState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 219, 219, 219),
      body: Stack(
        children: [
          Center(
            child: isJumpPage
                ? JumpExercisePage(cardKey: _cardKey, isPlaying: isPlaying)
                : SleevingExercisePage(
                    cardKey: _cardKey,
                    showInstructions:
                        !isPlaying,
                  ),
          ),

          DraggableNavBar(
            isPlaying: isPlaying,
            exerciseTitle: exerciseTitle,
            onPlayPause: () {
              _cardKey.currentState?.toggleTimer();
              setState(() => isPlaying = !isPlaying);
            },
            onStop: () => setState(() => isPlaying = false),

            onNext: () {
              setState(() {
                isJumpPage = !isJumpPage;
                exerciseTitle =
                    isJumpPage ? "Jump Exercise" : "Gainage Latéral";
              });
            },
          ),
        ],
      ),
    );
  }
}
