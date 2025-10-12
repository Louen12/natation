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
      isFinished : map['isFinished'],
    );


  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      "name": name,
      "reps": reps,
      "steps": steps,
      "rest": rest,
      "isFinished": isFinished
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}