class User {
  final String id;
  final String name;
  final String? club;
  final int age;
  final String? avatarUrl;
  final Map<String, Duration> bestTimes;

  const User({
    required this.id,
    required this.name,
    this.club,
    required this.age,
    this.avatarUrl,
    this.bestTimes = const {},
  });
}

extension FormatDuration on Duration {
  String toMmSsCenti() {
    final totalHundreds = inMilliseconds ~/ 10;
    final minutes = totalHundreds ~/ 6000;
    final seconds = (totalHundreds % 6000) ~/ 100;
    final hundreds = totalHundreds % 100;
    if (minutes > 0) {
      return '${minutes.toString().padLeft(1,'0')}:${seconds.toString().padLeft(2,'0')}.${hundreds.toString().padLeft(2,'0')}';
    }
    return '${seconds.toString().padLeft(1,'0')}.${hundreds.toString().padLeft(2,'0')}';
  }
}

const sampleUser = User(
  id: 'U1',
  name: 'Marc Lebreton',
  club: 'Rennes',
  age: 24,
  bestTimes: {
    '50 NL': Duration(seconds: 24, milliseconds: 85),
    '100 NL': Duration(minutes: 0, seconds: 52, milliseconds: 40),
    '200 4N': Duration(minutes: 2, seconds: 15, milliseconds: 30),
  },
);

