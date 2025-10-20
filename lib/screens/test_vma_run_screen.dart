import 'dart:async';
import 'package:flutter/material.dart';
import 'package:natation/services/bay_gps_service.dart';
import 'package:natation/services/bay_vma_service.dart';
import 'package:natation/widgets/bay_speed_indicator.dart';
import 'package:audioplayers/audioplayers.dart';

class TestVmaRunScreen extends StatefulWidget {
  @override
  _TestVmaScreenState createState() => _TestVmaScreenState();
}

class _TestVmaScreenState extends State<TestVmaRunScreen> {
  final vmaService = BayVMAService();
  final gpsService = BayGPSService();

  double vitesseGPS = 0.0;
  int palier = 1;
  String statusMessage = 'Chargement GPS...';
  Timer? _palierTimer;
  Timer? _countdownTimer;
  Timer? _bipTimer;
  int tempsRestant = 0;
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initGPS();
    _startPalierTimer();
  }

  Future<void> _initGPS() async {
    bool granted = await gpsService.handlePermission();
    if (!granted) {
      setState(() {
        statusMessage = 'Permission de localisation refusée';
      });
      return;
    }

    gpsService.getPositionStream()?.listen(
          (pos) {
        setState(() {
          vitesseGPS = pos.speed * 3.6;
          statusMessage = 'Vitesse GPS : ${vitesseGPS.toStringAsFixed(1)} km/h';
        });
      },
      onError: (error) {
        setState(() {
          statusMessage = 'Erreur GPS : $error';
        });
      },
      cancelOnError: true,
    );
  }

  void _startPalierTimer() {
    _palierTimer?.cancel();
    final palierActuel = vmaService.getLevel(palier);
    final duree = palierActuel.duree;
    tempsRestant = duree.inSeconds;
    _startBipTimer(palierActuel.vitesse);

    _palierTimer = Timer.periodic(duree, (_) async {
      setState(() {
        palier++;
        tempsRestant = vmaService.getLevel(palier).duree.inSeconds;
      });
      await player.play(AssetSource('audios/beep.mp3'));
      _startBipTimer(vmaService.getLevel(palier).vitesse);
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (tempsRestant > 0) {
        setState(() => tempsRestant--);
      }
    });
  }

  void _startBipTimer(double vitesseKmH) {
    _bipTimer?.cancel();
    final vitesseMS = vitesseKmH / 3.6;
    final tempsPour20m = 20 / vitesseMS;
    _bipTimer = Timer.periodic(
      Duration(milliseconds: (tempsPour20m * 1000).round()),
          (_) async {
        await player.play(AssetSource('audios/beep.mp3'));
      },
    );
  }

  void _endTest() {
    _palierTimer?.cancel();
    _countdownTimer?.cancel();
    _bipTimer?.cancel();

    final palierAtteint = vmaService.getLevel(palier);
    final vma = palierAtteint.vitesse;

    Navigator.pushNamed(
      context,
      '/result',
      arguments: {
        'palier': palierAtteint.numero,
        'vma': vma,
      },
    );
  }

  @override
  void dispose() {
    _palierTimer?.cancel();
    _countdownTimer?.cancel();
    _bipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palierActuel = vmaService.getLevel(palier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Test VMA"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange, Colors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFFFF3E0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  shadowColor: Colors.orangeAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: BaySpeedIndicator(
                      vitesseCible: palierActuel.vitesse,
                      vitesseGPS: vitesseGPS,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Palier ${palierActuel.numero}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Temps restant : $tempsRestant s',
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 6,
                  ),
                  onPressed: _endTest,
                  icon: const Icon(Icons.flag, color: Colors.white),
                  label: const Text(
                    "Terminer le test",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  statusMessage,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
