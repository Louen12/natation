
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

  Future<Exercise> insert(Exercise exercise) async {
    exercise.id = await db.insert("exercise", exercise.toMap());
    return exercise;
  }

  Future<List<Exercise>> getAllExercises() async {
    List<Map<String, dynamic>> maps = await db.query('exercise');
    return maps.map(Exercise.fromMap).toList();
  }

  Future fillDatabase() async{
    Exercise a = Exercise(name: "pompe", reps: 4, steps: 5, rest: 10, isFinished: false);
    Exercise b = Exercise(name: "VMA", reps: 3, steps: 6, rest: 10, isFinished: true);
    Exercise c = Exercise(name: "course", reps: 2, steps: 7, rest: 10, isFinished: false);
    insert(a);
    insert(b);
    insert(c);
  }

  Future close() async => db.close();
}
