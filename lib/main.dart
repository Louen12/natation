import 'package:flutter/material.dart';
import 'package:natation/screens/program.dart';
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
        '/': (context) => const YogaPage(title: 'Programme'),
        '/yoga': (context) => const YogaPage(title: "Yoga"),
      },
    );
  }
}
