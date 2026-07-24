import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../database/hive_boxes.dart';

class ProductController extends ChangeNotifier {
  late Box<Product> _productsBox;
  List<Product> _products = [];
  String _searchQuery = '';

  List<Product> get products {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                      p.category.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  ProductController() {
    _productsBox = HiveBoxes.getProductsBox();
    _loadProducts();
  }

  void _loadProducts() {
    _products = _productsBox.values.toList();
    _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  void searchProducts(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await _productsBox.put(product.id, product);
    _loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await product.save();
    _loadProducts();
  }

  Future<void> deleteProduct(Product product) async {
    await product.delete();
    _loadProducts();
  }
}
