import 'package:hive/hive.dart';

part 'employee.g.dart';

@HiveType(typeId: 5)
class Employee extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String shopId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String role;

  @HiveField(4)
  String mobileNumber;

  Employee({
    required this.id,
    required this.shopId,
    required this.name,
    required this.role,
    required this.mobileNumber,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'],
      shopId: json['shopId'],
      name: json['name'],
      role: json['role'],
      mobileNumber: json['mobileNumber'],
    );
  }
}
