import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/attendance_record.dart';

class AttendanceEditScreen extends StatefulWidget {
  const AttendanceEditScreen({super.key});
  @override
  State<AttendanceEditScreen> createState() => _AttendanceEditScreenState();
}

class _AttendanceEditScreenState extends State<AttendanceEditScreen> {
  late DateTime _selectedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Attendance')),
      body: Column(children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1))),
            Expanded(child: Center(child: Text(DateFormat('MMMM yyyy').format(_selectedMonth), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)))),
            IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1))),
          ]),
        ),
        // Day labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => Expanded(child: Center(child: Text(d, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant))))).toList()),
        ),
        const SizedBox(height: 4),
        // Calendar grid
        _buildCalendarGrid(provider, cs),
        const Divider(height: 1),
        // Selected date details
        Expanded(child: _selectedDate != null ? _buildDateDetail(provider, cs) : Center(child: Text('Select a date to edit', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)))),
      ]),
    );
  }

  Widget _buildCalendarGrid(AppProvider provider, ColorScheme cs) {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday; // 1=Mon

    final cells = <Widget>[];
    // Empty cells before first day
    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    // Day cells
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final isSelected = _selectedDate != null && _selectedDate!.year == date.year && _selectedDate!.month == date.month && _selectedDate!.day == date.day;
      final isWeekend = date.weekday == 6 || date.weekday == 7;
      final hasRecords = provider.hasAttendanceForDate(date);
      final records = hasRecords ? provider.getRecordsForDate(date) : <AttendanceRecord>[];
      
      // Determine dot color
      Color? dotColor;
      if (hasRecords && records.isNotEmpty) {
        final hasAbsent = records.any((r) => r.status == AttendanceStatus.absent);
        final allPresent = records.every((r) => r.status == AttendanceStatus.present || r.status == AttendanceStatus.dutyLeave);
        final hasHoliday = records.any((r) => r.status == AttendanceStatus.holiday);
        if (hasHoliday) {
          dotColor = cs.tertiary;
        } else if (allPresent) {
          dotColor = cs.primary;
        } else if (hasAbsent) {
          dotColor = cs.error;
        } else {
          dotColor = cs.primary;
        }
      }

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? cs.primaryContainer : Colors.transparent,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$day', style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isWeekend ? cs.onSurfaceVariant.withValues(alpha: 0.5) : cs.onSurface)),
              if (dotColor != null) Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 2), decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
            ]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.1,
        children: cells,
      ),
    );
  }

  Widget _buildDateDetail(AppProvider provider, ColorScheme cs) {
    final date = _selectedDate!;
    final schedule = provider.calculator.getScheduleForDate(date);
    final subjects = provider.subjects;
    final records = provider.getRecordsForDate(date);

    if (schedule.isEmpty) {
      return Center(child: Text('No classes on ${DateFormat('EEEE').format(date)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedule.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(DateFormat('EEEE, MMM d').format(date), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          );
        }
        final entry = schedule[i - 1];
        String subName = entry.subjectId;
        try { subName = subjects.firstWhere((s) => s.id == entry.subjectId).name; } catch (_) {}
        final existing = records.where((r) => r.subjectId == entry.subjectId).firstOrNull;
        final currentStatus = existing?.status ?? AttendanceStatus.present;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(subName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SegmentedButton<AttendanceStatus>(
                  segments: const [
                    ButtonSegment(value: AttendanceStatus.present, label: Text('Present')),
                    ButtonSegment(value: AttendanceStatus.absent, label: Text('Absent')),
                    ButtonSegment(value: AttendanceStatus.dutyLeave, label: Text('Duty')),
                    ButtonSegment(value: AttendanceStatus.holiday, label: Text('Holiday')),
                  ],
                  selected: {currentStatus},
                  onSelectionChanged: (v) async {
                    final normalizedDate = DateTime(date.year, date.month, date.day);
                    await provider.saveAttendance(AttendanceRecord(date: normalizedDate, subjectId: entry.subjectId, status: v.first));
                  },
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
