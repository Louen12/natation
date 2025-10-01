import 'package:flutter/material.dart';

class ExerciceWidget extends StatelessWidget {
  final String exercice;
  final bool action;
  const ExerciceWidget({super.key,
    required this.exercice,
    required this.action,
});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.amber[600],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            exercice,
            style: DefaultTextStyle.of(context)
                .style
                .apply(fontSizeFactor: 1.3),
          ),
          ElevatedButton(
            onPressed: () {
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(action ? 'Play' : 'V'),
          ),
        ],
      ),
    );
  }
}
