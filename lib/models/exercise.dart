class Exercise {
  final int id;
  final String name;

  final int? reps; // Pompes / Gainage
  final int? steps; // Pompes / Traction
  final int? rest; // sec
  final double? distance; // km
  final int? timeObjective; // sec
  final int? duration; // sec
  final int? jumpNumber; // 20
  final int? heightObjective; // cm
  final int? time; // sec
  final String? type;

  Exercise({
    required this.id,
    required this.name,
    this.reps,
    this.steps,
    this.rest,
    this.distance,
    this.timeObjective,
    this.duration,
    this.jumpNumber,
    this.heightObjective,
    this.time,
    this.type,
  });

  // Helpers de parsing
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String && v.trim().isNotEmpty) return int.tryParse(v);
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String && v.trim().isNotEmpty) return double.tryParse(v);
    return null;
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: _toInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      reps: _toInt(json['reps']),
      steps: _toInt(json['steps']),
      rest: _toInt(json['rest']),
      distance: _toDouble(json['distance']),
      timeObjective: _toInt(json['time_objective']),
      duration: _toInt(json['duration']),
      jumpNumber: _toInt(json['jump_number']),
      heightObjective: _toInt(json['height_objective']),
      time: _toInt(json['time']),
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'reps': reps,
    'steps': steps,
    'rest': rest,
    'distance': distance,
    'time_objective': timeObjective,
    'duration': duration,
    'jump_number': jumpNumber,
    'height_objective': heightObjective,
    'time': time,
    'type': type,
  };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
    id: map['id'] as int,
    name: map['name'] as String,
    reps: map['reps'] as int?,
    steps: map['steps'] as int?,
    rest: map['rest'] as int?,
    distance: (map['distance'] as num?)?.toDouble(),
    timeObjective: map['time_objective'] as int?,
    duration: map['duration'] as int?,
    jumpNumber: map['jump_number'] as int?,
    heightObjective: map['height_objective'] as int?,
    time: map['time'] as int?,
    type: map['type'] as String?,
  );
}
