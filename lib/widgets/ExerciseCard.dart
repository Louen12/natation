import 'package:flutter/material.dart';

class ExerciseCard extends StatelessWidget {
  final String title;
  final String? bestTime;
  final String? time;
  final int? repetitions;
  final String? leftImage;
  final String? rightImage;
  final Color backgroundColor;

  const ExerciseCard({
    super.key,
    required this.title,
    this.bestTime,
    this.time,
    this.repetitions,
    this.leftImage,
    this.rightImage,
    this.backgroundColor = const Color(0xFFFF6200),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          if (leftImage != null)
            Positioned(
              top: -10,
              left: -20,
              child: Image.asset(leftImage!, width: 120),
            ),
          if (rightImage != null)
            Positioned(
              top: 0,
              right: -20,
              child: Image.asset(rightImage!, width: 120),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontFamily: 'DynaPuff',
                  fontWeight: FontWeight.bold,
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                            fontSize: 22,
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
                  if (repetitions != null)
                    Column(
                      children: [
                        Text(
                          "$repetitions",
                          style: const TextStyle(
                            fontSize: 22,
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
        ],
      ),
    );
  }
}
