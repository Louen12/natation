import 'package:flutter/services.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Bip de démarrage
  Future<void> playStartBeep() async {
    try {
      // Utiliser le bip système ou un fichier audio
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      print('Erreur lors de la lecture du bip de démarrage: $e');
    }
  }

  // Bip de fin
  Future<void> playEndBeep() async {
    try {
      // Bip plus long pour la fin
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      print('Erreur lors de la lecture du bip de fin: $e');
    }
  }

  // Bip de tick (optionnel)
  Future<void> playTickBeep() async {
    try {
      // Bip plus discret pour les ticks
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      print('Erreur lors de la lecture du bip de tick: $e');
    }
  }

  // Méthode pour jouer un fichier audio personnalisé (utilise les bips système)
  Future<void> playCustomSound(String assetPath) async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      print('Erreur lors de la lecture du son personnalisé: $e');
    }
  }

  void dispose() {
    // Pas de ressources à libérer pour les bips système
  }
}
