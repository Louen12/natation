import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../widgets/running_map.dart';
import '../widgets/running_controls.dart';
import '../widgets/stat_chip.dart';
import '../services/geo_utils.dart';

class RunningScreen extends StatefulWidget {
  final double? plannedDistanceMeters;
  final int? maxDurationSeconds;

  const RunningScreen({super.key, this.plannedDistanceMeters, this.maxDurationSeconds});

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  // Map & tracking
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _posSub;
  final List<ll.LatLng> _track = [];
  ll.LatLng? _currentLatLng;

  // Timer / chrono
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _running = false;
  bool _paused = false;

  // Metrics
  double _distanceMeters = 0.0;

  // Objectives (defaults if not provided): 5 km in 45 min
  late double _plannedDistanceMeters;
  late int _maxDurationSeconds;

  @override
  void initState() {
    super.initState();
    _initObjectives();
    _ensureLocationReady();
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

    if (!mounted) return;
    if (showDialogOnStop) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(success ? 'Objectif atteint 🎉' : 'Objectif non atteint'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Distance prévue: ${(_plannedDistanceMeters / 1000).toStringAsFixed(2)} km'),
                Text('Distance parcourue: ${( _distanceMeters / 1000).toStringAsFixed(2)} km'),
                const SizedBox(height: 8),
                Text('Temps max: ${GeoUtils.formatDuration(Duration(seconds: _maxDurationSeconds))}'),
                Text('Temps réalisé: ${GeoUtils.formatDuration(_elapsed)}'),
                Text('Coordonées : ${_track}')
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
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
      appBar: AppBar(
        title: const Text('Course à pied'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMap(),
          ),
          _buildStatsPanel(),
          const SizedBox(height: 8),
          _buildControls(),
          const SizedBox(height: 12),
        ],
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

  Widget _buildStatsPanel() {
    final km = _distanceMeters / 1000;
    final remaining = (_plannedDistanceMeters - _distanceMeters).clamp(0, double.infinity);
    final remainingKm = remaining / 1000;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey.shade100, boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 4, offset: const Offset(0, -2)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              StatChip(label: 'Distance', value: '${km.toStringAsFixed(2)} km'),
              StatChip(label: 'Temps', value: GeoUtils.formatDuration(_elapsed)),
              StatChip(label: 'Reste', value: '${remainingKm.toStringAsFixed(2)} km'),
              StatChip(label: 'Temps max', value: GeoUtils.formatDuration(Duration(seconds: _maxDurationSeconds))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return RunningControls(
      running: _running,
      paused: _paused,
      onStart: _start,
      onPauseResume: _pauseResume,
      onStop: () => _stop(showDialogOnStop: true),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
