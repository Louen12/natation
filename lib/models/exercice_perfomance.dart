class ExercisePerformance {
  final int? id;
  final int exerciseId;
  final DateTime date;
  final int repetitions;
  final Duration duration;
  final Duration averageHoldTime;

  ExercisePerformance({
    this.id,
    required this.exerciseId,
    required this.date,
    required this.repetitions,
    required this.duration,
    required this.averageHoldTime,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exercise_id': exerciseId,
      'date': date.toIso8601String(),
      'repetitions': repetitions,
      'duration': duration.inSeconds,
      'average_hold_time': averageHoldTime.inSeconds,
    };
  }

  factory ExercisePerformance.fromMap(Map<String, dynamic> map) {
    return ExercisePerformance(
      id: map['id'],
      exerciseId: map['exercise_id'],
      date: DateTime.parse(map['date']),
      repetitions: map['repetitions'],
      duration: Duration(seconds: map['duration']),
      averageHoldTime: Duration(seconds: map['average_hold_time']),
    );
  }
}
