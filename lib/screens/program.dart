import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/exercise_api.dart';
import '../widgets/exercise_capsule.dart';
import '../repositories/exercice_repository.dart'; // NEW
import '../widgets/vico_header.dart';

class ProgramPage extends StatefulWidget {
  final String title;

  const ProgramPage({super.key, required this.title});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  late Future<List<Exercise>> _future;
  final _repo = ExerciseRepository(); // NEW
  bool _resetting = false; // NEW

  @override
  void initState() {
    super.initState();
    _future = ExerciseApi.fetchExercises();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = ExerciseApi.fetchExercises();
    });
  }

  Future<void> _onResetAll() async {
    setState(() => _resetting = true);
    await _repo.resetAllDone();
    await _refresh();
    if (mounted) setState(() => _resetting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar removed so the title appears under the header
      body: Column(
        children: [
          const VicoHeader(temps: Duration.zero, distance: 0.0, showTimes: false),
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
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Exercise>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? const <Exercise>[];
                if (items.isEmpty) {
                  return const Center(child: Text('Aucun exercice.'));
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 120), // espace bas
                    itemCount: items.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const SizedBox.shrink();
                      }
                      final ex = items[index - 1];

                      return GestureDetector(
                        onTap: () async {
                          final changed = await Navigator.of(context).pushNamed(
                            "/${(ex.name).toLowerCase()}",
                            arguments: ex,
                          );
                          if (changed == true) {
                            await _refresh();
                          }
                        },
                        child: ExercisePill(
                          title: ex.name,
                          completed: ex.isDone,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            onPressed: _resetting ? null : _onResetAll,
            icon: const Icon(Icons.refresh),
            label: Text(_resetting
                ? 'Réinitialisation...'
                : 'Réinitialiser les exercices'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }
}
