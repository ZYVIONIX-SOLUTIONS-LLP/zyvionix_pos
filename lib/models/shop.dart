import 'package:hive/hive.dart';

part 'shop.g.dart';

@HiveType(typeId: 4)
class Shop extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String ownerId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String address;

  @HiveField(4)
  String mobile;

  @HiveField(5)
  String? gst;

  @HiveField(6)
  String? email;

  Shop({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.mobile,
    this.gst,
    this.email,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['_id'],
      ownerId: json['ownerId'],
      name: json['name'],
      address: json['address'],
      mobile: json['mobile'],
      gst: json['gst'],
      email: json['email'],
    );
  }
}
