class Bio {
  final String weight;
  final String size;
  Bio({required this.weight, required this.size});

  factory Bio.fromJson(Map<String, dynamic> json) => Bio(
    weight: json['weight'],
    size: json['size'],
  );
}

class Position {
  final String name;
  final String time;
  final String? rest;
  Position({required this.name, required this.time, this.rest});

  factory Position.fromJson(Map<String, dynamic> json) => Position(
    name: json['name'],
    time: json['time'],
    rest: json['rest'],
  );
}

class Exercice {
  final int id;
  final String name;
  final int? reps;
  final int? steps;
  final String? rest;
  final List<Position>? positions;
  final String? distance;
  final String? timeObjective;
  final String? duration;

  Exercice({
    required this.id,
    required this.name,
    this.reps,
    this.steps,
    this.rest,
    this.positions,
    this.distance,
    this.timeObjective,
    this.duration,
  });

  factory Exercice.fromJson(Map<String, dynamic> json) => Exercice(
    id: json['id'],
    name: json['name'],
    reps: json['reps'],
    steps: json['steps'],
    rest: json['rest'],
    positions: (json['position'] as List?)?.map((e) => Position.fromJson(e)).toList(),
    distance: json['distance'],
    timeObjective: json['time_objective'],
    duration: json['duration'],
  );
}

