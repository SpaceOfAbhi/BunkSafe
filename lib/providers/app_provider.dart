import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/attendance_record.dart';
import '../models/timetable_entry.dart';
import '../models/working_saturday.dart';
import '../services/database_service.dart';
import '../services/attendance_calculator.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService db = DatabaseService();
  late final AttendanceCalculator calculator;

  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> init() async {
    await db.init();
    calculator = AttendanceCalculator(db);
    _initialized = true;
    notifyListeners();
  }

  // ── Getters ───────────────────────────────────────────────

  bool get isSetupComplete => db.isSetupComplete;
  List<Subject> get subjects => db.subjects;
  DateTime? get semesterStart => db.semesterStart;
  DateTime? get semesterEnd => db.semesterEnd;
  int get notificationHour => db.notificationHour;
  int get notificationMinute => db.notificationMinute;
  int get targetAttendance => db.targetAttendance;
  int get periodsPerDay => db.periodsPerDay;
  List<WorkingSaturday> get workingSaturdays => db.workingSaturdays;

  // ── Setup ─────────────────────────────────────────────────

  void setSemesterDates(DateTime start, DateTime end) {
    db.semesterStart = start;
    db.semesterEnd = end;
    notifyListeners();
  }

  void setNotificationTime(int hour, int minute) {
    db.notificationHour = hour;
    db.notificationMinute = minute;
    notifyListeners();
  }

  void setTargetAttendance(int target) {
    db.targetAttendance = target;
    notifyListeners();
  }

  void setPeriodsPerDay(int periods) {
    db.periodsPerDay = periods;
    notifyListeners();
  }

  Future<void> addSubject(String name, String shortCode) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await db.addSubject(Subject(id: id, name: name, shortCode: shortCode));
    notifyListeners();
  }

  Future<void> removeSubject(String id) async {
    await db.removeSubject(id);
    notifyListeners();
  }

  Future<void> updateSubject(Subject subject) async {
    await db.updateSubject(subject);
    notifyListeners();
  }

  void completeSetup() {
    db.isSetupComplete = true;
    notifyListeners();
  }

  // ── Timetable ─────────────────────────────────────────────

  List<TimetableEntry> getEntriesForDay(int day) => db.getEntriesForDay(day);

  Future<void> setTimetableEntry(int day, int slot, String subjectId) async {
    await db.setTimetableEntry(TimetableEntry(
      dayOfWeek: day,
      slotIndex: slot,
      subjectId: subjectId,
    ));
    notifyListeners();
  }

  Future<void> removeTimetableEntry(int day, int slot) async {
    await db.removeTimetableEntry(day, slot);
    notifyListeners();
  }

  Future<void> copyTimetable(int fromDay, int toDay) async {
    await db.copyTimetable(fromDay, toDay);
    notifyListeners();
  }

  // ── Attendance ────────────────────────────────────────────

  Future<void> markAllPresent(DateTime date) async {
    await calculator.markAllPresent(date);
    notifyListeners();
  }

  Future<void> saveAttendance(AttendanceRecord record) async {
    await db.saveAttendanceRecord(record);
    notifyListeners();
  }

  List<AttendanceRecord> getRecordsForDate(DateTime date) =>
      db.getRecordsForDate(date);

  List<AttendanceRecord> getRecordsForSubject(String subjectId) =>
      db.getRecordsForSubject(subjectId);

  bool hasAttendanceForDate(DateTime date) =>
      db.hasAttendanceForDate(date);

  // ── Working Saturdays ─────────────────────────────────────

  Future<void> addWorkingSaturday(DateTime date, int followsDay) async {
    await db.addWorkingSaturday(WorkingSaturday(
      date: date,
      followsDayOfWeek: followsDay,
    ));
    notifyListeners();
  }

  Future<void> removeWorkingSaturday(String key) async {
    await db.removeWorkingSaturday(key);
    notifyListeners();
  }

  // ── Export / Import / Reset ───────────────────────────────

  String exportData() => db.exportData();

  Future<void> importData(String json) async {
    await db.importData(json);
    notifyListeners();
  }

  Future<void> resetAll() async {
    await db.resetAll();
    notifyListeners();
  }
}
