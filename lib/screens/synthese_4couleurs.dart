import 'package:flutter/material.dart';
import 'jump_exercise.dart';
import 'sleeving_exercise.dart';
import 'stats_screen.dart';

class Synthese4Couleurs extends StatefulWidget {
  const Synthese4Couleurs({super.key});

  @override
  State<Synthese4Couleurs> createState() => _Synthese4CouleursState();
}

class _Synthese4CouleursState extends State<Synthese4Couleurs> {
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
                '4 Couleurs - Natation',
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
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Statistiques'),
              selected: _currentIndex == 2,
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: const Color(0xFFFF6200),
        foregroundColor: Colors.white,
      ),
      body: _getCurrentPage(),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Exercice de Saut';
      case 1:
        return 'Gainage Latéral';
      case 2:
        return 'Statistiques';
      default:
        return '4 Couleurs - Natation';
    }
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const JumpExercisePage();
      case 1:
        return const SleevingExercisePage();
      case 2:
        return const StatsScreen();
      default:
        return const JumpExercisePage();
    }
  }
}
