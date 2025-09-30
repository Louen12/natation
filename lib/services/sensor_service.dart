import 'package:sensors_plus/sensors_plus.dart';
import '../logic/lowpass_filter.dart';

class SensorService {
  final _filter = LowPassFilter(alpha: 0.9);

  // Flux de l'accélération filtrée sur l'axe Z
  Stream<double> get zStream =>
      accelerometerEvents.map((e) => _filter.next(e.z));
}
