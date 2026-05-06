import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/attendance_record.dart';

class AttendanceMarkingScreen extends StatefulWidget {
  final DateTime date;
  const AttendanceMarkingScreen({super.key, required this.date});
  @override
  State<AttendanceMarkingScreen> createState() => _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends State<AttendanceMarkingScreen> {
  // Map<subjectId, AttendanceStatus>
  final Map<String, AttendanceStatus> _selections = {};

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    final schedule = provider.calculator.getScheduleForDate(widget.date);
    // Pre-fill with existing records or default to present
    final existing = provider.getRecordsForDate(widget.date);
    for (final entry in schedule) {
      final record = existing.where((r) => r.subjectId == entry.subjectId).firstOrNull;
      _selections[entry.subjectId] = record?.status ?? AttendanceStatus.present;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;
    final schedule = provider.calculator.getScheduleForDate(widget.date);
    final subjects = provider.subjects;
    final dateStr = DateFormat('EEEE, MMM d').format(widget.date);

    final presentCount = _selections.values.where((s) => s == AttendanceStatus.present).length;
    final absentCount = _selections.values.where((s) => s == AttendanceStatus.absent).length;
    final dutyCount = _selections.values.where((s) => s == AttendanceStatus.dutyLeave).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance'), bottom: PreferredSize(
        preferredSize: const Size.fromHeight(24),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Align(alignment: Alignment.centerLeft, child: Text(dateStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
        ),
      )),
      body: Column(children: [
        Expanded(
          child: schedule.isEmpty
              ? Center(child: Text('No classes scheduled', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedule.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final entry = schedule[i];
                    String subName = entry.subjectId;
                    try { subName = subjects.firstWhere((s) => s.id == entry.subjectId).name; } catch (_) {}
                    final status = _selections[entry.subjectId] ?? AttendanceStatus.present;

                    return Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text('P${entry.slotIndex + 1}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(subName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                          ]),
                          const SizedBox(height: 10),
                          SegmentedButton<AttendanceStatus>(
                            segments: const [
                              ButtonSegment(value: AttendanceStatus.present, label: Text('Present'), icon: Icon(Icons.check_rounded, size: 16)),
                              ButtonSegment(value: AttendanceStatus.absent, label: Text('Absent'), icon: Icon(Icons.close_rounded, size: 16)),
                              ButtonSegment(value: AttendanceStatus.dutyLeave, label: Text('Duty'), icon: Icon(Icons.assignment_ind_rounded, size: 16)),
                            ],
                            selected: {status},
                            onSelectionChanged: (v) => setState(() => _selections[entry.subjectId] = v.first),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
        ),
        // Summary and save
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5))),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _badge(context, '$presentCount', 'Present', cs.primary),
              const SizedBox(width: 20),
              _badge(context, '$absentCount', 'Absent', cs.error),
              const SizedBox(width: 20),
              _badge(context, '$dutyCount', 'Duty', cs.tertiary),
            ]),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () async {
                final normalizedDate = DateTime(widget.date.year, widget.date.month, widget.date.day);
                for (final entry in _selections.entries) {
                  await provider.saveAttendance(AttendanceRecord(date: normalizedDate, subjectId: entry.key, status: entry.value));
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved'), duration: Duration(seconds: 2)));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Attendance'),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _badge(BuildContext context, String count, String label, Color color) {
    return Column(children: [
      Text(count, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
      Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}
