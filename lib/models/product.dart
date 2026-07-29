import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  String? category;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String? imagePath;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.category,
    this.imagePath,
    required this.createdAt,
  });

  factory Product.create({
    required String name,
    required double price,
    String? category,
    String? imagePath,
  }) {
    return Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      price: price,
      category: category,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );
  }
}
