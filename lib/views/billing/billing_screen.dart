import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/controllers/language_controller.dart';
import 'package:zyvionix_pos/provider/navbar/navbar_provider.dart';
import 'package:zyvionix_pos/views/products/product_list_screen.dart';
import 'package:zyvionix_pos/views/products/add_edit_product_screen.dart';
import 'package:zyvionix_pos/utils/subscription_helper.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import '../../controllers/bill_controller.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import '../../constants/app_theme.dart';
import 'cart_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String _selectedCategory = 'All';
  final Set<String> _selectedProductIds = {};

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isEmployee = false;

  @override
  void initState() {
    super.initState();
    final box = HiveBoxes.getSettingsBox();
    _isEmployee = box.get('user_role') == 'Employee';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit'),
          content: const Text('Are you sure you want to exit?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<BottomNavbarProvider>().setIndex(0);
              },
              child: const Text('Exit', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductController>().products;

    // Dynamically build categories
    final Set<String> uniqueCategories = {'All'};
    for (var p in products) {
      final cat = (p.category?.isNotEmpty == true)
          ? p.category!
          : 'Uncategorized';
      uniqueCategories.add(cat);
    }
    final categories = uniqueCategories.toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              context.read<BottomNavbarProvider>().setIndex(0);
            },
            icon: const Icon(Icons.arrow_back_ios),
          ),
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                )
              : Text(
                  context.tr('products'),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          centerTitle: !_isSearching,
          automaticallyImplyLeading: false,
          actions: [
            if (!_isEmployee)
              IconButton(
                icon: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                tooltip: 'Add Product',
                onPressed: () async {
                  final canProceed =
                      await SubscriptionHelper.checkAndEnforcePlan(context);
                  if (!canProceed) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddEditProductScreen(),
                    ),
                  );
                },
              ),
            if (_selectedProductIds.length == 1 && !_isEmployee)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                tooltip: 'Edit Product',
                onPressed: () {
                  final selectedId = _selectedProductIds.first;
                  final selectedProduct = products.firstWhere(
                    (p) => p.id == selectedId,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddEditProductScreen(product: selectedProduct),
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: 'Product List',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductListScreen()),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (!_isSearching) _buildCategories(categories),
                Expanded(
                  child: _isSearching
                      ? _buildSearchResults(products)
                      : _buildProductsGrid(products),
                ),
                const SizedBox(height: 100),
              ],
            ),
            if (_selectedProductIds.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 25,
                child: _buildBottomBar(products),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(List<String> categories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 60,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(List<Product> products) {
    final query = _searchQuery.toLowerCase();
    final results = products.where((p) {
      final name = p.name.toLowerCase();
      return name.contains(query);
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No products found.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        final isSelected = _selectedProductIds.contains(item.id);

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12.0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imagePath != null
                  ? (item.imagePath!.startsWith('http')
                        ? Image.network(
                            item.imagePath!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.fastfood,
                                    color: Colors.grey,
                                  ),
                                ),
                          )
                        : Image.file(
                            File(item.imagePath!),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.fastfood,
                                    color: Colors.grey,
                                  ),
                                ),
                          ))
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
            ),
            title: Text(
              item.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '₹${item.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedProductIds.remove(item.id);
                } else {
                  _selectedProductIds.add(item.id);
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid(List<Product> products) {
    final filteredProducts = _selectedCategory == 'All'
        ? products
        : products.where((p) {
            final cat = (p.category?.isNotEmpty == true)
                ? p.category!
                : 'Uncategorized';
            return cat == _selectedCategory;
          }).toList();

    if (filteredProducts.isEmpty) {
      return const Center(
        child: Text(
          'No products in this category.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final item = filteredProducts[index];
        final isSelected = _selectedProductIds.contains(item.id);

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedProductIds.remove(item.id);
              } else {
                _selectedProductIds.add(item.id);
              }
            });
          },
          borderRadius: BorderRadius.circular(0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(0),
                          topRight: Radius.circular(0),
                        ),
                        child: item.imagePath != null
                            ? (item.imagePath!.startsWith('http')
                                  ? Image.network(
                                      item.imagePath!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.fastfood,
                                                color: Colors.grey,
                                                size: 30,
                                              ),
                                            );
                                          },
                                    )
                                  : Image.file(
                                      File(item.imagePath!),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.fastfood,
                                                color: Colors.grey,
                                                size: 30,
                                              ),
                                            );
                                          },
                                    ))
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Colors.grey,
                                  size: 30,
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            item.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(List<Product> products) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: () {
          final billController = context.read<BillController>();
          billController.clearCart();

          for (final id in _selectedProductIds) {
            try {
              final product = products.firstWhere((p) => p.id == id);
              billController.addToCart(product);
            } catch (e) {
              // Ignore if product not found
            }
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ).then((_) {
            if (mounted) {
              setState(() {
                _selectedProductIds.clear();
                final currentCart = context.read<BillController>().cart;
                for (var item in currentCart) {
                  _selectedProductIds.add(item.product.id);
                }
              });
            }
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Proceed with ${_selectedProductIds.length} item(s)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
