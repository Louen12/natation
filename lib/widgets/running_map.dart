import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

class RunningMap extends StatelessWidget {
  final MapController mapController;
  final List<ll.LatLng> track;
  final ll.LatLng? current;

  const RunningMap({
    super.key,
    required this.mapController,
    required this.track,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final center = current ?? const ll.LatLng(48.108436, -1.648091);
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16,
        interactionOptions: const InteractionOptions(flags: ~InteractiveFlag.rotate),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.natation',
        ),
        if (track.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(points: track, strokeWidth: 4, color: Colors.blueAccent),
            ],
          ),
        if (current != null)
          MarkerLayer(
            markers: [
              Marker(
                point: current!,
                width: 30,
                height: 30,
                child: const Icon(Icons.my_location, color: Colors.red, size: 32),
              ),
            ],
          ),
      ],
    );
  }
}
