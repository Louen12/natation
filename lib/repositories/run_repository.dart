import 'package:natation/models/run_session.dart';

/// Repository responsable de la persistance des sessions de course.
/// Implémentation basique (stub) qui peut être remplacée par une DB ou API.
class RunRepository {
  Future<void> save(RunSession session) async {
    // TODO: persister réellement (SQLite/Hive/API). Pour l'instant, no-op.
  }
}
