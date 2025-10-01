import 'package:flutter/material.dart';

class ExerciseCard extends StatelessWidget {
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
          // Carte avec ClipPath
          ClipPath(
            clipper: ExerciseCardClipper(),
            child: Container(
              padding: const EdgeInsets.all(24),
              height: 220,
              decoration: BoxDecoration(
                color: backgroundColor,
              ),
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (bestTime != null)
                    Column(
                      children: [
                        Text(
                          bestTime!,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'DynaPuff',
                          ),
                        ),
                        const Text(
                          "Best Time",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'DynaPuff',
                          ),
                        ),
                      ],
                    ),
                  if (time != null)
                    Column(
                      children: [
                        Text(
                          time!,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'DynaPuff',
                          ),
                        ),
                        const Text(
                          "Time",
                          style: TextStyle(color: Colors.white , fontFamily: 'DynaPuff'),
                        ),
                      ],
                    ),
                  if (series != null)
                    Column(
                      children: [
                        Text(
                          "$series / $totalSeries",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'DynaPuff',
                          ),
                        ),
                        const Text(
                          "Series",
                          style: TextStyle(color: Colors.white, fontFamily: 'DynaPuff'),
                        ),
                      ],
                    ),
                  if (repos != 0)
                    Column(
                      children: [
                        Text(
                          "$repos",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'DynaPuff',
                          ),
                        ),
                        const Text(
                          "Repos",
                          style: TextStyle(color: Colors.white, fontFamily: 'DynaPuff'),
                        ),
                      ],
                    ),
                  if (repetitions != null)
                    Column(
                      children: [
                        Text(
                          "$repetitions / $totalRepetitions",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'DynaPuff',
                          ),
                        ),
                        const Text(
                          "Reps",
                          style: TextStyle(color: Colors.white, fontFamily: 'DynaPuff'),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
            ),
          ),
          // Images qui débordent (devant la carte)
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
}

class ExerciseCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const radius = 20.0;

    // Point de départ : coin supérieur gauche avec arrondi
    path.moveTo(radius, 0);

    // Côté supérieur droit avec arrondi
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);

    // Côté droit jusqu'au coin inférieur droit avec arrondi
    path.lineTo(size.width, size.height - 40 - radius);
    path.quadraticBezierTo(size.width, size.height - 40, size.width - radius, size.height - 40);

    // Coin inférieur droit qui remonte vers le pic central
    path.quadraticBezierTo(
      size.width * 0.75, // Point de contrôle horizontal
      size.height - 15, // Point de contrôle vertical (remonte)
      size.width * 0.5, // Point final au centre
      size.height, // Hauteur finale (pic vers le bas)
    );

    // Coin inférieur gauche qui remonte vers le pic central
    path.quadraticBezierTo(
      size.width * 0.25, // Point de contrôle horizontal
      size.height - 15, // Point de contrôle vertical (remonte)
      radius, // Point final au coin gauche (avec arrondi)
      size.height - 40, // Hauteur finale (même proportion que le côté droit)
    );

    // Arrondi du coin inférieur gauche
    path.quadraticBezierTo(0, size.height - 40, 0, size.height - 40 - radius);


    // Côté gauche jusqu'au coin supérieur gauche avec arrondi
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);


    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}