import 'package:flutter/material.dart';

class ResultVmaScreen extends StatelessWidget {
  const ResultVmaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final palier = args['palier'];
    final vma = args['vma'];

    return Scaffold(
      appBar: AppBar(title: const Text("Résultat du test")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Palier atteint : $palier", style: TextStyle(fontSize: 22)),
            Text("VMA estimée : ${vma.toStringAsFixed(1)} km/h",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text("Retour à l'accueil"),
            )
          ],
        ),
      ),
    );
  }
}
