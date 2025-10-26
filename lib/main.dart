import 'package:flutter/material.dart';
import 'package:natation/screens/history_vma_screen.dart';
import 'package:natation/screens/program.dart';
import 'package:natation/screens/program_exercises.dart';
import 'package:natation/screens/result_vma_screen.dart';
import 'package:natation/screens/test_vma_home_screen.dart';
import 'package:natation/screens/test_vma_run_screen.dart';
import 'package:natation/screens/traction_page.dart';
import 'package:natation/screens/yoga.dart';
import 'package:natation/screens/training.dart';
import 'package:natation/screens/running.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const ProgramPage(title: 'Programme'),
        '/yoga': (context) => const YogaPage(title: "Yoga"),
        '/course': (context) => const RunningScreen(title: "Course"),
        '/vma': (context) => const TestVmaHomeScreen(),
        '/vma_test': (context) => const TestVmaRunScreen(),
        '/history_vma': (context) => const HistoryVmaScreen(),
        '/result_vma': (context) => const ResultVmaScreen(),
        '/traction': (context) => const TractionPage(),
        '/result_course': (context) => const ResultVmaScreen(), // TODO: change to result_course_screen
      },
    );
  }
}
