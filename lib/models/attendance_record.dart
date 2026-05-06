import 'package:hive/hive.dart';

/// Attendance status for a single class session.
enum AttendanceStatus { present, absent, dutyLeave, holiday }

class AttendanceRecordAdapter extends TypeAdapter<AttendanceRecord> {
  @override
  final int typeId = 1;

  @override
  AttendanceRecord read(BinaryReader reader) {
    return AttendanceRecord(
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      subjectId: reader.readString(),
      status: AttendanceStatus.values[reader.readInt()],
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceRecord obj) {
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeString(obj.subjectId);
    writer.writeInt(obj.status.index);
  }
}

class AttendanceRecord {
  final DateTime date;
  final String subjectId;
  final AttendanceStatus status;

  AttendanceRecord({
    required this.date,
    required this.subjectId,
    required this.status,
  });

  /// Unique key for Hive storage: "YYYY-MM-DD_subjectId"
  String get key =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_$subjectId';

  AttendanceRecord copyWith({AttendanceStatus? status}) {
    return AttendanceRecord(
      date: date,
      subjectId: subjectId,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.millisecondsSinceEpoch,
        'subjectId': subjectId,
        'status': status.index,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
        subjectId: json['subjectId'] as String,
        status: AttendanceStatus.values[json['status'] as int],
      );
}
