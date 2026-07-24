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
  double discount;

  @HiveField(6)
  double tax;

  @HiveField(7)
  double grandTotal;

  @HiveField(8)
  String paymentMethod;

  @HiveField(9)
  String? customerName;

  @HiveField(10)
  String? customerPhone;

  Bill({
    required this.id,
    required this.billNumber,
    required this.date,
    required this.items,
    required this.subTotal,
    required this.discount,
    required this.tax,
    required this.grandTotal,
    required this.paymentMethod,
    this.customerName,
    this.customerPhone,
  });
}
