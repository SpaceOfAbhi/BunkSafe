import 'package:hive/hive.dart';

class WorkingSaturdayAdapter extends TypeAdapter<WorkingSaturday> {
  @override
  final int typeId = 3;

  @override
  WorkingSaturday read(BinaryReader reader) {
    return WorkingSaturday(
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      followsDayOfWeek: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkingSaturday obj) {
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeInt(obj.followsDayOfWeek);
  }
}

/// A Saturday that follows a specific weekday's timetable.
/// [followsDayOfWeek] 1=Monday ... 5=Friday
class WorkingSaturday {
  final DateTime date;
  final int followsDayOfWeek;

  WorkingSaturday({
    required this.date,
    required this.followsDayOfWeek,
  });

  String get key =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static const dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  String get followsDayName => dayNames[followsDayOfWeek];

  Map<String, dynamic> toJson() => {
        'date': date.millisecondsSinceEpoch,
        'followsDayOfWeek': followsDayOfWeek,
      };

  factory WorkingSaturday.fromJson(Map<String, dynamic> json) =>
      WorkingSaturday(
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
        followsDayOfWeek: json['followsDayOfWeek'] as int,
      );
}
