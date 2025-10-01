import 'dart:async';
import 'package:flutter/material.dart';

class ExerciseCard extends StatefulWidget {
  final String title;
  final String? bestTime;
  final int? repetitions;
  final String? leftImage;
  final String? rightImage;
  final Color backgroundColor;

  const ExerciseCard({
    super.key,
    required this.title,
    this.bestTime,
    this.repetitions,
    this.leftImage,
    this.rightImage,
    this.backgroundColor = const Color(0xFFFF6200),
  });

  @override
  State<ExerciseCard> createState() => ExerciseCardState();
}

class ExerciseCardState extends State<ExerciseCard> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;

  void startTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds++;
      });
    });
    setState(() => _isRunning = true);
  }

  void stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void toggleTimer() {
    if (_isRunning) {
      stopTimer();
    } else {
      startTimer();
    }
  }

  bool get isRunning => _isRunning;

  String get formattedTime {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: ExerciseCardClipper(),
            child: Container(
              padding: const EdgeInsets.all(24),
              height: 220,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
              ),
              child: Column(
                children: [
                  Text(
                    widget.title,
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
                      if (widget.bestTime != null)
                        Column(
                          children: [
                            Text(widget.bestTime!,
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'DynaPuff')),
                            const Text("Best Time",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'DynaPuff')),
                          ],
                        ),
                      Column(
                        children: [
                          Text(
                            formattedTime,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'DynaPuff'),
                          ),
                          const Text("Time",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'DynaPuff')),
                        ],
                      ),
                      if (widget.repetitions != null)
                        Column(
                          children: [
                            Text("${widget.repetitions}",
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'DynaPuff')),
                            const Text("Reps",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'DynaPuff')),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (widget.leftImage != null)
            Positioned(
              top: -70,
              left: -30,
              child: Image.asset(widget.leftImage!, width: 160),
            ),
          if (widget.rightImage != null)
            Positioned(
              top: -70,
              right: -40,
              child: Image.asset(widget.rightImage!, width: 160),
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