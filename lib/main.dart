import 'package:flutter/material.dart';
import 'package:natation/screens/history_vma_screen.dart';
import 'package:natation/screens/result_vma_screen.dart';
import 'package:natation/screens/test_vma_home_screen.dart';
import 'package:natation/screens/test_vma_run_screen.dart';
import 'package:natation/screens/program_exercises.dart';

void main() {
  runApp(MaterialApp(
    home: MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Sport',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(), // 👈 définis ton écran d’accueil
      routes: {
        '/test_vma_home' : (context) => TestVmaHomeScreen(),
        '/test_vma_run': (context) => TestVmaRunScreen(),
        '/result': (context) => ResultVmaScreen(),
        '/history_vma': (context) => HistoryVmaScreen(),
        '/programme': (context) => ProgramExercises()
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Accueil")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/test_vma_home');
              },
              child: const Text("Page test VMA"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/programme');
              },
              child: const Text("Page programme"),
            ),
          ],
        ),
      ),
    );
  }
}
