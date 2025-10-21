import 'package:flutter/material.dart';
import 'package:natation/services/jump_service.dart';
import 'dart:async'; // pour unawaited
import 'package:natation/repositories/exercice_repository.dart';
import 'package:natation/models/exercise.dart';

class JumpPage extends StatefulWidget {
  final String title;

  const JumpPage({super.key, required this.title});

  @override
  State<JumpPage> createState() => _JumpPageState();
}

class _JumpPageState extends State<JumpPage> {
  final jumpService = JumpService(massKg: 75);

  final int timer = 60000; // temps en ms

  final _repo = ExerciseRepository();
  Exercise? exercise;

  @override
  void initState() {
    super.initState();
    jumpService.events.listen((event) {});
  }

  @override
  void dispose() {
    jumpService.dispose();
    super.dispose();
  }

  void startTimer() {
    int timeLeft = timer;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft <= 0) {
        timer.cancel();
        if (jumpService.isRunning) {
          jumpService.stop();

          final ex = exercise;
          if (ex != null) {
            unawaited(
              _repo.setDone(ex.id, true),
            ); // ✅ marque exo comme fait
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exercice terminé ✅')),
            );
          }
        }
        setState(() {});
      } else {
        timeLeft -= 1000;
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (exercise == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Exercise) {
        exercise = args;
      } else {
        debugPrint('Aucun exercice transmis à JumpPage');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détection de saut'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // compteur total
                      ValueListenableBuilder<int>(
                        valueListenable: jumpService.jumpCount,
                        builder: (_, count, __) => Text(
                          "$count saut${count > 1 ? 's' : ''}",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // chrono
                      const SizedBox(height: 10),
                      Text(
                        jumpService.isRunning
                            ? "Temps restant : ${(timer / 1000).ceil()} s"
                            : "Appuyez sur Démarrer pour commencer",
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 30),

                      // dernières stats globales
                      ValueListenableBuilder(
                        valueListenable: jumpService.stats,
                        builder: (_, stats, __) => Column(
                          children: [
                            Text(
                              "Hauteur max : ${(stats.maxHeightM * 100).toStringAsFixed(1)} cm",
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              "Hauteur moyenne : ${(stats.avgHeightM * 100).toStringAsFixed(1)} cm",
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              "Calories totales : ${stats.totalCaloriesKcal.toStringAsFixed(1)} kcal",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // dernier saut détecté
                      StreamBuilder<JumpEvent>(
                        stream: jumpService.events,
                        builder: (_, snapshot) {
                          if (!snapshot.hasData) {
                            return const Text(
                              "Fais un saut pour commencer !",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            );
                          }
                          final evt = snapshot.data!;
                          return Column(
                            children: [
                              Text(
                                "Dernier airtime : ${evt.airTime.inMilliseconds} ms",
                                style: const TextStyle(fontSize: 22),
                              ),
                              Text(
                                "Takeoff : ${evt.peakTakeoffG.toStringAsFixed(2)} g",
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                "Landing : ${evt.peakLandingG.toStringAsFixed(2)} g",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // bouton start/stop
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (jumpService.isRunning) {
                    jumpService.stop();

                    final ex = exercise;
                    if (ex != null) {
                      unawaited(
                        _repo.setDone(ex.id, true),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exercice terminé ✅')),
                      );
                    }
                  } else {
                    jumpService.start();
                    startTimer();
                  }
                  setState(() {});
                },
                icon: Icon(
                  jumpService.isRunning ? Icons.stop : Icons.play_arrow,
                ),
                label: Text(
                  jumpService.isRunning ? "Stop" : "Démarrer",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
