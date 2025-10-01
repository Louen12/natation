import 'package:flutter/material.dart';
import '../models/training.dart';

class TrainingListScreen extends StatelessWidget {
  const TrainingListScreen({super.key});

  List<TrainingSet> _flattenSession(TrainingSession s) => [
        ...s.warmUp,
        ...s.mainSet,
        ...s.coolDown,
      ];

  @override
  Widget build(BuildContext context) {
    final session = sampleSessions.isNotEmpty ? sampleSessions.first : null;
    final sets = session == null ? <TrainingSet>[] : _flattenSession(session);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programme d\'entraînement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
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
                _BannerHeader(onAllSessions: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AllSessionsScreen()),
                  );
                }),
                const SizedBox(height: 28),
                Text(
                  'VOTRE PROGRAMME',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                ),
                const SizedBox(height: 24),
                if (session == null)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .8),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Text('Aucun entraînement disponible.'),
                  )
                else
                  _ProgramPanel(session: session, sets: sets),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerHeader extends StatelessWidget {
  final VoidCallback onAllSessions;
  const _BannerHeader({required this.onAllSessions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
            Positioned.fill(
            top: 10,
            child: CustomPaint(
              painter: _BannerPainter(),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                'NATH A FOND',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 4,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: onAllSessions,
              icon: const Icon(Icons.list_alt),
              label: const Text('Tous'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFF6A00);
    final w = size.width;
    final h = 70.0;
    final notchDepth = 14.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h - 10)
      ..lineTo(w / 2 + 70, h - 10)
      ..lineTo(w / 2, h - 10 + notchDepth)
      ..lineTo(w / 2 - 70, h - 10)
      ..lineTo(0, h - 10)
      ..close();
    canvas.drawShadow(path, Colors.black45, 4, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgramPanel extends StatelessWidget {
  final TrainingSession session;
  final List<TrainingSet> sets;
  const _ProgramPanel({required this.session, required this.sets});

  @override
  Widget build(BuildContext context) {
    final panelColor = Colors.grey.shade200;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          for (int i = 0; i < sets.length; i++)
            _ExerciseRow(
              index: i,
              set: sets[i],
              onTap: () => _showSetDetails(context, sets[i], i + 1),
            ),
          if (sets.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Programme vide.'),
            ),
        ],
      ),
    );
  }

  void _showSetDetails(BuildContext context, TrainingSet set, int number) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Exercice $number', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text('${set.repetitions} x ${set.distance}m ${set.stroke.label}'),
              if (set.intensity != null) Text('Intensité : ${set.intensity}'),
              if (set.comment != null) ...[
                const SizedBox(height: 8),
                Text(set.comment!),
              ],
              const SizedBox(height: 8),
              Text('Total: ${set.totalDistance} m', style: Theme.of(ctx).textTheme.labelMedium),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer'),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final int index;
  final TrainingSet set;
  final VoidCallback onTap;
  const _ExerciseRow({required this.index, required this.set, required this.onTap});

  Color _strokeColor(Stroke stroke) {
    switch (stroke) {
      case Stroke.freestyle:
        return Colors.blueAccent;
      case Stroke.backstroke:
        return Colors.indigo;
      case Stroke.breaststroke:
        return Colors.green.shade600;
      case Stroke.butterfly:
        return Colors.purple;
      case Stroke.medley:
        return Colors.deepOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = '${set.repetitions} x ${set.distance}m ${set.stroke.label}${set.intensity != null ? ' • ${set.intensity}' : ''}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: FiftySquare._size,
              height: FiftySquare._size,
              decoration: BoxDecoration(
                color: _strokeColor(set.stroke),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                set.stroke.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

class FiftySquare {
  static const double _size = 50;
}

class AllSessionsScreen extends StatelessWidget {
  const AllSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = [...sampleSessions]..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(title: const Text('Tous les entraînements')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final s = sessions[index];
          return Card(
            child: ListTile(
              title: Text(s.title),
              subtitle: Text('${_shortDate(s.date)}  •  ${s.totalDistance} m'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TrainingDetailScreen(session: s),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TrainingDetailScreen extends StatelessWidget {
  final TrainingSession session;
  const TrainingDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(session.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(_longDate(session.date)),
              const Spacer(),
              Chip(label: Text('${session.totalDistance} m')),
            ],
          ),
          const SizedBox(height: 16),
          if (session.warmUp.isNotEmpty) _Block(title: 'Échauffement', sets: session.warmUp),
          if (session.mainSet.isNotEmpty) _Block(title: 'Série principale', sets: session.mainSet),
          if (session.coolDown.isNotEmpty) _Block(title: 'Récupération', sets: session.coolDown),
          if (session.notes != null) ...[
            const SizedBox(height: 16),
            Text('Notes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(session.notes!),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final List<TrainingSet> sets;
  const _Block({required this.title, required this.sets});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ...sets.map((s) => _SetTile(set: s)),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Total: ${sets.fold(0, (p, e) => p + e.totalDistance)} m',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  final TrainingSet set;
  const _SetTile({required this.set});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(set.stroke.icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: style.bodyMedium,
                    children: [
                      TextSpan(text: '${set.repetitions} x ${set.distance}m '),
                      TextSpan(text: set.stroke.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (set.intensity != null) TextSpan(text: '  •  ${set.intensity!}', style: const TextStyle(color: Colors.teal)),
                    ],
                  ),
                ),
                if (set.comment != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      set.comment!,
                      style: style.bodySmall?.copyWith(
                        color: style.bodySmall?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text('${set.totalDistance} m', style: style.labelSmall),
        ],
      ),
    );
  }
}

String _shortDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
String _longDate(DateTime d) => '${_weekdayFr(d.weekday)} ${d.day} ${_monthFr(d.month)}';
String _weekdayFr(int w) => ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'][w-1];
String _monthFr(int m) => ['janv','févr','mars','avr','mai','juin','juil','août','sept','oct','nov','déc'][m-1];
