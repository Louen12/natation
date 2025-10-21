import 'package:flutter/material.dart';
import 'package:natation/repositories/vma_repository.dart';

class HistoryVmaScreen extends StatefulWidget {
  const HistoryVmaScreen({super.key});

  @override
  State<HistoryVmaScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryVmaScreen> {
  List<Map<String, dynamic>> results = [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final data = await VmaRepository().getResults();
    setState(() => results = data);
  }
  
  Future<void> _deleteResult(int id) async {
    await VmaRepository().deleteOneResult(id);
    _loadResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique des tests"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange, Colors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: results.isEmpty
          ? const Center(
        child: Text("Aucun test enregistré."),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final res = results[index];

          return Dismissible(
            key: ValueKey(res['id']),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white, size: 30),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Supprimer ce résultat ?'),
                  content: const Text('Cette action est irréversible.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) async {
              await _deleteResult(res['id']);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Résultat supprimé')),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 6,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.run_circle, color: Colors.orange),
                title: Text(
                  "VMA : ${res['vma'].toStringAsFixed(1)} km/h",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Palier ${res['palier']} — ${DateTime.parse(res['date']).toLocal().toString().split('.')[0]}",
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
