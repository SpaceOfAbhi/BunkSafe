import '../models/attendance_record.dart';
import '../models/timetable_entry.dart';
import 'database_service.dart';

class AttendanceCalculator {
  final DatabaseService _db;

  AttendanceCalculator(this._db);

  // ── Per-subject stats ─────────────────────────────────────

  int totalConducted(String subjectId) {
    return _db
        .getRecordsForSubject(subjectId)
        .where((r) => r.status != AttendanceStatus.holiday)
        .length;
  }

  int totalAttended(String subjectId) {
    return _db
        .getRecordsForSubject(subjectId)
        .where(
          (r) =>
              r.status == AttendanceStatus.present ||
              r.status == AttendanceStatus.dutyLeave,
        )
        .length;
  }

  int totalAbsent(String subjectId) {
    return _db
        .getRecordsForSubject(subjectId)
        .where((r) => r.status == AttendanceStatus.absent)
        .length;
  }

  int dutyLeaveCount(String subjectId) {
    return _db
        .getRecordsForSubject(subjectId)
        .where((r) => r.status == AttendanceStatus.dutyLeave)
        .length;
  }

  double attendancePercentage(String subjectId) {
    final total = totalConducted(subjectId);
    if (total == 0) return 100.0;
    return (totalAttended(subjectId) / total) * 100;
  }

  // ── Overall stats ─────────────────────────────────────────

  double overallAttendancePercentage() {
    final subjects = _db.subjects;
    if (subjects.isEmpty) return 100.0;
    int totalAtt = 0;
    int totalCond = 0;
    for (final sub in subjects) {
      totalAtt += totalAttended(sub.id);
      totalCond += totalConducted(sub.id);
    }
    if (totalCond == 0) return 100.0;
    return (totalAtt / totalCond) * 100;
  }

  // ── Semester progress ─────────────────────────────────────

  double semesterProgress() {
    final start = _db.semesterStart;
    final end = _db.semesterEnd;
    if (start == null || end == null) return 0.0;

    final now = DateTime.now();
    final totalDays = end.difference(start).inDays;
    if (totalDays <= 0) return 1.0;
    final elapsed = now.difference(start).inDays;
    return (elapsed / totalDays).clamp(0.0, 1.0);
  }

  // ── Remaining classes estimation ──────────────────────────

  /// Count how many times [subjectId] appears in the weekly timetable.
  int weeklyFrequency(String subjectId) {
    return _db.timetableEntries.where((e) => e.subjectId == subjectId).length;
  }

  /// Remaining working days from today until semester end,
  /// considering only Mon-Fri + working Saturdays.


  /// Estimate remaining classes for a subject based on weekly frequency.
  int estimatedRemainingClasses(String subjectId) {
    final end = _db.semesterEnd;
    if (end == null) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final endDate = DateTime(end.year, end.month, end.day);

    if (todayDate.isAfter(endDate)) return 0;

    int count = 0;
    DateTime d = todayDate.add(const Duration(days: 1));

    while (!d.isAfter(endDate)) {
      int effectiveDay = d.weekday;

      if (d.weekday == 6) {
        final ws = _db.getWorkingSaturday(d);
        if (ws != null) {
          effectiveDay = ws.followsDayOfWeek;
        } else {
          d = d.add(const Duration(days: 1));
          continue;
        }
      } else if (d.weekday == 7) {
        d = d.add(const Duration(days: 1));
        continue;
      }

      // Count how many slots of this subject on this effective day
      final dayEntries = _db.getEntriesForDay(effectiveDay);
      count += dayEntries.where((e) => e.subjectId == subjectId).length;

      d = d.add(const Duration(days: 1));
    }
    return count;
  }

  // ── Bunk / Recovery Calculation ───────────────────────────

  /// Calculate how many more classes can be bunked while maintaining [targetPercent].
  /// Returns negative if recovery is needed.
  int safeBunks(String subjectId, int targetPercent) {
    final attended = totalAttended(subjectId);
    final conducted = totalConducted(subjectId);
    final remaining = estimatedRemainingClasses(subjectId);
    final totalFuture = conducted + remaining;

    if (totalFuture == 0) return 0;

    // We need: (attended + x) / (conducted + remaining) >= targetPercent/100
    // where x is classes we attend out of remaining.
    // Max bunks = remaining - x
    // x = ceil(targetPercent * totalFuture / 100) - attended
    final required = (targetPercent * totalFuture / 100).ceil() - attended;

    if (required < 0) {
      // Already above target, can bunk all remaining
      return remaining;
    }

    // Bunks remaining = remaining - required
    return remaining - required;
  }

  /// Classes needed to recover to [targetPercent] from current state.
  /// Returns 0 if already at target.
  int recoveryClassesNeeded(String subjectId, int targetPercent) {
    final bunks = safeBunks(subjectId, targetPercent);
    if (bunks >= 0) return 0;
    return bunks.abs();
  }

  /// Whether the target is mathematically reachable.
  bool isTargetReachable(String subjectId, int targetPercent) {
    final attended = totalAttended(subjectId);
    final conducted = totalConducted(subjectId);
    final remaining = estimatedRemainingClasses(subjectId);
    final totalFuture = conducted + remaining;

    if (totalFuture == 0) return true;

    // Best case: attend all remaining
    final bestPercentage = (attended + remaining) / totalFuture * 100;
    return bestPercentage >= targetPercent;
  }

  /// Duty leaves needed to reach target (if currently below).
  int dutyLeavesNeeded(String subjectId, int targetPercent) {
    final attended = totalAttended(subjectId);
    final conducted = totalConducted(subjectId);

    if (conducted == 0) return 0;

    final currentPercent = attended / conducted * 100;
    if (currentPercent >= targetPercent) return 0;

    // Each duty leave adds 1 to attended and 0 to conducted (it's retroactive)
    // Actually duty leave counts as present with no new class added.
    // So: (attended + dl) / conducted >= target/100
    // dl = ceil(target * conducted / 100) - attended
    final needed = (targetPercent * conducted / 100).ceil() - attended;
    return needed > 0 ? needed : 0;
  }

  // ── Today's schedule ──────────────────────────────────────

  /// Get the effective timetable entries for a given date.
  List<TimetableEntry> getScheduleForDate(DateTime date) {
    int effectiveDay = date.weekday;

    if (date.weekday == 6) {
      final ws = _db.getWorkingSaturday(date);
      if (ws != null) {
        effectiveDay = ws.followsDayOfWeek;
      } else {
        return [];
      }
    } else if (date.weekday == 7) {
      return [];
    }

    return _db.getEntriesForDay(effectiveDay);
  }

  /// Mark all today's classes as present.
  Future<void> markAllPresent(DateTime date) async {
    final schedule = getScheduleForDate(date);
    for (final entry in schedule) {
      final record = AttendanceRecord(
        date: DateTime(date.year, date.month, date.day),
        subjectId: entry.subjectId,
        status: AttendanceStatus.present,
      );
      await _db.saveAttendanceRecord(record);
    }
  }
}
