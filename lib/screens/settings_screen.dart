import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';

import 'setup/setup_flow.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;
    final notifTime = TimeOfDay(hour: provider.notificationHour, minute: provider.notificationMinute);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Preferences section
          _sectionHeader(context, 'Preferences'),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Notification Time'),
                trailing: Text(notifTime.format(context), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.primary)),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: notifTime);
                  if (t != null) provider.setNotificationTime(t.hour, t.minute);
                },
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.track_changes_rounded),
                title: const Text('Target Attendance'),
                trailing: Text('${provider.targetAttendance}%', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.primary)),
                onTap: () => _showTargetDialog(context, provider),
              ),
            ]),
          ),
          // Working Saturdays section
          _sectionHeader(context, 'Working Saturdays'),
          ...provider.workingSaturdays.map((ws) => Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today_rounded),
              title: Text(DateFormat('EEE, MMM d').format(ws.date)),
              subtitle: Text('→ ${ws.followsDayName} timetable', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              trailing: IconButton(icon: Icon(Icons.delete_outline_rounded, size: 20, color: cs.error), onPressed: () => provider.removeWorkingSaturday(ws.key)),
            ),
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: () => _showAddSaturdayDialog(context, provider),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Working Saturday'),
            ),
          ),
          // Data section
          _sectionHeader(context, 'Data Management'),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.upload_rounded),
                title: const Text('Export Backup'),
                onTap: () {
                  final data = provider.exportData();
                  Clipboard.setData(ClipboardData(text: data));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup copied to clipboard')));
                },
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Import Backup'),
                onTap: () => _showImportDialog(context, provider),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.restart_alt_rounded, color: cs.error),
                title: Text('Reset Semester', style: TextStyle(color: cs.error)),
                onTap: () => _showResetDialog(context, provider),
              ),
            ]),
          ),
          // About
          _sectionHeader(context, 'About'),
          Card(
            child: Column(children: [
              const ListTile(leading: Icon(Icons.info_outline_rounded), title: Text('KTU Companion'), subtitle: Text('Version 1.0.0')),
              const Divider(height: 1, indent: 56),
              ListTile(leading: const Icon(Icons.school_rounded), title: const Text('Made for KTU Students'), subtitle: Text('Offline attendance tracker', style: TextStyle(color: cs.onSurfaceVariant))),
            ]),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }

  void _showTargetDialog(BuildContext context, AppProvider provider) {
    int target = provider.targetAttendance;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, ss) => AlertDialog(
        title: const Text('Target Attendance'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$target%', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          Slider(value: target.toDouble(), min: 50, max: 100, divisions: 50, label: '$target%', onChanged: (v) => ss(() => target = v.round())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () { provider.setTargetAttendance(target); Navigator.pop(ctx); }, child: const Text('Save')),
        ],
      ),
    ));
  }

  void _showAddSaturdayDialog(BuildContext context, AppProvider provider) {
    DateTime? selectedDate;
    int followsDay = 1;
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, ss) => AlertDialog(
        title: const Text('Add Working Saturday'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(selectedDate != null ? DateFormat('EEE, MMM d, yyyy').format(selectedDate!) : 'Select Saturday'),
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030), selectableDayPredicate: (d) => d.weekday == 6);
              if (d != null) ss(() => selectedDate = d);
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Follows timetable of'),
            initialValue: followsDay,
            items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text(dayNames[i]))),
            onChanged: (v) => ss(() => followsDay = v ?? 1),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: selectedDate != null ? () { provider.addWorkingSaturday(selectedDate!, followsDay); Navigator.pop(ctx); } : null, child: const Text('Add')),
        ],
      ),
    ));
  }

  void _showImportDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Import Backup'),
      content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Paste backup data here'), maxLines: 5),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          try {
            await provider.importData(controller.text);
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup imported successfully')));
          } catch (e) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
          }
        }, child: const Text('Import')),
      ],
    ));
  }

  void _showResetDialog(BuildContext context, AppProvider provider) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Reset Semester'),
      content: const Text('This will delete all your data including subjects, timetable, and attendance records. This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () async {
            await provider.resetAll();
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SetupFlow()), (_) => false);
          },
          child: const Text('Reset Everything'),
        ),
      ],
    ));
  }
}
