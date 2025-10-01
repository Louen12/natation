import 'package:geolocator/geolocator.dart';

class BayGPSService {
  Future<bool> handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permission refusée
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions définitivement refusées
      return false;
    }

    return true;
  }

  Stream<Position>? getPositionStream() {
    // On vérifie les permissions avant de retourner le stream
    return Stream.fromFuture(handlePermission()).asyncExpand((granted) {
      if (granted) {
        return Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        );
      } else {
        // Si pas de permission, on retourne un stream vide
        return const Stream.empty();
      }
    });
  }
}
