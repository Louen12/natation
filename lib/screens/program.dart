import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/exercise_api.dart';
import '../widgets/exercise_capsule.dart';

class ProgramPage extends StatefulWidget {
  final String title;

  const ProgramPage({super.key, required this.title});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  late final Future<List<Exercise>> _future;

  @override
  void initState() {
    super.initState();
    _future = ExerciseApi.fetchExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<Exercise>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <Exercise>[];
          if (items.isEmpty) {
            return const Center(child: Text('Aucun exercice.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Center();
              }
              final ex = items[index - 1];
              return ExercisePill(
                title: ex.name,
                onTap: () {
                  // TODO: navigation vers la page détail selon le type
                  Navigator.of(context).pushNamed('/yoga', arguments: ex);
                },
              );
            },
          );
        },
      ),
    );
  }
}
