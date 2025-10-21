class JumpSession {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final int repetitions;
  final double totalHeight;
  final double maxHeight;
  final double totalCalories;
  final double averagePower;
  final String? notes;

  JumpSession({
    this.id,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.repetitions,
    required this.totalHeight,
    required this.maxHeight,
    required this.totalCalories,
    required this.averagePower,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'duration': duration.inMilliseconds,
      'repetitions': repetitions,
      'total_height': totalHeight,
      'max_height': maxHeight,
      'total_calories': totalCalories,
      'average_power': averagePower,
      'notes': notes,
    };
  }

  factory JumpSession.fromMap(Map<String, dynamic> map) {
    return JumpSession(
      id: map['id'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time']),
      endTime: map['end_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'])
          : null,
      duration: Duration(milliseconds: map['duration']),
      repetitions: map['repetitions'],
      totalHeight: map['total_height'] ?? 0.0,
      maxHeight: map['max_height'] ?? 0.0,
      totalCalories: map['total_calories'] ?? 0.0,
      averagePower: map['average_power'] ?? 0.0,
      notes: map['notes'],
    );
  }

  JumpSession copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    int? repetitions,
    double? totalHeight,
    double? maxHeight,
    double? totalCalories,
    double? averagePower,
    String? notes,
  }) {
    return JumpSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      repetitions: repetitions ?? this.repetitions,
      totalHeight: totalHeight ?? this.totalHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      totalCalories: totalCalories ?? this.totalCalories,
      averagePower: averagePower ?? this.averagePower,
      notes: notes ?? this.notes,
    );
  }
}
