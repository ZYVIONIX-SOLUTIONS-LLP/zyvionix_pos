import 'dart:convert';
import 'dart:io';
// import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/product.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../database/hive_boxes.dart';

class BackupService {
  static Future<Directory?> _getPublicDownloadDir() async {
    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final pathSegments = externalDir.path.split('/');
        final androidIndex = pathSegments.indexOf('Android');
        if (androidIndex != -1) {
          final rootPath = pathSegments.sublist(0, androidIndex).join('/');
          final dir = Directory('$rootPath/Download/ZyvionixPOS_Backups');
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return dir;
        }
      }
      // Fallback if the path parsing fails
      final fallbackDir = Directory(
        '/storage/emulated/0/Download/ZyvionixPOS_Backups',
      );
      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }
      return fallbackDir;
    }

    // Fallback for non-Android platforms
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/ZyvionixPOS_Backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted ||
          await Permission.storage.isGranted) {
        return true;
      }

      final manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) return true;

      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true; // Not required for non-Android in this scope
  }

  static Future<File?> _getBackupFile(String userId) async {
    if (userId.isEmpty) return null;

    final granted = await _requestPermissions();
    if (!granted) return null;

    final dir = await _getPublicDownloadDir();
    if (dir == null) return null;

    return File('${dir.path}/backup_$userId.json');
  }

  static Future<bool> checkBackupExists(String userId) async {
    try {
      final file = await _getBackupFile(userId);
      if (file == null) return false;
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  static Future<void> backupData(String userId) async {
    if (userId.isEmpty) return;
    try {
      final file = await _getBackupFile(userId);
      if (file == null) return;

      final box = HiveBoxes.getSettingsBox();
      final productsBox = HiveBoxes.getProductsBox();
      final billsBox = HiveBoxes.getBillsBox();

      if (productsBox == null || billsBox == null) return;

      if (productsBox.isEmpty && billsBox.isEmpty) {
        print("Skipping backup because Hive is empty.");
        return;
      }

      final products = await Future.wait(
        productsBox.values.map((p) async {
          String? base64Image;
          if (p.imagePath != null && p.imagePath!.isNotEmpty) {
            final imgFile = File(p.imagePath!);
            if (await imgFile.exists()) {
              final bytes = await imgFile.readAsBytes();
              base64Image = base64Encode(bytes);
            }
          }
          return {
            'id': p.id,
            'name': p.name,
            'price': p.price,
            'category': p.category,
            'base64Image': base64Image,
            'createdAt': p.createdAt.toIso8601String(),
          };
        }),
      );

      final bills = billsBox.values
          .map(
            (b) => {
              'id': b.id,
              'billNumber': b.billNumber,
              'date': b.date.toIso8601String(),
              'items': b.items
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
              'subTotal': b.subTotal,
              'tax': b.tax,
              'grandTotal': b.grandTotal,
              'paymentMethod': b.paymentMethod,
              'companyName': b.companyName,
              'customerPhone': b.customerPhone,
              'timestamp': b.timestamp.toIso8601String(),
            },
          )
          .toList();

      final payload = {
        'timestamp': DateTime.now().toIso8601String(),
        'userId': userId,
        'offline_company_name': box.get('offline_company_name'),
        'offline_company_address': box.get('offline_company_address'),
        'offline_business_type': box.get('offline_business_type'),
        'offline_email': box.get('offline_email'),
        'offline_gst': box.get('offline_gst'),
        'products': products,
        'bills': bills,
      };

      await file.writeAsString(jsonEncode(payload));
      print(
        'Backup successfulllllllllllllllllllllllllllllllllllllll: ${file.path}',
      );
    } catch (e) {
      print('Backup failed: $e');
    }
  }

  static Future<bool> restoreData(String userId) async {
    try {
      final file = await _getBackupFile(userId);
      if (file == null || !await file.exists()) return false;

      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr);

      print("Backup file: ${file.path}");
      print("JSON: $jsonStr");
      print("Products in JSON: ${(data['products'] as List?)?.length}");
      print("Bills in JSON: ${(data['bills'] as List?)?.length}");

      final box = HiveBoxes.getSettingsBox();
      if (data['offline_company_name'] != null)
        await box.put('offline_company_name', data['offline_company_name']);
      if (data['offline_company_address'] != null)
        await box.put(
          'offline_company_address',
          data['offline_company_address'],
        );
      if (data['offline_business_type'] != null)
        await box.put('offline_business_type', data['offline_business_type']);
      if (data['offline_email'] != null)
        await box.put('offline_email', data['offline_email']);
      if (data['offline_gst'] != null)
        await box.put('offline_gst', data['offline_gst']);

      final appDir = await getApplicationDocumentsDirectory();

      final productsBox = HiveBoxes.getProductsBox();
      final billsBox = HiveBoxes.getBillsBox();
      if (productsBox == null || billsBox == null) return false;

      // Clear existing first
      await productsBox.clear();
      await billsBox.clear();

      final productsList = data['products'] as List?;
      if (productsList != null) {
        for (var p in productsList) {
          String? newImagePath;
          if (p['base64Image'] != null) {
            final bytes = base64Decode(p['base64Image']);
            final imgFile = File('${appDir.path}/img_${p['id']}.jpg');
            await imgFile.writeAsBytes(bytes);
            newImagePath = imgFile.path;
          }
          final product = Product(
            id: p['id'],
            name: p['name'],
            price: (p['price'] as num).toDouble(),
            category: p['category'],
            imagePath: newImagePath,
            createdAt: p['createdAt'] != null
                ? DateTime.parse(p['createdAt'])
                : DateTime.now(),
          );
          await productsBox.put(product.id, product);
        }
      }

      final billsList = data['bills'] as List?;
      if (billsList != null) {
        for (var b in billsList) {
          final itemsList = b['items'] as List;
          final items = itemsList.map<BillItem>((item) {
            return BillItem(
              product: Product(
                id: item['productId'],
                name: item['name'],
                price: (item['price'] as num).toDouble(),
                category: '',
                createdAt: DateTime.now(),
              ),
              quantity: item['quantity'],
              price: (item['price'] as num).toDouble(),
              total: (item['total'] as num).toDouble(),
            );
          }).toList();

          final bill = Bill(
            id: b['id'],
            billNumber: b['billNumber'],
            date: DateTime.parse(b['date']),
            items: items,
            subTotal: (b['subTotal'] as num).toDouble(),
            tax: (b['tax'] as num).toDouble(),
            grandTotal: (b['grandTotal'] as num).toDouble(),
            paymentMethod: b['paymentMethod'],
            companyName: b['companyName'],
            customerPhone: b['customerPhone'],
            timestamp: b['timestamp'] != null
                ? DateTime.parse(b['timestamp'])
                : DateTime.now(),
          );
          await billsBox.put(bill.id, bill);
        }
      }

      print("Products restored: ${productsBox.length}");
      print("Bills restored: ${billsBox.length}");
      print('Restore successful!');
      return true;
    } catch (e) {
      print('Restore failed: $e');
      return false;
    }
  }
}
