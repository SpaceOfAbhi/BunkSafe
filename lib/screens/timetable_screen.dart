import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/subject.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  @override
  void initState() {
    super.initState();
    // Default to today's tab (Mon=0, Tue=1, etc), or Monday if weekend
    final todayIndex = (DateTime.now().weekday - 1).clamp(0, 4);
    _tabController = TabController(length: 5, vsync: this, initialIndex: todayIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;
    final subjects = provider.subjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [Tab(text: 'Mon'), Tab(text: 'Tue'), Tab(text: 'Wed'), Tab(text: 'Thu'), Tab(text: 'Fri')],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              if (v == 'copy') _showCopyDialog(context, provider);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'copy', child: Text('Copy timetable')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(5, (dayIndex) {
          final dayOfWeek = dayIndex + 1;
          final entries = provider.getEntriesForDay(dayOfWeek);
          final periodsPerDay = provider.periodsPerDay;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: periodsPerDay,
            itemBuilder: (_, slotIndex) {
              final entry = entries.where((e) => e.slotIndex == slotIndex).firstOrNull;
              Subject? sub;
              if (entry != null) {
                try { sub = subjects.firstWhere((s) => s.id == entry.subjectId); } catch (_) {}
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showSubjectPicker(context, provider, dayOfWeek, slotIndex, subjects),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: sub != null ? cs.primaryContainer : cs.surfaceContainerHighest,
                          ),
                          alignment: Alignment.center,
                          child: Text('P${slotIndex + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sub != null ? cs.onPrimaryContainer : cs.onSurfaceVariant)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: sub != null
                              ? Text(sub.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500))
                              : Text('Empty slot', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant),
                      ]),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  void _showSubjectPicker(BuildContext context, AppProvider provider, int day, int slot, List<Subject> subjects) {
    showModalBottomSheet(
      context: context, showDragHandle: true,
      builder: (ctx) => ListView(shrinkWrap: true, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text('Period ${slot + 1} — ${_dayNames[day - 1]}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        ListTile(
          leading: const Icon(Icons.remove_circle_outline_rounded),
          title: const Text('Empty'),
          onTap: () { provider.removeTimetableEntry(day, slot); Navigator.pop(ctx); },
        ),
        const Divider(height: 1),
        for (final sub in subjects)
          ListTile(
            leading: CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.secondaryContainer, child: Text(sub.shortCode.substring(0, sub.shortCode.length.clamp(0, 2)), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSecondaryContainer))),
            title: Text(sub.name),
            onTap: () { provider.setTimetableEntry(day, slot, sub.id); Navigator.pop(ctx); },
          ),
      ]),
    );
  }

  void _showCopyDialog(BuildContext context, AppProvider provider) {
    int? fromDay, toDay;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, ss) => AlertDialog(
        title: const Text('Copy Timetable'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(decoration: const InputDecoration(labelText: 'From'), value: fromDay, items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text(_dayNames[i]))), onChanged: (v) => ss(() => fromDay = v)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(decoration: const InputDecoration(labelText: 'To'), value: toDay, items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text(_dayNames[i]))), onChanged: (v) => ss(() => toDay = v)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: fromDay != null && toDay != null ? () { provider.copyTimetable(fromDay!, toDay!); Navigator.pop(ctx); } : null, child: const Text('Copy')),
        ],
      ),
    ));
  }
}
