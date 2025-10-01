class Position {
  final int? id;
  final int exerciseId;
  final String name;
  final int? time;
  final int? rest;

  Position({
    this.id,
    required this.exerciseId,
    required this.name,
    this.time,
    this.rest,
  });

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String && v.trim().isNotEmpty) return int.tryParse(v);
    return null;
  }

  factory Position.fromJson(
    Map<String, dynamic> json, {
    required int exerciseId,
  }) {
    return Position(
      exerciseId: exerciseId,
      name: json['name']?.toString() ?? '',
      time: _toInt(json['time']),
      rest: _toInt(json['rest']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'exercise_id': exerciseId,
    'name': name,
    'time': time,
    'rest': rest,
  };

  factory Position.fromMap(Map<String, dynamic> map) => Position(
    id: map['id'] as int?,
    exerciseId: map['exercise_id'] as int,
    name: map['name'] as String,
    time: map['time'] as int?,
    rest: map['rest'] as int?,
  );
}
