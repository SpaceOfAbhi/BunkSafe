import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/subject.dart';

class SubjectDetailScreen extends StatelessWidget {
  final Subject subject;
  const SubjectDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final calc = provider.calculator;
    final cs = Theme.of(context).colorScheme;
    final pct = calc.attendancePercentage(subject.id);
    final attended = calc.totalAttended(subject.id);
    final total = calc.totalConducted(subject.id);
    final absent = calc.totalAbsent(subject.id);
    final dutyLeaves = calc.dutyLeaveCount(subject.id);
    final remaining = calc.estimatedRemainingClasses(subject.id);

    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Attendance percentage header
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                SizedBox(
                  width: 100, height: 100,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox(width: 100, height: 100, child: CircularProgressIndicator(value: pct / 100, strokeWidth: 7, backgroundColor: cs.surfaceContainerHighest, strokeCap: StrokeCap.round)),
                    Text('${pct.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _stat(context, '$attended', 'Attended'),
                  _divider(context),
                  _stat(context, '$total', 'Total'),
                  _divider(context),
                  _stat(context, '$absent', 'Absent'),
                  _divider(context),
                  _stat(context, '$dutyLeaves', 'Duty Leave'),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          // Remaining estimate
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.event_note_rounded, color: cs.onSurfaceVariant),
              title: const Text('Estimated remaining classes'),
              trailing: Text('$remaining', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Target Analysis', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          // Target cards
          for (final target in [90, 80, 75]) ...[
            _targetCard(context, target, subject.id, calc, provider, cs),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 20),
          // Duty leave info
          Text('Duty Leave Recovery', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (final target in [90, 80, 75]) ...[
            _dutyLeaveCard(context, target, subject.id, calc, cs),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
    ]);
  }

  Widget _divider(BuildContext context) {
    return Container(width: 1, height: 28, color: Theme.of(context).colorScheme.outlineVariant);
  }

  Widget _targetCard(BuildContext context, int target, String subjectId, dynamic calc, AppProvider provider, ColorScheme cs) {
    final bunks = calc.safeBunks(subjectId, target);
    final reachable = calc.isTargetReachable(subjectId, target);
    final recovery = calc.recoveryClassesNeeded(subjectId, target);
    final currentPct = calc.attendancePercentage(subjectId);
    final isAbove = currentPct >= target;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: !reachable ? cs.errorContainer : isAbove ? cs.primaryContainer : cs.tertiaryContainer,
            ),
            alignment: Alignment.center,
            child: Text('$target%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: !reachable ? cs.onErrorContainer : isAbove ? cs.onPrimaryContainer : cs.onTertiaryContainer)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$target% Target', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              if (!reachable)
                Text('Not reachable', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error))
              else if (bunks > 0)
                Text('$bunks safe bunks remaining', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.primary))
              else if (bunks == 0)
                Text('No bunks left — attend all remaining', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.tertiary))
              else
                Text('Need $recovery more classes', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error)),
            ]),
          ),
          Icon(
            !reachable ? Icons.cancel_rounded : bunks >= 0 ? Icons.check_circle_rounded : Icons.warning_rounded,
            size: 20,
            color: !reachable ? cs.error : bunks >= 0 ? cs.primary : cs.error,
          ),
        ]),
      ),
    );
  }

  Widget _dutyLeaveCard(BuildContext context, int target, String subjectId, dynamic calc, ColorScheme cs) {
    final dlNeeded = calc.dutyLeavesNeeded(subjectId, target);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        dense: true,
        leading: Text('$target%', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
        title: dlNeeded > 0
            ? Text('Need $dlNeeded duty leave${dlNeeded > 1 ? 's' : ''} to reach $target%')
            : Text('Already at $target% or above'),
        titleTextStyle: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
