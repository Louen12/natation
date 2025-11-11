import 'package:flutter/material.dart';
import 'package:natation/models/exercise.dart';
import 'package:natation/screens/test_vma_home_screen.dart';


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
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[600],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            exercise.reps != null && exercise.steps != null? '${exercise.reps} x ${exercise.steps} ${exercise.name}' : '${exercise.name}',
            style: DefaultTextStyle.of(context)
                .style
                .apply(fontSizeFactor: 1.3),
          ),
          !action ?
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                "/${(exercise.name).toLowerCase()}",
                arguments: exercise,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action ? Colors.blue : Colors.lightGreen,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:  Text('Play'),
          ) :
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              "assets/images/checked.png",
              height: 20,
            ),
          ),
        ],
      ),
    );
  }
}
