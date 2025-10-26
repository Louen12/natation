import 'package:flutter/material.dart';

class CongratsPopup extends StatelessWidget {
  final String title;
  final int stars;
  final String buttonText;
  final VoidCallback onClose;

  const CongratsPopup({
    super.key,
    this.title = "GOOD JOB!",
    this.stars = 4,
    this.buttonText = "TJTQ",
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),

          // Image
          Image.asset(
            "assets/images/success.gif",
            height: 80,
          ),
          const SizedBox(height: 16),

          // Titre
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'DynaPuff',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Étoiles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < stars ? Icons.star : Icons.star_border,
                color: Colors.yellow[700],
                size: 36,
              );
            }),
          ),
          const SizedBox(height: 24),

          // Bouton rond orange
          GestureDetector(
            onTap: onClose,
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'DynaPuff',
                    fontSize: 16,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
