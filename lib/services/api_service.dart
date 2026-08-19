import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/models/product.dart';
import 'package:zyvionix_pos/models/bill.dart';
import 'package:zyvionix_pos/models/bill_item.dart';
import 'package:flutter/material.dart';
import 'package:zyvionix_pos/main.dart';
import 'package:zyvionix_pos/provider/auth_provider.dart';
import 'package:zyvionix_pos/views/auth/login_screen.dart';

class ApiService {
  static void _checkDeviceLock(http.Response response) {
    if (response.statusCode == 401) {
      try {
        final data = jsonDecode(response.body);
        if (data['code'] == 'DEVICE_LOGGED_OUT') {
          AuthProvider().logout();

          if (navigatorKey.currentState != null) {
            showDialog(
              context: navigatorKey.currentState!.context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Session Expired'),
                content: Text(data['message'] ?? 'Logged out.'),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      navigatorKey.currentState!.pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        // Ignore decode errors
      }
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    final box = HiveBoxes.getSettingsBox();
    final token = box.get('auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Product>> getProducts() async {
    try {
      final headers = await _getHeaders();
      final box = HiveBoxes.getSettingsBox();
      final shopId = box.get('shop_id');
      final url = shopId != null
          ? '${ApiConstants.productsUrl}?shopId=$shopId'
          : ApiConstants.productsUrl;
      final response = await http.get(Uri.parse(url), headers: headers);

      _checkDeviceLock(response);

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
      final box = HiveBoxes.getSettingsBox();
      final shopId = box.get('shop_id');
      final body = {
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'category': product.category,
        'imagePath': product.imagePath,
      };
      if (shopId != null) body['shopId'] = shopId;

      final response = await http.post(
        Uri.parse(ApiConstants.productsUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      _checkDeviceLock(response);

      print('Response status code for add product ${response.statusCode}');
      print('Response bodyyyyyyyyyyyyyyyy for add product ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateProduct(Product product) async {
    try {
      final headers = await _getHeaders();
      final box = HiveBoxes.getSettingsBox();
      final shopId = box.get('shop_id');
      final body = {
        'name': product.name,
        'price': product.price,
        'category': product.category,
        'imagePath': product.imagePath,
      };
      if (shopId != null) body['shopId'] = shopId;

      final response = await http.put(
        Uri.parse('${ApiConstants.productsUrl}/${product.id}'),
        headers: headers,
        body: jsonEncode(body),
      );

      _checkDeviceLock(response);

      print('Response status code for updateee product ${response.statusCode}');
      print(
        'Response bodyyyyyyyyyyyyyyyy for updateeeee product ${response.body}',
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
      _checkDeviceLock(response);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Bills ---
  static Future<List<Bill>> getBills() async {
    try {
      final headers = await _getHeaders();
      final box = HiveBoxes.getSettingsBox();
      final shopId = box.get('shop_id');
      final url = shopId != null
          ? '${ApiConstants.billsUrl}?shopId=$shopId'
          : ApiConstants.billsUrl;
      final response = await http.get(Uri.parse(url), headers: headers);
      _checkDeviceLock(response);
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
      final box = HiveBoxes.getSettingsBox();
      final shopId = box.get('shop_id');

      final body = {
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
      };

      if (shopId != null) body['shopId'] = shopId;

      final response = await http.post(
        Uri.parse(ApiConstants.billsUrl),
        headers: headers,
        body: jsonEncode(body),
      );
      _checkDeviceLock(response);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- Profile ---
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
        ApiConstants.productsUrl,
      ).replace(path: '/api/auth/profile');
      final response = await http.get(uri, headers: headers);
      _checkDeviceLock(response);
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
      final uri = Uri.parse(
        ApiConstants.productsUrl,
      ).replace(path: '/api/auth/profile');
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(data),
      );
      _checkDeviceLock(response);
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

  static Future<Map<String, dynamic>> syncToCloud(
    Map<String, dynamic> payload,
  ) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
        ApiConstants.productsUrl,
      ).replace(path: '/api/auth/sync-to-cloud');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );
      _checkDeviceLock(response);

      final data = jsonDecode(response.body);

      print(
        'Response status code for updating to cloud storage ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to convert to cloud',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again later.',
      };
    }
  }

  // static Future<Map<String, dynamic>> syncToCloud(
  //   Map<String, dynamic> payload,
  // ) async {
  //   try {
  //     final headers = await _getHeaders();
  //     final uri = Uri.parse(
  //       ApiConstants.productsUrl,
  //     ).replace(path: '/api/auth/sync-to-cloud');

  //     final response = await http.post(
  //       uri,
  //       headers: headers,
  //       body: jsonEncode(payload),
  //     );

  //     final data = jsonDecode(response.body);

  //     if (response.statusCode == 200) {
  //       return {'success': true, 'data': data};
  //     } else {
  //       return {
  //         'success': false,
  //         'message': data['message'] ?? 'Failed to sync to cloud',
  //       };
  //     }
  //   } catch (e) {
  //     return {
  //       'success': false,
  //       'message': 'Connection error. Please try again later.',
  //     };
  //   }
  // }
}
