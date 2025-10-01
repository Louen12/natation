import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:natation/widgets/tjtq_card.dart';

class RunResultPage extends StatelessWidget {
  const RunResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemple de coordonnées du parcours
    final List<LatLng> parcours = [
      LatLng(48.111338, -1.68002), // Rennes
      LatLng(48.11321, -1.6745),
      LatLng(48.11501, -1.6720),
      LatLng(48.1163, -1.6781),
      LatLng(48.1139, -1.6820),
    ];

    return Scaffold(
      body: Stack(
        children: [
          /// --- OpenStreetMap ---
          FlutterMap(
            options: MapOptions(initialCenter: parcours[0], initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.app",
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: parcours,
                    strokeWidth: 6,
                    color: Colors.black,
                  ),
                ],
              ),
            ],
          ),

          /// --- Carte d'infos (au-dessus de la map) ---
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: ExerciseCard(
              title: "NATH A FOND",
              time: "59:50",
              bestTime: "29:25",
              repetitions: 2,
              leftImage: "assets/cheetah.png",
              rightImage: "assets/bird.png",
            ),
          ),
        ],
      ),
    );
  }
}
