import 'package:flutter/material.dart';
import '../repositories/jump_repository.dart';
import '../repositories/sleeving_repository.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final JumpRepository _jumpRepository = JumpRepository();
  final SleevingRepository _sleevingRepository = SleevingRepository();
  
  Map<String, dynamic>? _jumpStats;
  Map<String, dynamic>? _sleevingStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final jumpStats = await _jumpRepository.getStatistics();
      final sleevingStats = await _sleevingRepository.getStatistics();
      
      setState(() {
        _jumpStats = jumpStats;
        _sleevingStats = sleevingStats;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 219, 219, 219),
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: const Color(0xFFFF6200),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJumpStatsCard(),
                  const SizedBox(height: 16),
                  _buildSleevingStatsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildJumpStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sauts Verticaux',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6200),
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Sessions totales', '${_jumpStats?['totalSessions'] ?? 0}'),
            _buildStatRow('Sauts totaux', '${_jumpStats?['totalRepetitions'] ?? 0}'),
            _buildStatRow('Calories brûlées', '${(_jumpStats?['totalCalories'] ?? 0).toStringAsFixed(1)} kcal'),
            _buildStatRow('Hauteur max', '${(_jumpStats?['maxHeight'] ?? 0).toStringAsFixed(1)} cm'),
            _buildStatRow('Puissance moyenne', '${(_jumpStats?['averagePower'] ?? 0).toStringAsFixed(2)} g'),
          ],
        ),
      ),
    );
  }

  Widget _buildSleevingStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gainage Latéral',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6200),
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Sessions totales', '${_sleevingStats?['totalSessions'] ?? 0}'),
            _buildStatRow('Répétitions totales', '${_sleevingStats?['totalRepetitions'] ?? 0}'),
            _buildStatRow('Sessions complétées', '${_sleevingStats?['completedSessions'] ?? 0}'),
            _buildStatRow('Temps moyen par répétition', '${_formatDuration(_sleevingStats?['averageHoldTime'] ?? Duration.zero)}'),
            _buildStatRow('Meilleure session', '${_sleevingStats?['bestRepetitions'] ?? 0} répétitions'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
