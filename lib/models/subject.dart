import 'package:hive/hive.dart';

class SubjectAdapter extends TypeAdapter<Subject> {
  @override
  final int typeId = 0;

  @override
  Subject read(BinaryReader reader) {
    return Subject(
      id: reader.readString(),
      name: reader.readString(),
      shortCode: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Subject obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.shortCode);
  }
}

class Subject {
  final String id;
  final String name;
  final String shortCode;

  Subject({
    required this.id,
    required this.name,
    required this.shortCode,
  });

  Subject copyWith({String? name, String? shortCode}) {
    return Subject(
      id: id,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortCode': shortCode,
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        shortCode: json['shortCode'] as String,
      );
}
