import 'package:hive/hive.dart';
import 'bill_item.dart';

part 'bill.g.dart';

@HiveType(typeId: 2)
class Bill extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int billNumber;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  List<BillItem> items;

  @HiveField(4)
  double subTotal;

  @HiveField(5)
  double tax;

  @HiveField(6)
  double grandTotal;

  @HiveField(7)
  String paymentMethod;

  @HiveField(8)
  String? companyName;

  @HiveField(9)
  String? customerPhone;

  @HiveField(10)
  DateTime timestamp;

  Bill({
    required this.id,
    required this.billNumber,
    required this.date,
    required this.items,
    required this.subTotal,
    required this.tax,
    required this.grandTotal,
    required this.paymentMethod,
    this.companyName,
    this.customerPhone,
    required this.timestamp,
  });
}
