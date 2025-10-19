import 'package:flutter/material.dart';
import 'package:natation/models/exercise.dart';
import 'package:natation/repositories/exercise_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../widgets/exercise_widget.dart';

class ProgramExercises extends StatefulWidget {
  const ProgramExercises({Key? key}) : super(key: key);

  @override
  _ProgramExercisesState createState() => _ProgramExercisesState();
}

class _ProgramExercisesState extends State<ProgramExercises> {
  final List<String> activity = <String>['Pompe', 'Traction', 'Abdo'];
  final List<int> colorCodes = <int>[600, 500, 100];

  final List<int> repetition = <int>[4, 5, 3];

  final List<int> serie = <int>[10, 5, 20];

  late Future<List<Exercise>> exercisesFuture;

  @override
  void initState() {
    super.initState();
    exercisesFuture = _initializeDatabaseAndGetExercises();
  }
  Future<List<Exercise>> _initializeDatabaseAndGetExercises() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'user.db');
    ExerciseProvider userProvider = ExerciseProvider();
    await userProvider.open(path);
    await userProvider.fillDatabase();
    return userProvider.getAllExercises();
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
                    Text('Header'),
                    Expanded(child:
                      ListView.builder(
                        scrollDirection:  Axis.vertical,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          Exercise exercise = snapshot.data![index];
                          return ExerciseWidget(
                            exercise: exercise,
                            action: exercise.isFinished
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
