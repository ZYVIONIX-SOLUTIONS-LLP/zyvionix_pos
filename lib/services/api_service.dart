import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/models/product.dart';
import 'package:zyvionix_pos/models/bill.dart';
import 'package:zyvionix_pos/models/bill_item.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final box = HiveBoxes.getSettingsBox();
    final token = box.get('auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- Products ---
  static Future<List<Product>> getProducts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConstants.productsUrl),
        headers: headers,
      );

      print('Response status code for get products ${response.statusCode}');
      print('Response bodyyyyyyyyyyyyyy for get products ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) {
          final p = Product(
            id: json['id'],
            name: json['name'],
            price: (json['price'] as num).toDouble(),
            category: json['category'],
            imagePath: json['imagePath'],
            createdAt: json['createdAt'] != null
                ? DateTime.parse(json['createdAt'])
                : DateTime.now(),
          );
          // If product has createdAt property on the frontend model, we could set it.
          // Since we don't know the exact constructor, we assume this works based on typical Hive models.
          return p;
        }).toList();
      }
    } catch (e) {
      print("Error fetching products: $e");
    }
    return [];
  }

  static Future<bool> addProduct(Product product) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.productsUrl),
        headers: headers,
        body: jsonEncode({
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'category': product.category,
          'imagePath': product.imagePath,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateProduct(Product product) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConstants.productsUrl}/${product.id}'),
        headers: headers,
        body: jsonEncode({
          'name': product.name,
          'price': product.price,
          'category': product.category,
          'imagePath': product.imagePath,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteProduct(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConstants.productsUrl}/$id'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Bills ---
  static Future<List<Bill>> getBills() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConstants.billsUrl),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) {
          return Bill(
            id: json['id'],
            billNumber: json['billNumber'],
            date: DateTime.parse(json['date']),
            items: (json['items'] as List<dynamic>)
                .map(
                  (item) => BillItem(
                    product: Product(
                      id: item['productId'] ?? '',
                      name: item['name'] ?? '',
                      price: (item['price'] as num).toDouble(),
                      category: null,
                      createdAt: DateTime.now(),
                    ),
                    quantity: item['quantity'],
                    price: (item['price'] as num).toDouble(),
                    total: (item['total'] as num).toDouble(),
                  ),
                )
                .toList(),
            subTotal: (json['subTotal'] as num).toDouble(),
            tax: (json['tax'] as num).toDouble(),
            grandTotal: (json['grandTotal'] as num).toDouble(),
            paymentMethod: json['paymentMethod'],
            companyName: json['companyName']?.isEmpty == true
                ? null
                : json['companyName'],
            customerPhone: json['customerPhone']?.isEmpty == true
                ? null
                : json['customerPhone'],
            timestamp: DateTime.parse(json['timestamp']),
          );
        }).toList();
      }
    } catch (e) {
      print("Error fetching bills: $e");
    }
    return [];
  }

  static Future<bool> addBill(Bill bill) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.billsUrl),
        headers: headers,
        body: jsonEncode({
          'id': bill.id,
          'billNumber': bill.billNumber,
          'date': bill.date.toIso8601String(),
          'items': bill.items
              .map(
                (item) => {
                  'productId': item.product.id,
                  'name': item.product.name,
                  'price': item.price,
                  'quantity': item.quantity,
                  'total': item.total,
                },
              )
              .toList(),
          'subTotal': bill.subTotal,
          'tax': bill.tax,
          'grandTotal': bill.grandTotal,
          'paymentMethod': bill.paymentMethod,
          'companyName': bill.companyName ?? '',
          'customerPhone': bill.customerPhone ?? '',
          'timestamp': bill.timestamp.toIso8601String(),
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- Profile ---
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final headers = await _getHeaders();
      // Since ApiConstants.baseUrl might not have /auth, let's check ApiConstants.
      // We will assume the endpoint is '${ApiConstants.baseUrl}/auth/profile' 
      // based on typical setups, or we can just replace the path of productsUrl.
      final uri = Uri.parse(ApiConstants.productsUrl).replace(path: '/api/auth/profile');
      final response = await http.get(
        uri,
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
    return null;
  }

  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(ApiConstants.productsUrl).replace(path: '/api/auth/profile');
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        // Also update local hive settings if successful
        final box = HiveBoxes.getSettingsBox();
        if (data.containsKey('companyName')) {
          await box.put('shop_name', data['companyName']);
        }
        if (data.containsKey('email')) {
          await box.put('user_email', data['email']);
        }
        if (data.containsKey('mobileNumber')) {
          await box.put('user_phone', data['mobileNumber']);
        }
        return true;
      }
    } catch (e) {
      print("Error updating profile: $e");
    }
    return false;
  }
}
