import 'package:flutter/material.dart';
import 'package:natation/screens/history_vma_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:natation/models/run_session.dart';
import 'package:natation/screens/tjtq_result_race.dart';
import 'screens/traction_page.dart';
import 'models/traction.dart';
import 'package:natation/screens/program.dart';
import 'package:natation/screens/program_exercises.dart';
import 'package:natation/screens/result_vma_screen.dart';
import 'package:natation/screens/test_vma_home_screen.dart';
import 'package:natation/screens/test_vma_run_screen.dart';
import 'package:natation/screens/yoga.dart';

void main() {
  runApp(MyApp());
}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
// Création plan personnalisé
// const customPlan = TractionPlan(
  // sets: 4,
  // repsPerSet: 10,
  // restSeconds: 20,
// );
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: TractionPage(plan: customPlan),
//     );
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemple de parcours pour le test
    final List<LatLng> testTrack = [
      LatLng(48.111338, -1.68002), // Rennes
      LatLng(48.11321, -1.6745),
      LatLng(48.11501, -1.6720),
      LatLng(48.1163, -1.6781),
      LatLng(48.1139, -1.6820),
    ];

    final testSession = RunSession(
      plannedDistanceMeters: 1000,
      maxDurationSeconds: 600,
      distanceMeters: 950,
      elapsed: const Duration(seconds: 580),
      track: testTrack,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const ProgramPage(title: 'Programme'),
        '/yoga': (context) => const YogaPage(title: "Yoga"),
        '/traction': (context) => const TractionPage(
              plan: TractionPlan(sets: 3, repsPerSet: 8, restSeconds: 30),
            ),
        '/course': (context) => RunResultPage(runSession: testSession),
        '/vma': (context) => const TestVmaHomeScreen(),
        '/vma_test': (context) => const TestVmaRunScreen(),
        '/history_vma': (context) => const HistoryVmaScreen(),
        '/result_vma': (context) => const ResultVmaScreen(),
      },
    );
  }
}