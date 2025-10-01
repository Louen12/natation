import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

/// Service capteur.
/// On prend l'accélération SANS gravité (userAccelerometer)
/// puis on calcule la MAGNITUDE (√(x²+y²+z²)) pour être insensible à l'orientation.
/// On applique ensuite filtre passe-bas (exponential moving average).
class SensorService {
  final double _alpha; // proche de 1.0 => plus lisse
  double _lp = 0.0;
  bool _init = false;

  SensorService({double alpha = 0.9}) : _alpha = alpha;

  /// Flux de magnitude filtrée.
  Stream<double> get magnitudeStream =>
      userAccelerometerEventStream().map((e) {
        final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
        if (!_init) {
          _init = true;
          _lp = mag;
          return _lp;
        }
        _lp = _lp * _alpha + mag * (1 - _alpha);
        return _lp;
      });
}
