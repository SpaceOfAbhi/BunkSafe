import 'package:hive/hive.dart';

class TimetableEntryAdapter extends TypeAdapter<TimetableEntry> {
  @override
  final int typeId = 2;

  @override
  TimetableEntry read(BinaryReader reader) {
    return TimetableEntry(
      dayOfWeek: reader.readInt(),
      slotIndex: reader.readInt(),
      subjectId: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, TimetableEntry obj) {
    writer.writeInt(obj.dayOfWeek);
    writer.writeInt(obj.slotIndex);
    writer.writeString(obj.subjectId);
  }
}

/// Represents a single timetable slot.
/// [dayOfWeek] 1=Monday ... 5=Friday
/// [slotIndex] 0-based period index within the day
class TimetableEntry {
  final int dayOfWeek;
  final int slotIndex;
  final String subjectId;

  TimetableEntry({
    required this.dayOfWeek,
    required this.slotIndex,
    required this.subjectId,
  });

  /// Hive storage key: "day_slot"
  String get key => '${dayOfWeek}_$slotIndex';

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'slotIndex': slotIndex,
        'subjectId': subjectId,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) =>
      TimetableEntry(
        dayOfWeek: json['dayOfWeek'] as int,
        slotIndex: json['slotIndex'] as int,
        subjectId: json['subjectId'] as String,
      );
}
