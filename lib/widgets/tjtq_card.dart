import 'package:flutter/material.dart';
import 'package:natation/models/run_session.dart';

/// Carte d'affichage pour un exercice ou une session de course.
class ExerciseCard extends StatelessWidget {
  // Données optionnelles: session de course ou paramètres d'exercice
  final RunSession? runSession;
  final String title;
  final String? bestTime;
  final String? time;
  final int? repetitions;
  final int? totalRepetitions;
  final int? series;
  final int? totalSeries;
  final int? repos;
  final String? leftImage;
  final String? rightImage;
  final Color backgroundColor;

  const ExerciseCard({
    super.key,
    required this.title,
    this.bestTime,
    this.time,
    this.repetitions,
    this.totalRepetitions,
    this.series,
    this.totalSeries,
    this.repos,
    this.leftImage,
    this.rightImage,
    this.runSession,
    this.backgroundColor = const Color(0xFFFF6200),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Carte principale découpée avec un clipper personnalisé
          ClipPath(
            clipper: ExerciseCardClipper(),
            child: Container(
              padding: const EdgeInsets.all(24),
              height: 240,
              decoration: BoxDecoration(color: backgroundColor),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Titre de la carte
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontFamily: 'DynaPuff',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// Si c’est une session de course, on affiche les stats de course
                  if (runSession != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Distance parcourue en km
                        Column(
                          children: [
                            Text(
                              "${runSession!.distanceKm.toStringAsFixed(2)} km",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'DynaPuff',
                              ),
                            ),
                            const Text(
                              "Distance",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'DynaPuff',
                              ),
                            ),
                          ],
                        ),
                        // Temps écoulé format mm:ss
                        Column(
                          children: [
                            Text(
                              "${runSession!.elapsed.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(runSession!.elapsed.inSeconds.remainder(60)).toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'DynaPuff',
                              ),
                            ),
                            const Text(
                              "Temps",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'DynaPuff',
                              ),
                            ),
                          ],
                        ),
                        // Indicateur de réussite de l'objectif
                        Column(
                          children: [
                            Icon(
                              runSession!.success
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: const Color.fromARGB(255, 255, 255, 255),
                              size: 36,
                            ),
                            const Text(
                              "Objectif",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'DynaPuff',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Description de l'objectif (distance + durée)
                    Text(
                      "Objectif : ${runSession!.plannedDistanceMeters / 1000} km en ${runSession!.maxDurationSeconds ~/ 60} min",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontFamily: 'DynaPuff',
                      ),
                    ),
                  ]
                  /// Sinon on affiche les autres types d’exercices (réps, séries, temps...)
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (bestTime != null)
                          _buildColumn(bestTime!, "Best Time"),
                        if (time != null) _buildColumn(time!, "Time"),
                        if (series != null)
                          _buildColumn("$series / $totalSeries", "Series"),
                        if (repos != null && repos != 0)
                          _buildColumn("$repos", "Repos"),
                        if (repetitions != null)
                          _buildColumn(
                            "$repetitions / $totalRepetitions",
                            "Reps",
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Images décoratives positionnées en dehors de la carte
          if (leftImage != null)
            Positioned(
              top: -70,
              left: -30,
              child: Image.asset(leftImage!, width: 160),
            ),
          if (rightImage != null)
            Positioned(
              top: -70,
              right: -40,
              child: Image.asset(rightImage!, width: 160),
            ),
        ],
      ),
    );
  }

  // Petit helper pour créer une colonne valeur + label
  Widget _buildColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'DynaPuff',
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontFamily: 'DynaPuff'),
        ),
      ],
    );
  }
}

/// Clipper personnalisé pour donner une forme arrondie et une encoche au bas
class ExerciseCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const radius = 20.0;

    // chemin du contour avec coins arrondis et une courbe centrale en bas
    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - 40 - radius);
    path.quadraticBezierTo(
      size.width,
      size.height - 40,
      size.width - radius,
      size.height - 40,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 15,
      size.width * 0.5,
      size.height,
    );
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 15,
      radius,
      size.height - 40,
    );
    path.quadraticBezierTo(0, size.height - 40, 0, size.height - 40 - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
