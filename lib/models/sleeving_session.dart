class SleevingSession {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final int repetitions;
  final int targetRepetitions;
  final Duration averageHoldTime;
  final String? notes;

  SleevingSession({
    this.id,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.repetitions,
    required this.targetRepetitions,
    required this.averageHoldTime,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'duration': duration.inMilliseconds,
      'repetitions': repetitions,
      'target_repetitions': targetRepetitions,
      'average_hold_time': averageHoldTime.inMilliseconds,
      'notes': notes,
    };
  }

  factory SleevingSession.fromMap(Map<String, dynamic> map) {
    return SleevingSession(
      id: map['id'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time']),
      endTime: map['end_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'])
          : null,
      duration: Duration(milliseconds: map['duration']),
      repetitions: map['repetitions'],
      targetRepetitions: map['target_repetitions'] ?? 8,
      averageHoldTime: Duration(milliseconds: map['average_hold_time'] ?? 0),
      notes: map['notes'],
    );
  }

  SleevingSession copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    int? repetitions,
    int? targetRepetitions,
    Duration? averageHoldTime,
    String? notes,
  }) {
    return SleevingSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      repetitions: repetitions ?? this.repetitions,
      targetRepetitions: targetRepetitions ?? this.targetRepetitions,
      averageHoldTime: averageHoldTime ?? this.averageHoldTime,
      notes: notes ?? this.notes,
    );
  }
}
