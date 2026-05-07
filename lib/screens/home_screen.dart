import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'subject_detail_screen.dart';
import 'timetable_screen.dart';
import 'attendance_marking_screen.dart';
import 'attendance_edit_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardTab(),
      const TimetableScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_navIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today_rounded), label: 'Timetable'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceEditScreen())),
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final calc = provider.calculator;
    final cs = Theme.of(context).colorScheme;
    final subjects = provider.subjects;
    final overallPct = calc.overallAttendancePercentage();
    final semProgress = calc.semesterProgress();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('KTU Companion'),
          floating: true,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(children: [
              // Overall attendance card
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Overall Attendance', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('${overallPct.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                      ]),
                      SizedBox(
                        width: 56, height: 56,
                        child: CircularProgressIndicator(
                          value: overallPct / 100,
                          strokeWidth: 5,
                          backgroundColor: cs.surfaceContainerHighest,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Text('Semester', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: semProgress, minHeight: 4, backgroundColor: cs.surfaceContainerHighest))),
                      const SizedBox(width: 8),
                      Text('${(semProgress * 100).toInt()}%', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              // Quick mark today
              if (!provider.hasAttendanceForDate(DateTime.now()) && provider.calculator.getScheduleForDate(DateTime.now()).isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline_rounded, color: cs.primary),
                    title: const Text('Mark today\'s attendance'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      FilledButton.tonal(
                        onPressed: () async {
                          await provider.markAllPresent(DateTime.now());
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All classes marked present'), duration: Duration(seconds: 2)));
                        },
                        child: const Text('All Present'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceMarkingScreen(date: DateTime.now()))),
                        child: const Text('Select'),
                      ),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
        // Subjects header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text('Subjects', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ),
        // Subject list
        if (subjects.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No subjects added yet. Go to Settings to add subjects.')),
            ),
          )
        else
          SliverList.builder(
            itemCount: subjects.length * 2 - 1,
            itemBuilder: (_, index) {
              if (index.isOdd) return const SizedBox(height: 2);
              final i = index ~/ 2;
              final sub = subjects[i];
              final pct = calc.attendancePercentage(sub.id);
              final attended = calc.totalAttended(sub.id);
              final total = calc.totalConducted(sub.id);
              final bunks = calc.safeBunks(sub.id, provider.targetAttendance);
              final isLow = pct < provider.targetAttendance && total > 0;

              return Card(
                child: ListTile(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectDetailScreen(subject: sub))),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: isLow ? cs.errorContainer : cs.secondaryContainer,
                    child: Text(sub.shortCode.substring(0, sub.shortCode.length.clamp(0, 2)),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isLow ? cs.onErrorContainer : cs.onSecondaryContainer)),
                  ),
                  title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('$attended/$total classes', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      if (bunks > 0 && total > 0)
                        Text('$bunks bunks left', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w500))
                      else if (bunks < 0 && total > 0)
                        Text('need ${bunks.abs()}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  trailing: Text('${pct.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: isLow ? cs.error : cs.onSurface)),
                ),
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}
