import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:classbunk_v1/screens/home_screen.dart';
import 'package:classbunk_v1/providers/app_provider.dart';
import 'package:classbunk_v1/services/attendance_calculator.dart';
import 'package:classbunk_v1/models/subject.dart';
import 'package:classbunk_v1/models/timetable_entry.dart';

class MockCalculator implements AttendanceCalculator {
  @override
  double overallAttendancePercentage() => double.nan;
  @override
  double semesterProgress() => double.nan;
  @override
  double attendancePercentage(String subjectId) => 80.0;
  @override
  int totalAttended(String subjectId) => 10;
  @override
  int totalConducted(String subjectId) => 15;
  @override
  int safeBunks(String subjectId, int targetPercent) => 2;
  @override
  List<TimetableEntry> getScheduleForDate(DateTime date) => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockProvider extends ChangeNotifier implements AppProvider {
  @override
  final AttendanceCalculator calculator = MockCalculator();
  @override
  List<Subject> get subjects => [];
  @override
  int get targetAttendance => 75;
  @override
  bool hasAttendanceForDate(DateTime date) => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('HomeScreen test', (WidgetTester tester) async {
    final mockProvider = MockProvider();
    
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: mockProvider,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
