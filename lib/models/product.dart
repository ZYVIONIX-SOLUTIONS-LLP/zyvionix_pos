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
  String category;

  @HiveField(4)
  String? description;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String? imagePath;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.description,
    this.imagePath,
    required this.createdAt,
  });

  factory Product.create({
    required String name,
    required double price,
    required String category,
    String? description,
    String? imagePath,
  }) {
    return Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      price: price,
      category: category,
      description: description,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );
  }
}
