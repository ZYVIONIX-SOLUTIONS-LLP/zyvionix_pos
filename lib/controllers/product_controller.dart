import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../database/hive_boxes.dart';
import '../services/api_service.dart';
import '../services/backup_service.dart';

class ProductController extends ChangeNotifier {
  Box<Product>? _productsBox;
  List<Product> _products = [];
  String _searchQuery = '';

  bool _isCloud = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Product> get products {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.category!.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  ProductController() {
    init();
  }

  Future<void> init() async {
    final settingsBox = HiveBoxes.getSettingsBox();
    final storageType = settingsBox.get(
      'storageType',
      defaultValue: 'Device Storage',
    );
    _isCloud = storageType == 'Cloud Storage' || storageType == 'cloud';

    if (!_isCloud) {
      _productsBox = HiveBoxes.getProductsBox();
    }
    await loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    if (_isCloud) {
      _products = await ApiService.getProducts();
    } else {
      if (_productsBox != null) {
        _products = _productsBox!.values.toList();
      }
    }

    _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _productsBox = null;
    _products = [];
    _searchQuery = '';
    _isCloud = false;
    _isLoading = false;
    notifyListeners();
  }

  void searchProducts(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    if (_isCloud) {
      final success = await ApiService.addProduct(product);
      if (success) await loadProducts();
    } else {
      if (_productsBox != null) {
        await _productsBox!.put(product.id, product);
        final userId = HiveBoxes.getSettingsBox().get('user_id') ?? '';
        await BackupService.backupData(userId);
        await loadProducts();
      }
    }
  }

  Future<void> updateProduct(Product product) async {
    if (_isCloud) {
      final success = await ApiService.updateProduct(product);
      if (success) await loadProducts();
    } else {
      await product.save();
      final userId = HiveBoxes.getSettingsBox().get('user_id') ?? '';
      await BackupService.backupData(userId);
      await loadProducts();
    }
  }

  Future<void> deleteProduct(Product product) async {
    if (_isCloud) {
      final success = await ApiService.deleteProduct(product.id);
      if (success) await loadProducts();
    } else {
      await product.delete();
      final userId = HiveBoxes.getSettingsBox().get('user_id') ?? '';
      await BackupService.backupData(userId);
      await loadProducts();
    }
  }
}
