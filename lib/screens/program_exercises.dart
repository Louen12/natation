import 'package:flutter/material.dart';
import 'package:natation/models/exercise.dart';
import 'package:natation/widgets/vico_header.dart';

import '../services/exercise_api.dart';
import '../widgets/exercise_widget.dart';

class ProgramExercises extends StatefulWidget {
  const ProgramExercises({Key? key}) : super(key: key);

  @override
  _ProgramExercisesState createState() => _ProgramExercisesState();
}

class _ProgramExercisesState extends State<ProgramExercises> {
  late Future<List<Exercise>> exercisesFuture;

  double _distanceMeters = 0.0;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    exercisesFuture = _initializeDatabaseAndGetExercises();
  }
  Future<List<Exercise>> _initializeDatabaseAndGetExercises() async {
    return ExerciseApi.fetchExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder<List<Exercise>>(
          future: exercisesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No users found'));
            } else {
              return Column(
                  children: [
                    Text('Programme'),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: VicoHeader(
                        temps: _elapsed,
                        distance: _distanceMeters / 1000,
                        showTimes: false,
                      ),
                    ),
                    Expanded(child:
                      ListView.builder(
                        scrollDirection:  Axis.vertical,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          Exercise exercise = snapshot.data![index];
                          return ExerciseWidget(
                            exercise: exercise,
                            action: exercise.isDone
                          );
                        },
                      ),
                  )
                ]
              );
            }
          }
      )
    );
  }
}
