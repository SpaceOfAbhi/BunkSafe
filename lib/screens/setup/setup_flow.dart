import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/subject.dart';
import '../home_screen.dart';

class SetupFlow extends StatefulWidget {
  const SetupFlow({super.key});
  @override
  State<SetupFlow> createState() => _SetupFlowState();
}

class _SetupFlowState extends State<SetupFlow> {
  final _pageController = PageController();
  int _currentStep = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay _notifTime = const TimeOfDay(hour: 20, minute: 0);
  final _subjectController = TextEditingController();
  final _shortCodeController = TextEditingController();
  final Map<int, Map<int, String>> _timetable = {};
  int _periodsPerDay = 5;

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Future<void> _finishSetup() async {
    final provider = context.read<AppProvider>();
    if (_startDate != null && _endDate != null) {
      provider.setSemesterDates(_startDate!, _endDate!);
    }
    provider.setNotificationTime(_notifTime.hour, _notifTime.minute);
    provider.setPeriodsPerDay(_periodsPerDay);
    for (final dayEntry in _timetable.entries) {
      for (final slotEntry in dayEntry.value.entries) {
        await provider.setTimetableEntry(dayEntry.key, slotEntry.key, slotEntry.value);
      }
    }
    provider.completeSetup();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _subjectController.dispose();
    _shortCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(4, (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i <= _currentStep
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_datesStep(), _notifStep(), _subjectsStep(), _timetableStep()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datesStep() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        Text('Semester Dates', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('When does your semester start and end?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 36),
        _dateTile('Start Date', _startDate, () async {
          final d = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
          if (d != null) setState(() => _startDate = d);
        }),
        const SizedBox(height: 16),
        _dateTile('End Date', _endDate, () async {
          final d = await showDatePicker(context: context, initialDate: _endDate ?? _startDate?.add(const Duration(days: 120)) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
          if (d != null) setState(() => _endDate = d);
        }),
        const Spacer(),
        FilledButton(onPressed: _startDate != null && _endDate != null ? _nextStep : null, child: const Text('Continue')),
      ]),
    );
  }

  Widget _dateTile(String label, DateTime? value, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.outline)),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value != null ? DateFormat('MMM d, yyyy').format(value) : 'Select date', style: Theme.of(context).textTheme.bodyLarge),
          ]),
        ]),
      ),
    );
  }

  Widget _notifStep() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        Text('Daily Reminder', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('When should we ask about your attendance?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 36),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: _notifTime);
            if (t != null) setState(() => _notifTime = t);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.outline)),
            child: Row(children: [
              Icon(Icons.schedule_rounded, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(_notifTime.format(context), style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Icon(Icons.edit_rounded, size: 18, color: cs.onSurfaceVariant),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        Text('Periods per day', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [ButtonSegment(value: 4, label: Text('4')), ButtonSegment(value: 5, label: Text('5')), ButtonSegment(value: 6, label: Text('6')), ButtonSegment(value: 7, label: Text('7')), ButtonSegment(value: 8, label: Text('8'))],
          selected: {_periodsPerDay},
          onSelectionChanged: (v) => setState(() => _periodsPerDay = v.first),
        ),
        const Spacer(),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: _prevStep, child: const Text('Back'))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: FilledButton(onPressed: _nextStep, child: const Text('Continue'))),
        ]),
      ]),
    );
  }

  Widget _subjectsStep() {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AppProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        Text('Your Subjects', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Add all subjects for this semester.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(flex: 3, child: TextField(controller: _subjectController, decoration: const InputDecoration(hintText: 'Subject name'), textCapitalization: TextCapitalization.words)),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _shortCodeController, decoration: const InputDecoration(hintText: 'Code'), textCapitalization: TextCapitalization.characters)),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () {
              final name = _subjectController.text.trim();
              if (name.isEmpty) return;
              final code = _shortCodeController.text.trim().isEmpty ? name.substring(0, name.length.clamp(0, 3)).toUpperCase() : _shortCodeController.text.trim();
              provider.addSubject(name, code);
              _subjectController.clear();
              _shortCodeController.clear();
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ]),
        const SizedBox(height: 20),
        Expanded(
          child: provider.subjects.isEmpty
              ? Center(child: Text('No subjects added yet', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)))
              : ListView.separated(
                  itemCount: provider.subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final sub = provider.subjects[i];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(radius: 18, backgroundColor: cs.secondaryContainer, child: Text(sub.shortCode.substring(0, sub.shortCode.length.clamp(0, 2)), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSecondaryContainer))),
                        title: Text(sub.name),
                        trailing: IconButton(icon: Icon(Icons.close_rounded, size: 18, color: cs.onSurfaceVariant), onPressed: () => provider.removeSubject(sub.id)),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: _prevStep, child: const Text('Back'))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: FilledButton(onPressed: provider.subjects.isNotEmpty ? _nextStep : null, child: const Text('Continue'))),
        ]),
      ]),
    );
  }

  Widget _timetableStep() {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AppProvider>();
    final subjects = provider.subjects;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        Text('Weekly Timetable', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Tap cells to assign subjects.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(onPressed: () => _showCopyDialog(context), icon: const Icon(Icons.copy_rounded, size: 16), label: const Text('Copy day')),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Table(
              border: TableBorder.all(color: cs.outlineVariant, borderRadius: BorderRadius.circular(10), width: 0.5),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
                  children: [_cell('', isHeader: true), for (final d in days) _cell(d, isHeader: true)],
                ),
                for (int slot = 0; slot < _periodsPerDay; slot++)
                  TableRow(children: [
                    _cell('P${slot + 1}', isHeader: true),
                    for (int day = 1; day <= 5; day++) _buildSlotCell(day, slot, subjects, cs),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: _prevStep, child: const Text('Back'))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: FilledButton(onPressed: _finishSetup, child: const Text('Finish Setup'))),
        ]),
      ]),
    );
  }

  Widget _cell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Center(child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600))),
    );
  }

  Widget _buildSlotCell(int day, int slot, List<Subject> subjects, ColorScheme cs) {
    final subjectId = _timetable[day]?[slot];
    String label = '';
    if (subjectId != null) {
      try {
        final sub = subjects.firstWhere((s) => s.id == subjectId);
        label = sub.shortCode.substring(0, sub.shortCode.length.clamp(0, 3));
      } catch (_) { label = '?'; }
    }
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context, showDragHandle: true,
          builder: (ctx) => ListView(shrinkWrap: true, children: [
            ListTile(leading: const Icon(Icons.remove_circle_outline_rounded), title: const Text('Empty'), onTap: () { setState(() => _timetable[day]?.remove(slot)); Navigator.pop(ctx); }),
            const Divider(height: 1),
            for (final sub in subjects) ListTile(title: Text(sub.name), onTap: () { setState(() { _timetable[day] ??= {}; _timetable[day]![slot] = sub.id; }); Navigator.pop(ctx); }),
          ]),
        );
      },
      child: Container(height: 40, alignment: Alignment.center, color: subjectId != null ? cs.primaryContainer.withOpacity(0.4) : Colors.transparent, child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: subjectId != null ? cs.onPrimaryContainer : cs.onSurfaceVariant))),
    );
  }

  void _showCopyDialog(BuildContext context) {
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    int? fromDay, toDay;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, ss) => AlertDialog(
        title: const Text('Copy Timetable'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(decoration: const InputDecoration(labelText: 'From'), value: fromDay, items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text(dayNames[i]))), onChanged: (v) => ss(() => fromDay = v)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(decoration: const InputDecoration(labelText: 'To'), value: toDay, items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text(dayNames[i]))), onChanged: (v) => ss(() => toDay = v)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: fromDay != null && toDay != null ? () { setState(() { _timetable[toDay!] = Map<int, String>.from(_timetable[fromDay!] ?? {}); }); Navigator.pop(ctx); } : null, child: const Text('Copy')),
        ],
      ),
    ));
  }
}
