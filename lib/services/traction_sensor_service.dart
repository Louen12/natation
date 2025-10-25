import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

/// Service capteur robuste.
/// 1) Low-pass sur l'accéléromètre pour estimer l'axe gravité (g).
/// 2) Projection de l'accélération utilisateur sur g -> "vertical".
/// 3) Lissage EMA du signal projeté.
class SensorService {
  final double alphaGravity; // 0.90–0.98 (plus haut = plus lisse)
  final double alphaSmooth;  // 0.80–0.95 (plus haut = plus lisse)

  SensorService({this.alphaGravity = 0.95, this.alphaSmooth = 0.90});

  /// Flux de l’accélération VERTICALE lissée (≈ m/s²).
  /// Signe: positif ≈ vers le bas, négatif ≈ vers le haut.
  Stream<double> verticalStream() {
    final ctrl = StreamController<double>();

    // Estimation de la gravité (LPF sur accelerometer)
    double gx = 0, gy = 0, gz = 9.81;
    bool gInit = false;

    // Lissage final du signal projeté
    double vSmooth = 0;
    bool vInit = false;

    StreamSubscription<AccelerometerEvent>? accSub;
    StreamSubscription<UserAccelerometerEvent>? userSub;

    void onListen() {
      accSub = accelerometerEventStream().listen((e) {
        if (!gInit) {
          gx = e.x; gy = e.y; gz = e.z; gInit = true;
        } else {
          gx = gx * alphaGravity + e.x * (1 - alphaGravity);
          gy = gy * alphaGravity + e.y * (1 - alphaGravity);
          gz = gz * alphaGravity + e.z * (1 - alphaGravity);
        }
      });

      userSub = userAccelerometerEventStream().listen((e) {
        final norm = math.sqrt(gx*gx + gy*gy + gz*gz);
        if (norm < 1e-6) return;

        // Axe unitaire vertical (≈ direction de la gravité)
        final ux = gx / norm, uy = gy / norm, uz = gz / norm;

        // Projection de l'accélération utilisateur sur l'axe vertical
        final vertical = e.x * ux + e.y * uy + e.z * uz;

        // Lissage EMA
        if (!vInit) { vSmooth = vertical; vInit = true; }
        else { vSmooth = vSmooth * alphaSmooth + vertical * (1 - alphaSmooth); }

        ctrl.add(vSmooth);
      });
    }

    Future<void> onCancel() async {
      await accSub?.cancel();
      await userSub?.cancel();
    }

    ctrl.onListen = onListen;
    ctrl.onPause  = onCancel;
    ctrl.onCancel = onCancel;

    return ctrl.stream;
  }
}
