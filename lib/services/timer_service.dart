import 'dart:async';
import 'package:flutter/material.dart';

class TimerService with ChangeNotifier {
  Timer? _timer;
  Duration _duration = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;
  final Duration _targetDuration;
  
  // Callbacks pour les bips
  VoidCallback? _onStartBeep;
  VoidCallback? _onEndBeep;
  VoidCallback? _onTick;

  TimerService({required Duration targetDuration}) : _targetDuration = targetDuration;

  Duration get duration => _duration;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  Duration get remainingTime => _targetDuration - _duration;
  double get progress => _duration.inMilliseconds / _targetDuration.inMilliseconds;

  void setOnStartBeep(VoidCallback callback) {
    _onStartBeep = callback;
  }

  void setOnEndBeep(VoidCallback callback) {
    _onEndBeep = callback;
  }

  void setOnTick(VoidCallback callback) {
    _onTick = callback;
  }

  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    _isPaused = false;
    
    // Bip de démarrage
    _onStartBeep?.call();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _duration = Duration(seconds: _duration.inSeconds + 1);
      _onTick?.call();
      notifyListeners();
      
      // Vérifier si on a atteint la durée cible
      if (_duration >= _targetDuration) {
        stop();
        _onEndBeep?.call();
      }
    });
    
    notifyListeners();
  }

  void pause() {
    if (!_isRunning || _isPaused) return;
    
    _isPaused = true;
    _timer?.cancel();
    notifyListeners();
  }

  void resume() {
    if (!_isRunning || !_isPaused) return;
    
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _duration = Duration(seconds: _duration.inSeconds + 1);
      _onTick?.call();
      notifyListeners();
      
      if (_duration >= _targetDuration) {
        stop();
        _onEndBeep?.call();
      }
    });
    
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isPaused = false;
    notifyListeners();
  }

  void reset() {
    stop();
    _duration = Duration.zero;
    notifyListeners();
  }

  void restart() {
    reset();
    start();
  }

  String get formattedDuration {
    final minutes = _duration.inMinutes;
    final seconds = _duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedRemainingTime {
    final remaining = remainingTime;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
