// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      category: fields[4] as String,
      isExpense: fields[5] as bool,
      mpesaCode: fields[9] as String?,
      isSms: fields[10] as bool,
      rawSms: fields[11] as String?,
      sender: fields[12] as String?,
      recipient: fields[13] as String?,
      agent: fields[14] as String?,
      business: fields[15] as String?,
      balance: fields[16] as double?,
      description: fields[17] as String?,
      iconPath: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.isExpense)
      ..writeByte(6)
      ..write(obj.iconCodePoint)
      ..writeByte(7)
      ..write(obj.iconFontFamily)
      ..writeByte(8)
      ..write(obj.colorValue)
      ..writeByte(9)
      ..write(obj.mpesaCode)
      ..writeByte(10)
      ..write(obj.isSms)
      ..writeByte(11)
      ..write(obj.rawSms)
      ..writeByte(12)
      ..write(obj.sender)
      ..writeByte(13)
      ..write(obj.recipient)
      ..writeByte(14)
      ..write(obj.agent)
      ..writeByte(15)
      ..write(obj.business)
      ..writeByte(16)
      ..write(obj.balance)
      ..writeByte(17)
      ..write(obj.description)
      ..writeByte(18)
      ..write(obj.iconPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
