import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // Callback pour notifier les changements d'état
  Function()? _onStateChanged;

  bool get isSpeaking => _isSpeaking;

  void setOnStateChanged(Function() callback) {
    _onStateChanged = callback;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configuration pour une voix féminine naturelle
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setSpeechRate(0.5); // Vitesse normale
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(0.8); // Plus aigu pour une voix féminine

    // Essayer de sélectionner une voix française de qualité
    var voices = await _flutterTts.getVoices;
    if (voices.isNotEmpty) {
      // Chercher une voix française (priorité aux voix premium)
      var bestFrenchFemaleVoice = voices.firstWhere(
        (voice) =>
            voice['locale'] == 'fr-FR' &&
            (voice['name'].toString().toLowerCase().contains('premium') ||
                voice['name'].toString().toLowerCase().contains('enhanced') ||
                voice['name'].toString().toLowerCase().contains('neural') ||
                voice['name'].toString().toLowerCase().contains('female') ||
                voice['name'].toString().toLowerCase().contains('femme') ||
                voice['name'].toString().toLowerCase().contains('feminin')),
        orElse: () => voices.firstWhere(
          (voice) =>
              voice['locale'] == 'fr-FR' &&
              !voice['name'].toString().toLowerCase().contains('male') &&
              !voice['name'].toString().toLowerCase().contains('homme'),
          orElse: () => voices.firstWhere(
            (voice) => voice['locale'] == 'fr-FR',
            orElse: () => voices.first,
          ),
        ),
      );
      await _flutterTts.setVoice({
        "name": bestFrenchFemaleVoice['name'],
        "locale": bestFrenchFemaleVoice['locale'],
      });
    }

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _onStateChanged?.call();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _onStateChanged?.call();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      _onStateChanged?.call();
      print("Erreur TTS: $msg");
    });

    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isSpeaking) {
      await stop();
    }

    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
      _onStateChanged?.call();
    }
  }

  Future<void> pause() async {
    if (_isSpeaking) {
      await _flutterTts.pause();
    }
  }

  Future<void> resume() async {
    if (_isSpeaking) {
      await _flutterTts.speak("");
    }
  }

  // Méthode pour obtenir toutes les voix disponibles
  Future<List<Map<String, String>>> getAvailableVoices() async {
    var voices = await _flutterTts.getVoices;
    return voices.cast<Map<String, String>>();
  }

  // Méthode pour changer de voix
  Future<void> setVoice(Map<String, String> voice) async {
    await _flutterTts.setVoice(voice);
  }

  // Méthode pour ajuster les paramètres de voix
  Future<void> adjustVoiceSettings({
    double? speechRate,
    double? pitch,
    double? volume,
  }) async {
    if (speechRate != null) await _flutterTts.setSpeechRate(speechRate);
    if (pitch != null) await _flutterTts.setPitch(pitch);
    if (volume != null) await _flutterTts.setVolume(volume);
  }

  Future<void> dispose() async {
    await _flutterTts.stop();
    _isInitialized = false;
  }
}
