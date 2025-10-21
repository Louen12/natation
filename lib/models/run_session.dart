import 'package:latlong2/latlong.dart' as ll;

class RunSession {
  final double plannedDistanceMeters;
  final int maxDurationSeconds;
  final double distanceMeters;
  final Duration elapsed;
  final List<ll.LatLng> track;

  const RunSession({
    required this.plannedDistanceMeters,
    required this.maxDurationSeconds,
    required this.distanceMeters,
    required this.elapsed,
    required this.track,
  });

  double get distanceKm => distanceMeters / 1000.0;
  bool get achievedDistance => distanceMeters >= plannedDistanceMeters;
  bool get withinTime => elapsed.inSeconds <= maxDurationSeconds;
  bool get success => achievedDistance && withinTime;
}
