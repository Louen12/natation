enum ExerciseType { pushUps, pullUps }

extension ExerciseTypeX on ExerciseType {
  String get label => this == ExerciseType.pushUps ? 'Pompes' : 'Tractions';
}
