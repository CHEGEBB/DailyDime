// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppNotificationAdapter extends TypeAdapter<AppNotification> {
  @override
  final int typeId = 4;

  @override
  AppNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppNotification(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      timestamp: fields[3] as DateTime,
      type: fields[4] as NotificationType,
      isRead: fields[5] as bool,
      data: (fields[6] as Map?)?.cast<String, dynamic>(),
      actionData: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppNotification obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.isRead)
      ..writeByte(6)
      ..write(obj.data)
      ..writeByte(7)
      ..write(obj.actionData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationTypeAdapter extends TypeAdapter<NotificationType> {
  @override
  final int typeId = 5;

  @override
  NotificationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationType.transaction;
      case 1:
        return NotificationType.budget;
      case 2:
        return NotificationType.goal;
      case 3:
        return NotificationType.balance;
      case 4:
        return NotificationType.system;
      case 5:
        return NotificationType.reminder;
      case 6:
        return NotificationType.challenge;
      case 7:
        return NotificationType.alert;
      case 8:
        return NotificationType.achievement;
      default:
        return NotificationType.transaction;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationType obj) {
    switch (obj) {
      case NotificationType.transaction:
        writer.writeByte(0);
        break;
      case NotificationType.budget:
        writer.writeByte(1);
        break;
      case NotificationType.goal:
        writer.writeByte(2);
        break;
      case NotificationType.balance:
        writer.writeByte(3);
        break;
      case NotificationType.system:
        writer.writeByte(4);
        break;
      case NotificationType.reminder:
        writer.writeByte(5);
        break;
      case NotificationType.challenge:
        writer.writeByte(6);
        break;
      case NotificationType.alert:
        writer.writeByte(7);
        break;
      case NotificationType.achievement:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
