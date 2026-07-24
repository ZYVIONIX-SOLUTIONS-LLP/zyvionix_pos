// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BillAdapter extends TypeAdapter<Bill> {
  @override
  final int typeId = 2;

  @override
  Bill read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Bill(
      id: fields[0] as String,
      billNumber: fields[1] as int,
      date: fields[2] as DateTime,
      items: (fields[3] as List).cast<BillItem>(),
      subTotal: fields[4] as double,
      discount: fields[5] as double,
      tax: fields[6] as double,
      grandTotal: fields[7] as double,
      paymentMethod: fields[8] as String,
      customerName: fields[9] as String?,
      customerPhone: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Bill obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.billNumber)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.subTotal)
      ..writeByte(5)
      ..write(obj.discount)
      ..writeByte(6)
      ..write(obj.tax)
      ..writeByte(7)
      ..write(obj.grandTotal)
      ..writeByte(8)
      ..write(obj.paymentMethod)
      ..writeByte(9)
      ..write(obj.customerName)
      ..writeByte(10)
      ..write(obj.customerPhone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
