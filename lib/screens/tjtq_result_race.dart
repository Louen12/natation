import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:natation/widgets/tjtq_card.dart';
import 'package:natation/models/run_session.dart'; // ton modèle RunSession

class RunResultPage extends StatelessWidget {
  final RunSession runSession;

  const RunResultPage({super.key, required this.runSession});

  @override
  Widget build(BuildContext context) {
    final parcours = runSession.track;

    return Scaffold(
      body: Stack(
        children: [
          /// --- OpenStreetMap ---
          FlutterMap(
            options: MapOptions(
              initialCenter: parcours.isNotEmpty ? parcours[0] : LatLng(0, 0),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.app",
              ),
              if (parcours.isNotEmpty)
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
              title: "COURSE TERMINÉE",
              runSession: runSession,
              // time:
              //     "${runSession.elapsed.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(runSession.elapsed.inSeconds.remainder(60)).toString().padLeft(2, '0')}",
              // bestTime: "Objectif: ${runSession.maxDurationSeconds ~/ 60}:${(runSession.maxDurationSeconds % 60).toString().padLeft(2, '0')}",
              // repetitions: 1,
              // leftImage: "assets/cheetah.png",
              // rightImage: "assets/bird.png",
            ),
          ),
        ],
      ),
    );
  }
}
