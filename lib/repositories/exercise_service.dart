
import 'package:natation/models/exercise.dart';
import 'package:sqflite/sqflite.dart';


class ExerciseProvider {
  late Database db;

  Future open(String path) async {
    databaseFactory.deleteDatabase(path);
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
          create table exercise ( 
            id integer primary key autoincrement, 
            name text not null,
            reps integer not null,
            steps integer not null,
            rest integer not null,
            isFinished integer not null)
          ''');
        });
    print('Database opened at path: $path');
  }

  /*Future<Exercise> insert(Exercise exercise) async {
    exercise.id = await db.insert("exercise", exercise.toMap());
    return exercise;
  }*/

  Future<List<Exercise>> getAllExercises() async {
    List<Map<String, dynamic>> maps = await db.query('exercise');
    return maps.map(Exercise.fromMap).toList();
  }

 /* Future fillDatabase() async{
    Exercise a = Exercise(id:1, name: "pompe", reps: 4, steps: 5, rest: 10, isDone: false);
    Exercise b = Exercise(id:2, name: "VMA", reps: 3, steps: 6, rest: 10, isDone: true);
    Exercise c = Exercise(id:3, name: "course", reps: 2, steps: 7, rest: 10, isDone: false);
    insert(a);
    insert(b);
    insert(c);
  }*/

  Future close() async => db.close();
}
