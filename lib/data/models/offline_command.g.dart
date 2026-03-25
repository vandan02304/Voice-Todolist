// ---------------------------------------------------------------------------
// Hive-generated TypeAdapters for OfflineCommand and CommandType.
// Run `flutter pub run build_runner build` to regenerate this file.
// ---------------------------------------------------------------------------

// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use

part of 'offline_command.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineCommandAdapter extends TypeAdapter<OfflineCommand> {
  @override
  final int typeId = 3;

  @override
  OfflineCommand read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineCommand(
      id: fields[0] as String,
      type: fields[1] as CommandType,
      taskId: fields[2] as String,
      payload: fields[3] as Map,
      timestamp: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineCommand obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.taskId)
      ..writeByte(3)
      ..write(obj.payload)
      ..writeByte(4)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineCommandAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CommandTypeAdapter extends TypeAdapter<CommandType> {
  @override
  final int typeId = 2;

  @override
  CommandType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CommandType.create;
      case 1:
        return CommandType.update;
      case 2:
        return CommandType.delete;
      case 3:
        return CommandType.complete;
      case 4:
        return CommandType.uncomplete;
      default:
        return CommandType.create;
    }
  }

  @override
  void write(BinaryWriter writer, CommandType obj) {
    switch (obj) {
      case CommandType.create:
        writer.writeByte(0);
        break;
      case CommandType.update:
        writer.writeByte(1);
        break;
      case CommandType.delete:
        writer.writeByte(2);
        break;
      case CommandType.complete:
        writer.writeByte(3);
        break;
      case CommandType.uncomplete:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommandTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
