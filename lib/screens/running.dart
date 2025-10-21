import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:natation/models/exercise.dart';
import 'package:natation/repositories/exercice_repository.dart';

import '../widgets/running_map.dart';
import '../widgets/running_controls.dart';
import '../services/geo_utils.dart';
import '../widgets/vico_header.dart';

class RunningScreen extends StatefulWidget {
  final double? plannedDistanceMeters;
  final int? maxDurationSeconds;
  final String title;

  const RunningScreen({super.key, this.plannedDistanceMeters, this.maxDurationSeconds, required this.title});

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  // Map & tracking

  final _repo = ExerciseRepository();

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _posSub;
  final List<ll.LatLng> _track = [];
  ll.LatLng? _currentLatLng;

  // Timer / chrono
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _running = false;
  bool _paused = false;
  bool _finished = false;
  bool _success = false;

  // Metrics
  double _distanceMeters = 0.0;

  Exercise? exercise;

  // Objectives (defaults if not provided): 5 km in 45 min
  late double _plannedDistanceMeters;
  late int _maxDurationSeconds;

  @override
  void initState() {
    super.initState();
    _initObjectives();
    _ensureLocationReady();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupère l'exercice métier passé via Navigator (pour l'id)
    if (exercise == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Exercise) {
        exercise = args;
      } else {
        debugPrint('Aucun exercice transmis à YogaPage');
      }
    }
  }

  void _initObjectives() {
    _plannedDistanceMeters = widget.plannedDistanceMeters ?? 5000;
    _maxDurationSeconds = widget.maxDurationSeconds ?? 45 * 60;
  }

  Future<void> _ensureLocationReady() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // On ne bloque pas l'UI, mais on affiche une info.
        if (mounted) {
          _showSnack('Veuillez activer la localisation pour le suivi.');
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showSnack('Permission localisation refusée définitivement.');
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      _updatePosition(pos, initial: true);
    } catch (e) {
      // Ignore but inform
      if (mounted) _showSnack('Erreur localisation: $e');
    }
  }

  void _updatePosition(Position pos, {bool initial = false}) {
    final latLng = ll.LatLng(pos.latitude, pos.longitude);
    setState(() {
      _currentLatLng = latLng;
      if (initial) {
        _track.clear();
        _track.add(latLng);
        _distanceMeters = 0;
      } else {
        if (_track.isEmpty) {
          _track.add(latLng);
        } else {
          final last = _track.last;
          final segment = GeoUtils.haversine(last.latitude, last.longitude, latLng.latitude, latLng.longitude);
          if (!segment.isNaN && segment.isFinite && segment < 1000) {
            _distanceMeters += segment;
            _track.add(latLng);
          }
        }
      }
    });

    try {
      _mapController.move(latLng, _mapController.camera.zoom);
    } catch (_) {}
  }

  void _start() {
    if (_running) return;
    setState(() {
      // Réinitialiser si c'était fini
      if (_finished) {
        _elapsed = Duration.zero;
        _distanceMeters = 0.0;
        _track.clear();
        if (_currentLatLng != null) {
          _track.add(_currentLatLng!);
        }
        _finished = false;
        _success = false;
      }
      _running = true;
      _paused = false;
    });

    // Timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
      // Arrêt auto si temps dépassé
      if (_elapsed.inSeconds >= _maxDurationSeconds) {
        _stop(showDialogOnStop: true);
      }
    });

    // Stream position
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 2),
    ).listen((pos) {
      _updatePosition(pos);
    });
  }

  void _pauseResume() {
    if (!_running) return;
    if (_paused) {
      // Resume
      setState(() => _paused = false);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
      });
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 2),
      ).listen((pos) => _updatePosition(pos));
    } else {
      // Pause
      setState(() => _paused = true);
      _timer?.cancel();
      _posSub?.cancel();
    }
  }

  void _stop({bool showDialogOnStop = true}) {
    if (!_running) return;
    setState(() {
      _running = false;
      _paused = false;
    });

    _timer?.cancel();
    _posSub?.cancel();

    final achievedDistance = _distanceMeters >= _plannedDistanceMeters;
    final withinTime = _elapsed.inSeconds <= _maxDurationSeconds;
    final success = achievedDistance && withinTime;
    
    final ex = exercise;
    if (ex != null) {
      unawaited(_repo.setDone(ex.id, true));
      if(success){
        unawaited(_repo.setFailed(ex.id, false));
      }
      else{
        unawaited(_repo.setFailed(ex.id, true));
      }
    } else {
      debugPrint('Impossible de marquer comme fait: exercise == null');
    }

    if (!mounted) return;
    
    // Au lieu d'afficher un dialog, on met à jour l'état
    setState(() {
      _finished = true;
      _success = success;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Support lire params depuis ModalRoute si non fournis
    final args = ModalRoute.of(context)?.settings.arguments;
    if ((args is Map) && (widget.plannedDistanceMeters == null || widget.maxDurationSeconds == null)) {
      _plannedDistanceMeters = (args['distance'] as num?)?.toDouble() ?? _plannedDistanceMeters;
      _maxDurationSeconds = (args['maxTimeSeconds'] as num?)?.toInt() ?? _maxDurationSeconds;
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Map en plein écran
            _buildMap(),
            
            // Header en haut
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: VicoHeader(
                temps: _elapsed,
                distance: _distanceMeters / 1000,
              ),
            ),
            
            // Contrôles en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildControls(),
            ),
            
            // Flèche de retour en bas à gauche (au-dessus du bloc noir)
            Positioned(
              bottom: 120,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 32, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return RunningMap(
      mapController: _mapController,
      track: _track,
      current: _currentLatLng,
    );
  }

  Widget _buildControls() {
    return RunningControls(
      running: _running,
      paused: _paused,
      finished: _finished,
      success: _success,
      onStart: _start,
      onPauseResume: _pauseResume,
      onStop: () => _stop(showDialogOnStop: true),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
