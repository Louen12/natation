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

  void resetTimer() {
    _timer?.cancel();
    setState(() {
      _elapsedSeconds = 0;
      _isRunning = false;
    });
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: ExerciseCardClipper(),
            child: Container(
              padding: const EdgeInsets.all(24),
              height: 200,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontFamily: 'DynaPuff',
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (widget.bestTime != null)
                        Column(
                          children: [
                            Text(
                              widget.bestTime!,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w500,
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
                      Column(
                        children: [
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontFamily: 'DynaPuff',
                            ),
                          ),
                          const Text(
                            "Time",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'DynaPuff',
                            ),
                          ),
                        ],
                      ),
                      if (widget.repetitions != null)
                        Column(
                          children: [
                            Text(
                              "${widget.repetitions}",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'DynaPuff',
                              ),
                            ),
                            const Text(
                              "Reps",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'DynaPuff',
                              ),
                            ),
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
              left: -40,
              child: Image.asset(widget.leftImage!, width: 180),
            ),
          if (widget.rightImage != null)
            Positioned(
              top: -70,
              right: -40,
              child: Image.asset(widget.rightImage!, width: 180),
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

    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);

    path.lineTo(size.width, size.height - 40 - radius);
    path.quadraticBezierTo(
        size.width, size.height - 40, size.width - radius, size.height - 40);

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
