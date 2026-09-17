import 'package:hive_ce/hive.dart';

part 'schedule_profile.g.dart';

@HiveType(typeId: 9)
class ScheduleProfile extends HiveObject {
  ScheduleProfile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.isDefault,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  bool isDefault;

  ScheduleProfile copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return ScheduleProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
