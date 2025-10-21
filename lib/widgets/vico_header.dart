import 'package:flutter/material.dart';

class VicoHeader extends StatelessWidget {
  final Duration temps; // temps de course
  final double distance; // distance parcourue en km
  final bool showTimes; // afficher les temps (temps total + temps au km)

  /// Callback optionnel pour gérer le retour (confirmation, etc.).
  /// Si null, on utilisera Navigator.maybePop(context).
  final VoidCallback? onBack;

  const VicoHeader({
    super.key,
    this.temps = Duration.zero,
    this.distance = 0.0,
    this.showTimes = true,
    this.onBack,
  });

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    // Temps formaté
    String tempsStr = _formatDuration(temps);

    // Temps au km (par défaut "-")
    String tempsAuKm = "-";
    if (distance > 0) {
      final secondsPerKm = temps.inSeconds / distance;
      final d = Duration(seconds: secondsPerKm.round());
      tempsAuKm = _formatDuration(d);
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Fond orange
        Padding(
          padding: const EdgeInsets.fromLTRB(30.0, 50.0, 30.0, 0.0),
          child: CustomPaint(
            painter: HeaderPainter(),
            child: Container(
              height: showTimes ? 130.0 : 75.0,
              width: double.infinity,
            ),
          ),
        ),

        // Guépard flottant à gauche
        Positioned(
          left: 10,
          top: 15,
          child: Image.asset("assets/images/guepard.png", height: 110),
        ),

        // Mésange flottante à droite
        Positioned(
          right: 0,
          top: 15,
          child: Image.asset("assets/images/mesange.png", height: 110),
        ),

        // Titre + éventuels temps
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(width: 20),
                Text(
                  "NATH A FOND",
                  style: TextStyle(
                    fontFamily: 'DynaPuff',
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(width: 30),
              ],
            ),
            showTimes
                ? Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _infoWidgetStatic(tempsStr, "Temps"),
                          _infoWidgetStatic(tempsAuKm, "Temps au km"),
                          _infoWidgetStatic(
                            distance.toStringAsFixed(1),
                            "Distance (km)",
                          ),
                        ],
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ],
        ),

        Positioned(
          left: 8,
          top: 8,
          child: SafeArea(
            bottom: false,
            child: Material(
              color: Colors.white.withOpacity(0.85),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Retour',
                onPressed: onBack ?? () => Navigator.maybePop(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _infoWidgetStatic(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'DynaPuff',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontFamily: 'DynaPuff', color: Colors.white),
        ),
      ],
    );
  }
}

class HeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color.fromRGBO(255, 98, 0, 1);

    final path = Path()
      ..moveTo(0, 20)
      ..quadraticBezierTo(0, 0, 20, 0)
      ..lineTo(size.width - 20, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 20)
      ..lineTo(size.width, size.height - 20)
      ..quadraticBezierTo(size.width, size.height, size.width - 10, size.height)
      ..lineTo(5, size.height)
      ..lineTo(size.width / 2, size.height + 40)
      ..lineTo(size.width - 5, size.height)
      ..lineTo(10, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - 20)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
