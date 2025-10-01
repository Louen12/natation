import 'package:flutter/material.dart';
import 'package:natation/models/exercise.dart';

class ExerciseWidget extends StatelessWidget {
  final Exercise exercise;
  final bool action;
  const ExerciseWidget({super.key,
    required this.exercise,
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
            '${exercise.reps} x ${exercise.steps} ${exercise.name}',
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
