class Exercise {
  final int id;
  final String name;

  Exercise({required this.id, required this.name});

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? 'Sans nom',
    );
  }
}
