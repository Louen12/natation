import 'package:flutter/material.dart';
import 'package:natation/screens/jump_exercise.dart';
import 'package:natation/screens/sleeving_exercise.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Natation App',
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 219, 219, 219),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFFFF6200),
              ),
              child: Text(
                'Natation App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Exercice de Saut'),
              selected: _currentIndex == 0,
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.accessibility_new),
              title: const Text('Gainage Latéral'),
              selected: _currentIndex == 1,
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Exercice de Saut' : 'Gainage Latéral'),
        backgroundColor: const Color(0xFFFF6200),
        foregroundColor: Colors.white,
      ),
      body: _currentIndex == 0 
          ? const JumpExercisePage()
          : const SleevingExercisePage(),
    );
  }
}
