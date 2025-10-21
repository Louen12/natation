import 'package:flutter/material.dart';
import 'package:natation/screens/history_vma_screen.dart';
import 'package:natation/screens/program.dart';
import 'package:natation/screens/program_exercises.dart';
import 'package:natation/screens/result_vma_screen.dart';
import 'package:natation/screens/test_vma_home_screen.dart';
import 'package:natation/screens/test_vma_run_screen.dart';
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
        '/vma': (context) => const TestVmaHomeScreen(),
        '/vma_test': (context) => const TestVmaRunScreen(),
        '/history_vma': (context) => const HistoryVmaScreen(),
        '/result_vma': (context) => const ResultVmaScreen(),
      },
    );
  }
}