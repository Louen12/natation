import 'dart:async';
import 'package:flutter/material.dart';
import 'package:natation/services/bay_gps_service.dart';
import 'package:natation/services/bay_vma_service.dart';
import 'package:natation/widgets/bay_speed_indicator.dart';
import 'package:audioplayers/audioplayers.dart';

class TestVmaScreen extends StatefulWidget {
  @override
  _TestVmaScreenState createState() => _TestVmaScreenState();
}

class _TestVmaScreenState extends State<TestVmaScreen> {
  final vmaService = BayVMAService();
  final gpsService = BayGPSService();

  double vitesseGPS = 0.0;
  int palier = 1;
  String statusMessage = 'Chargement GPS...';
  Timer? _palierTimer;
  Timer? _countdownTimer;
  Timer? _bipTimer; // 🔊 nouveau timer pour les bips 20m
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
          vitesseGPS = pos.speed * 3.6; // m/s -> km/h
          statusMessage =
          'Vitesse GPS : ${vitesseGPS.toStringAsFixed(1)} km/h';
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

    // 🔊 démarre aussi les bips toutes les X secondes pour 20m
    _startBipTimer(palierActuel.vitesse);

    // Timer pour la durée du palier
    _palierTimer = Timer.periodic(duree, (_) async {
      setState(() {
        palier++;
        tempsRestant = vmaService.getLevel(palier).duree.inSeconds;
      });

      // 🔊 bip de changement de palier
      await player.play(AssetSource('audios/beep.mp3'));

      // redémarre les bips 20m pour le nouveau palier
      _startBipTimer(vmaService.getLevel(palier).vitesse);
    });

    // Timer du compte à rebours
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (tempsRestant > 0) {
        setState(() => tempsRestant--);
      }
    });
  }

  // 🔊 Timer spécifique aux bips toutes les X secondes (20m à l’allure cible)
  void _startBipTimer(double vitesseKmH) {
    _bipTimer?.cancel();
    final vitesseMS = vitesseKmH / 3.6;
    final tempsPour20m = 20 / vitesseMS; // secondes

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

    // 👉 Affiche le résultat et retourne à l’accueil
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
      appBar: AppBar(title: Text("Test VMA")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BaySpeedIndicator(
              vitesseCible: palierActuel.vitesse,
              vitesseGPS: vitesseGPS,
            ),
            SizedBox(height: 20),
            Text(
              'Palier ${palierActuel.numero} | Temps restant : $tempsRestant s',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _endTest,
              child: Text("Fin du test"),
            ),
          ],
        ),
      ),
    );
  }
}
