import 'package:hive/hive.dart';
import 'product.dart';

part 'bill_item.g.dart';

@HiveType(typeId: 1)
class BillItem extends HiveObject {
  @HiveField(0)
  Product product;

  @HiveField(1)
  int quantity;

  @HiveField(2)
  double price;

  @HiveField(3)
  double total;

  BillItem({
    required this.product,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory BillItem.create({required Product product, required int quantity}) {
    return BillItem(
      product: product,
      quantity: quantity,
      price: product.price,
      total: product.price * quantity,
    );
  }
}
