import 'package:flutter/material.dart';
import '../models/exercice.dart';
import '../utils/exercice_loader.dart';
import '../widgets/vico_header.dart';

class TrainingListScreen extends StatelessWidget {
  const TrainingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programme d\'entraînement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<EntrainementData>(
        future: loadEntrainementFromAsset('entrainement.json'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur de chargement: \n${snapshot.error}'));
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Aucune donnée disponible.'));
          }
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFE5C7B6),
            ),
            width: double.infinity,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const VicoHeader(
                      temps: Duration.zero,
                      distance: 0.0,
                      showTimes: false,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'VOTRE PROGRAMME',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Poids : ${data.bio.weight} kg'),
                            Text('Taille : ${data.bio.size} m'),
                          ],
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.exercices.length,
                      itemBuilder: (context, index) {
                        final ex = data.exercices[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(ex.name),
                            subtitle: _buildExerciceSubtitle(ex),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _buildExerciceSubtitle(Exercice ex) {
  if (ex.positions != null && ex.positions!.isNotEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ex.positions!.map((p) => Text(
        '${p.name} : ${p.time}s${p.rest != null ? ' (repos ${p.rest}s)' : ''}',
      )).toList(),
    );
  }
  final details = <String>[];
  if (ex.reps != null) details.add('Répétitions : ${ex.reps}');
  if (ex.steps != null) details.add('Séries : ${ex.steps}');
  if (ex.rest != null) details.add('Repos : ${ex.rest}s');
  if (ex.distance != null) details.add('Distance : ${ex.distance} km');
  if (ex.timeObjective != null) details.add('Objectif temps : ${ex.timeObjective}s');
  if (ex.duration != null) details.add('Durée : ${ex.duration}s');
  return Text(details.join(' • '));
}
