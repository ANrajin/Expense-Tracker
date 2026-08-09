// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentAdapter extends TypeAdapter<Investment> {
  @override
  final int typeId = 3;

  @override
  Investment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Investment(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      investedAmount: fields[3] as double,
      currentValue: fields[4] as double,
      date: fields[5] as String,
      valuedDate: fields[6] as String,
      note: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Investment obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.investedAmount)
      ..writeByte(4)
      ..write(obj.currentValue)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.valuedDate)
      ..writeByte(7)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
