import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/subject.dart';
import '../models/attendance_record.dart';
import '../models/timetable_entry.dart';
import '../models/working_saturday.dart';

class DatabaseService {
  static const String _settingsBox = 'settings';
  static const String _subjectsBox = 'subjects';
  static const String _attendanceBox = 'attendance';
  static const String _timetableBox = 'timetable';
  static const String _workingSaturdaysBox = 'working_saturdays';

  late Box _settings;
  late Box<Subject> _subjects;
  late Box<AttendanceRecord> _attendance;
  late Box<TimetableEntry> _timetable;
  late Box<WorkingSaturday> _workingSaturdays;

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(AttendanceRecordAdapter());
    Hive.registerAdapter(TimetableEntryAdapter());
    Hive.registerAdapter(WorkingSaturdayAdapter());

    _settings = await Hive.openBox(_settingsBox);
    _subjects = await Hive.openBox<Subject>(_subjectsBox);
    _attendance = await Hive.openBox<AttendanceRecord>(_attendanceBox);
    _timetable = await Hive.openBox<TimetableEntry>(_timetableBox);
    _workingSaturdays = await Hive.openBox<WorkingSaturday>(
      _workingSaturdaysBox,
    );
  }

  // ── Settings ──────────────────────────────────────────────

  bool get isSetupComplete =>
      _settings.get('setupComplete', defaultValue: false);
  set isSetupComplete(bool val) => _settings.put('setupComplete', val);

  DateTime? get semesterStart {
    final ms = _settings.get('semesterStart');
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  set semesterStart(DateTime? val) =>
      _settings.put('semesterStart', val?.millisecondsSinceEpoch);

  DateTime? get semesterEnd {
    final ms = _settings.get('semesterEnd');
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  set semesterEnd(DateTime? val) =>
      _settings.put('semesterEnd', val?.millisecondsSinceEpoch);

  int get notificationHour =>
      _settings.get('notificationHour', defaultValue: 20);
  set notificationHour(int val) => _settings.put('notificationHour', val);

  int get notificationMinute =>
      _settings.get('notificationMinute', defaultValue: 0);
  set notificationMinute(int val) => _settings.put('notificationMinute', val);

  int get targetAttendance =>
      _settings.get('targetAttendance', defaultValue: 75);
  set targetAttendance(int val) => _settings.put('targetAttendance', val);

  int get periodsPerDay => _settings.get('periodsPerDay', defaultValue: 5);
  set periodsPerDay(int val) => _settings.put('periodsPerDay', val);

  // ── Subjects ──────────────────────────────────────────────

  List<Subject> get subjects => _subjects.values.toList();

  Future<void> addSubject(Subject subject) async {
    await _subjects.put(subject.id, subject);
  }

  Future<void> removeSubject(String id) async {
    await _subjects.delete(id);
    // Also remove related attendance and timetable entries
    final keysToRemove = _attendance.keys
        .where((k) => k.toString().endsWith('_$id'))
        .toList();
    for (final key in keysToRemove) {
      await _attendance.delete(key);
    }
    final ttKeysToRemove = _timetable.keys.where((k) {
      final entry = _timetable.get(k);
      return entry?.subjectId == id;
    }).toList();
    for (final key in ttKeysToRemove) {
      await _timetable.delete(key);
    }
  }

  Future<void> updateSubject(Subject subject) async {
    await _subjects.put(subject.id, subject);
  }

  // ── Timetable ─────────────────────────────────────────────

  List<TimetableEntry> get timetableEntries => _timetable.values.toList();

  List<TimetableEntry> getEntriesForDay(int dayOfWeek) {
    return _timetable.values.where((e) => e.dayOfWeek == dayOfWeek).toList()
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
  }

  Future<void> setTimetableEntry(TimetableEntry entry) async {
    await _timetable.put(entry.key, entry);
  }

  Future<void> removeTimetableEntry(int dayOfWeek, int slotIndex) async {
    await _timetable.delete('${dayOfWeek}_$slotIndex');
  }

  Future<void> clearTimetableForDay(int day) async {
    final keys = _timetable.keys
        .where((k) => k.toString().startsWith('${day}_'))
        .toList();
    for (final key in keys) {
      await _timetable.delete(key);
    }
  }

  Future<void> copyTimetable(int fromDay, int toDay) async {
    await clearTimetableForDay(toDay);
    final entries = getEntriesForDay(fromDay);
    for (final entry in entries) {
      final newEntry = TimetableEntry(
        dayOfWeek: toDay,
        slotIndex: entry.slotIndex,
        subjectId: entry.subjectId,
      );
      await setTimetableEntry(newEntry);
    }
  }

  // ── Attendance ────────────────────────────────────────────

  List<AttendanceRecord> get allAttendanceRecords =>
      _attendance.values.toList();

  List<AttendanceRecord> getRecordsForDate(DateTime date) {
    final prefix =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _attendance.values.where((r) => r.key.startsWith(prefix)).toList();
  }

  List<AttendanceRecord> getRecordsForSubject(String subjectId) {
    return _attendance.values.where((r) => r.subjectId == subjectId).toList();
  }

  Future<void> saveAttendanceRecord(AttendanceRecord record) async {
    await _attendance.put(record.key, record);
  }

  Future<void> deleteAttendanceRecord(String key) async {
    await _attendance.delete(key);
  }

  bool hasAttendanceForDate(DateTime date) {
    final prefix =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _attendance.keys.any((k) => k.toString().startsWith(prefix));
  }

  // ── Working Saturdays ─────────────────────────────────────

  List<WorkingSaturday> get workingSaturdays =>
      _workingSaturdays.values.toList();

  Future<void> addWorkingSaturday(WorkingSaturday ws) async {
    await _workingSaturdays.put(ws.key, ws);
  }

  Future<void> removeWorkingSaturday(String key) async {
    await _workingSaturdays.delete(key);
  }

  WorkingSaturday? getWorkingSaturday(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _workingSaturdays.get(key);
  }

  // ── Export / Import ───────────────────────────────────────

  String exportData() {
    final data = {
      'settings': {
        'semesterStart': semesterStart?.millisecondsSinceEpoch,
        'semesterEnd': semesterEnd?.millisecondsSinceEpoch,
        'notificationHour': notificationHour,
        'notificationMinute': notificationMinute,
        'targetAttendance': targetAttendance,
        'periodsPerDay': periodsPerDay,
      },
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'timetable': timetableEntries.map((t) => t.toJson()).toList(),
      'attendance': allAttendanceRecords.map((a) => a.toJson()).toList(),
      'workingSaturdays': workingSaturdays.map((w) => w.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  Future<void> importData(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    // Settings
    final settings = data['settings'] as Map<String, dynamic>;
    if (settings['semesterStart'] != null) {
      semesterStart = DateTime.fromMillisecondsSinceEpoch(
        settings['semesterStart'],
      );
    }
    if (settings['semesterEnd'] != null) {
      semesterEnd = DateTime.fromMillisecondsSinceEpoch(
        settings['semesterEnd'],
      );
    }
    notificationHour = settings['notificationHour'] ?? 20;
    notificationMinute = settings['notificationMinute'] ?? 0;
    targetAttendance = settings['targetAttendance'] ?? 75;
    periodsPerDay = settings['periodsPerDay'] ?? 5;

    // Subjects
    await _subjects.clear();
    for (final s in (data['subjects'] as List)) {
      final subject = Subject.fromJson(s);
      await _subjects.put(subject.id, subject);
    }

    // Timetable
    await _timetable.clear();
    for (final t in (data['timetable'] as List)) {
      final entry = TimetableEntry.fromJson(t);
      await _timetable.put(entry.key, entry);
    }

    // Attendance
    await _attendance.clear();
    for (final a in (data['attendance'] as List)) {
      final record = AttendanceRecord.fromJson(a);
      await _attendance.put(record.key, record);
    }

    // Working Saturdays
    await _workingSaturdays.clear();
    for (final w in (data['workingSaturdays'] as List)) {
      final ws = WorkingSaturday.fromJson(w);
      await _workingSaturdays.put(ws.key, ws);
    }

    isSetupComplete = true;
  }

  // ── Reset ─────────────────────────────────────────────────

  Future<void> resetAll() async {
    await _settings.clear();
    await _subjects.clear();
    await _attendance.clear();
    await _timetable.clear();
    await _workingSaturdays.clear();
  }
}
