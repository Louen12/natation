import 'package:flutter/material.dart';
import 'package:natation/screens/synthese_4couleurs.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4 Couleurs - Natation',
      home: const Synthese4Couleurs(),
      debugShowCheckedModeBanner: false,
    );
  }
}
