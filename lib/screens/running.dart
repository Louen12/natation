import 'package:flutter/material.dart';

class RunningScreen extends StatelessWidget {
  const RunningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course à pied'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Bienvenue sur la page 'Course à pied'!\n\nContenu à venir...",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
