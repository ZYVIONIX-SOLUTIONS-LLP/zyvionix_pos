import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../database/hive_boxes.dart';
import '../services/api_service.dart';

class ProductController extends ChangeNotifier {
  List<Product> _products = [];
  String _searchQuery = '';

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
    await loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    _products = await ApiService.getProducts();

    _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _products = [];
    _searchQuery = '';
    _isLoading = false;
    notifyListeners();
  }

  void searchProducts(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final success = await ApiService.addProduct(product);
    if (success) await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    final success = await ApiService.updateProduct(product);
    if (success) await loadProducts();
  }

  Future<void> deleteProduct(Product product) async {
    final success = await ApiService.deleteProduct(product.id);
    if (success) await loadProducts();
  }
}
