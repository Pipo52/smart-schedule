// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final typeId = 7;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      semesterReferenceDate: fields[0] as DateTime,
      manualWeekOverride: (fields[1] as num?)?.toInt(),
      defaultLessonReminderMinutes: fields[2] == null
          ? 10
          : (fields[2] as num).toInt(),
      themeMode: fields[3] == null
          ? AppThemeMode.system
          : fields[3] as AppThemeMode,
      appLocale: fields[4] as String?,
      schemaVersion: fields[5] == null ? 1 : (fields[5] as num).toInt(),
      lastOpenedProfileId: fields[7] as String?,
      startupBehavior: fields[8] == null
          ? StartupBehavior.lastOpened
          : fields[8] as StartupBehavior,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.semesterReferenceDate)
      ..writeByte(1)
      ..write(obj.manualWeekOverride)
      ..writeByte(2)
      ..write(obj.defaultLessonReminderMinutes)
      ..writeByte(3)
      ..write(obj.themeMode)
      ..writeByte(4)
      ..write(obj.appLocale)
      ..writeByte(5)
      ..write(obj.schemaVersion)
      ..writeByte(7)
      ..write(obj.lastOpenedProfileId)
      ..writeByte(8)
      ..write(obj.startupBehavior)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppThemeModeAdapter extends TypeAdapter<AppThemeMode> {
  @override
  final typeId = 8;

  @override
  AppThemeMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppThemeMode.system;
      case 1:
        return AppThemeMode.light;
      case 2:
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  @override
  void write(BinaryWriter writer, AppThemeMode obj) {
    switch (obj) {
      case AppThemeMode.system:
        writer.writeByte(0);
      case AppThemeMode.light:
        writer.writeByte(1);
      case AppThemeMode.dark:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StartupBehaviorAdapter extends TypeAdapter<StartupBehavior> {
  @override
  final typeId = 10;

  @override
  StartupBehavior read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StartupBehavior.defaultProfile;
      case 1:
        return StartupBehavior.lastOpened;
      default:
        return StartupBehavior.defaultProfile;
    }
  }

  @override
  void write(BinaryWriter writer, StartupBehavior obj) {
    switch (obj) {
      case StartupBehavior.defaultProfile:
        writer.writeByte(0);
      case StartupBehavior.lastOpened:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StartupBehaviorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
