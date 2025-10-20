import 'package:flutter/material.dart';
import 'package:natation/services/database_service.dart';

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
    final data = await DatabaseService().getResults();
    setState(() => results = data);
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
          return Card(
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
          );
        },
      ),
    );
  }
}
