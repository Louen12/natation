import 'package:natation/screens/test_vma_screen.dart';

class Exercise {
  int? id;
  String name;
  int reps;
  int steps;
  int rest;
  bool isFinished;


  Exercise({required this.name, required this.reps, required this.steps, required this.rest, required this.isFinished, this.id});

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id : map['id'] ?? null,
      name : map['name'],
      reps: map['reps'],
      steps : map['steps'],
      rest : map['rest'],
      isFinished : map['isFinished'] == 1 ? true : false,
    );


  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      "name": name,
      "reps": reps,
      "steps": steps,
      "rest": rest,
      "isFinished": isFinished ? 1:0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  static dynamic getWidgetFromName(Exercise exercise){
    switch(exercise.name){
      case "MVA":
        return TestVmaScreen();
      case "Pompes":
        return null;
      case "Traction":
        return null;
      case "Yoga":
        return null;
      case "Course":
        return null;
      case "Saut":
        return null;
      case "Gainage":
        return null;
    }
  }
}