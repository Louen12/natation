import 'package:flutter/material.dart';

class CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool big;
  final VoidCallback? onTap;

  const CircleButton({
    required this.icon,
    required this.color,
    this.big = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: big ? 80 : 60,
        height: big ? 80 : 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: big ? 40 : 28),
      ),
    );
  }
}
