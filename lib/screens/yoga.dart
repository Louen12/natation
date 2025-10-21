import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:natation/models/exercise.dart';
import 'package:natation/repositories/exercice_repository.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../widgets/vico_header.dart';

class YogaPositionDto {
  final String name;
  final int timeSeconds; // durée de la position (en secondes)
  final int restSeconds; // repos après la position (en secondes, optionnel)

  const YogaPositionDto({
    required this.name,
    required this.timeSeconds,
    required this.restSeconds,
  });

  factory YogaPositionDto.fromJson(Map<String, dynamic> json) {
    int parseToInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return YogaPositionDto(
      name: (json['name'] ?? '').toString(),
      timeSeconds: parseToInt(json['time']),
      restSeconds: parseToInt(json['rest']),
    );
  }
}

/// DTO représentant l'exercice de yoga (liste des positions)
class YogaExerciseDto {
  final List<YogaPositionDto> positions;

  const YogaExerciseDto({required this.positions});

  factory YogaExerciseDto.fromRootJson(Map<String, dynamic> root) {
    final exercices = root['exercice'];
    if (exercices is List) {
      final yogaEntry = exercices.firstWhere(
        (e) =>
            (e is Map<String, dynamic>) &&
            ((e['name'] == 'Yoga') || (e['position'] != null)),
        orElse: () => const {},
      );
      if (yogaEntry is Map<String, dynamic>) {
        final positions =
            (yogaEntry['position'] as List?)
                ?.map(
                  (p) => YogaPositionDto.fromJson(p as Map<String, dynamic>),
                )
                .toList() ??
            const <YogaPositionDto>[];
        return YogaExerciseDto(positions: positions);
      }
    }
    return const YogaExerciseDto(positions: <YogaPositionDto>[]);
  }

  int get totalPoseSeconds =>
      positions.fold<int>(0, (acc, p) => acc + p.timeSeconds);

  int get maxPoseSeconds => positions.isEmpty
      ? 0
      : positions.map((p) => p.timeSeconds).reduce(math.max);
}

class YogaPage extends StatefulWidget {
  final String title;

  const YogaPage({super.key, required this.title});

  @override
  State<YogaPage> createState() => _YogaPageState();
}

class _YogaPageState extends State<YogaPage> {
  final _repo = ExerciseRepository();

  /// Exercice métier (pour récupérer l'id, etc.) passé par Navigator
  Exercise? exercise;

  /// Données Yoga (positions) chargées depuis le JSON
  YogaExerciseDto? _yoga;
  String? _loadError;

  // Suivi de l'entraînement
  Timer? _tickTimer;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  AccelerometerEvent? _prevAccel;

  bool _isRunning = false;
  bool _isCompleted = false; // évite les doubles appels
  int _currentPoseIndex = -1;
  int _remainingInPose = 0; // secondes restantes pour la pose courante

  // Détection de mouvements brusques
  bool _currentSecondAbrupt = false;
  int _smoothSeconds = 0;
  int _unsmoothSeconds = 0;
  int _abruptEvents = 0;

  // Seuil de variation (m/s^2) entre deux échantillons pour considérer un mouvement brusque
  static const double _dvThreshold = 5.0;

  bool get _supportsAccelerometer =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _loadExercise();
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

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  Future<void> _loadExercise() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/db.json');
      final Map<String, dynamic> root =
          json.decode(jsonStr) as Map<String, dynamic>;
      final parsed = YogaExerciseDto.fromRootJson(root);
      setState(() {
        _yoga = parsed;
        _loadError = null;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Impossible de charger db.json: $e';
      });
    }
  }

  void _startExercise() {
    final ex = _yoga;
    if (ex == null || ex.positions.isEmpty || _isCompleted) return;

    _stopTracking(); // réinitialise si on relance

    setState(() {
      _isRunning = true;
      _currentPoseIndex = 0;
      _remainingInPose = ex.positions[0].timeSeconds;
      _currentSecondAbrupt = false;
      _smoothSeconds = 0;
      _unsmoothSeconds = 0;
      _abruptEvents = 0;
      _prevAccel = null;
    });

    if (_supportsAccelerometer) {
      try {
        _accelSub = accelerometerEvents.listen((event) {
          if (!_isRunning) return;
          final prev = _prevAccel;
          if (prev != null) {
            final dx = event.x - prev.x;
            final dy = event.y - prev.y;
            final dz = event.z - prev.z;
            final dv = math.sqrt(dx * dx + dy * dy + dz * dz);
            if (dv > _dvThreshold) {
              _currentSecondAbrupt = true;
              _abruptEvents++;
            }
          }
          _prevAccel = event;
        });
      } catch (_) {
        _accelSub = null;
      }
    } else {
      _accelSub = null;
    }

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isRunning) return;

      // Comptabilise la seconde courante selon la douceur du mouvement
      if (_currentSecondAbrupt) {
        _unsmoothSeconds++;
      } else {
        _smoothSeconds++;
      }
      _currentSecondAbrupt = false; // reset pour la seconde suivante

      // Avance le temps de la pose
      setState(() {
        _remainingInPose = math.max(0, _remainingInPose - 1);
      });

      if (_remainingInPose <= 0) {
        // Passe à la pose suivante ou termine
        if (_currentPoseIndex + 1 < ex.positions.length) {
          setState(() {
            _currentPoseIndex++;
            _remainingInPose = ex.positions[_currentPoseIndex].timeSeconds;
          });
        } else {
          _finishExercise();
        }
      }
    });
  }

  void _stopTracking() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _accelSub?.cancel();
    _accelSub = null;
  }

  /// Fin d'exercice (appelée automatiquement ou via bouton "Terminer" ou à la fin du timer).
  /// Ne bloque pas l'UI, et évite de pop avant d'afficher le résultat.
  /// Met à jour en BDD le statut "fait" de l'exercice.
  void _finishExercise() {
    if (_isCompleted) return;
    _isCompleted = true;

    _stopTracking();
    setState(() {
      _isRunning = false;
    });

    final total = _smoothSeconds + _unsmoothSeconds;
    final success = total == 0 ? 0.0 : (_smoothSeconds / total) * 100.0;

    // Met à jour la BDD sans bloquer
    final ex = exercise;
    if (ex != null) {
      unawaited(_repo.setDone(ex.id, true));
    } else {
      debugPrint('Impossible de marquer comme fait: exercise == null');
    }

    if (!mounted) return;

    // Affiche le résultat PUIS retourne à la page précédente en signalant le changement
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Résultat de l\'exercice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pourcentage de réussite: ${success.toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Text('Mouvements brusques détectés: $_abruptEvents'),
              const SizedBox(height: 12),
              const Text(
                'Note: plus il y a eu de mouvements brusques, plus le score diminue.',
              ),
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
    ).then((_) {
      if (mounted) {
        Navigator.pop(context, true); // ProgramPage rafraîchira
      }
    });
  }

  String _formatSeconds(int s) {
    final minutes = s ~/ 60;
    final seconds = s % 60;
    if (minutes == 0) return '${seconds}s';
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  Widget _buildBars(YogaExerciseDto yoga) {
    final maxS = math.max(1, yoga.maxPoseSeconds);
    return Column(
      children: [
        for (int i = 0; i < yoga.positions.length; i++)
          _BarRow(
            name: yoga.positions[i].name,
            seconds: yoga.positions[i].timeSeconds,
            portion: yoga.positions[i].timeSeconds / maxS,
            isActive: _isRunning && i == _currentPoseIndex,
            label:
                '${yoga.positions[i].name} — ${_formatSeconds(yoga.positions[i].timeSeconds)}',
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final yoga = _yoga;
    return Scaffold(
      body: Column(
        children: [
          const VicoHeader(
            temps: Duration.zero,
            distance: 0.0,
            showTimes: false,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 36.0, 16.0, 2.0),
            child: Center(
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'DynaPuff',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _loadError != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        const Text(
                          'Assurez-vous que db.json est déclaré comme asset dans pubspec.yaml.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : yoga == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Positions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBars(yoga),
                        const SizedBox(height: 24),
                        _StatusPanel(
                          isRunning: _isRunning,
                          currentPoseName: _currentPoseIndex >= 0
                              ? yoga.positions[_currentPoseIndex].name
                              : '-',
                          remainingSeconds: _remainingInPose,
                          smoothSeconds: _smoothSeconds,
                          unsmoothSeconds: _unsmoothSeconds,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (!_isRunning && !_isCompleted)
                                    ? _startExercise
                                    : null,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Commencer'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isRunning ? _finishExercise : null,
                                icon: const Icon(Icons.stop),
                                label: const Text('Terminer'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String name;
  final int seconds;
  final double portion; // 0..1 proportion de largeur
  final bool isActive;
  final String label;

  const _BarRow({
    required this.name,
    required this.seconds,
    required this.portion,
    required this.isActive,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Colors.grey.shade200;
    final activeColor = isActive ? Colors.blueAccent : Colors.green.shade400;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        final barWidth = (portion.clamp(0.0, 1.0)) * fullWidth;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: barWidth,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final bool isRunning;
  final String currentPoseName;
  final int remainingSeconds;
  final int smoothSeconds;
  final int unsmoothSeconds;

  const _StatusPanel({
    required this.isRunning,
    required this.currentPoseName,
    required this.remainingSeconds,
    required this.smoothSeconds,
    required this.unsmoothSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Statut: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(isRunning ? 'En cours' : 'En attente'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Pose actuelle: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Text(
                  currentPoseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Temps restant: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_formatStatic(remainingSeconds)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Secondes douces: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('$smoothSeconds'),
              const SizedBox(width: 16),
              const Text(
                'Secondes brusques: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('$unsmoothSeconds'),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatStatic(int s) {
    final minutes = s ~/ 60;
    final seconds = s % 60;
    if (minutes == 0) return '${seconds}s';
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
}
