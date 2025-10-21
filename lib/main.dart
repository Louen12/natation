import 'package:flutter/material.dart';
import 'package:natation/screens/jump_exercise.dart';
import 'package:natation/screens/program.dart';
import 'package:natation/screens/sleeving_exercise.dart';
import 'package:natation/screens/yoga.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const ProgramPage(title: 'Programme'),
        '/yoga': (context) => const YogaPage(title: "Yoga"),
        '/saut': (context) => const JumpPage(title: "Saut"),
        '/gainage': (context) => const SleevingExercisePage(),
      },
    );
  }
}
