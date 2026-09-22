// ignore_for_file: unused_local_variable

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/controllers/bill_controller.dart';
import 'package:zyvionix_pos/controllers/product_controller.dart';
import 'package:zyvionix_pos/views/billing/cart_screen.dart';
import 'package:zyvionix_pos/views/products/add_edit_product_screen.dart';
import 'package:zyvionix_pos/utils/subscription_helper.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  String selectedCategory = "All";
  bool _isEmployee = false;

  @override
  void initState() {
    super.initState();
    final box = HiveBoxes.getSettingsBox();
    _isEmployee = box.get('user_role') == 'Employee';
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BillController>();
    final productList = context.watch<ProductController>().products;

    final query = searchController.text.trim().toLowerCase();
    final filteredProducts = productList.where((product) {
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          (product.category != null && product.category!.toLowerCase().contains(query));
      final cat = (product.category?.isNotEmpty == true)
          ? product.category!
          : 'Uncategorized';
      final matchesCategory =
          selectedCategory == "All" || cat == selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'proceed',
        onPressed: () {
          searchFocusNode.unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
        },
        backgroundColor: const Color(0xFF165FF2),
        elevation: 4,
        icon: const Icon(
          Icons.shopping_cart_checkout_rounded,
          color: Colors.white,
        ),
        label: Text(
          'Proceed (${controller.cart.length})',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: "Search dishes, drinks...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.grey,
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    searchController.clear();
                                    searchFocusNode.requestFocus();
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  if (!_isEmployee) ...[
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1EA1F2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF1EA1F2)),
                        onPressed: () async {
                          final canProceed = await SubscriptionHelper.checkAndEnforcePlan(context);
                          if (!canProceed) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddEditProductScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),

                          // Lottie.asset(
                          //   'assets/empty_search.json',
                          //   width: 250,
                          //   height: 250,
                          //   fit: BoxFit.contain,
                          //   errorBuilder: (context, error, stackTrace) {
                          //     return Icon(
                          //       Icons.search_off_rounded,
                          //       size: 80,
                          //       color: Colors.grey.shade400,
                          //     );
                          //   },
                          // ),
                          const SizedBox(height: 16),
                          Text(
                            productList.isEmpty
                                ? 'No products added yet. Click + to add your first product!'
                                : 'No products found matching your search',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final productObj = filteredProducts[index];
                        final isInCart = controller.cart.any(
                          (item) => item.product.id == productObj.id,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isInCart
                                ? (isDark ? const Color(0xFF1E3A8A) : Colors.blue.shade50)
                                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isInCart
                                  ? Colors.blue
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (!isInCart) {
                                controller.addToCart(productObj);
                              } else {
                                final itemToRemove = controller.cart.firstWhere(
                                  (item) => item.product.id == productObj.id,
                                );
                                controller.removeFromCart(itemToRemove);
                              }

                              setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: productObj.imagePath != null
                                        ? (productObj.imagePath!.startsWith(
                                                'http',
                                              )
                                              ? Image.network(
                                                  productObj.imagePath!,
                                                  width: 65,
                                                  height: 65,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          width: 65,
                                                          height: 65,
                                                          color: Colors
                                                              .orange
                                                              .shade50,
                                                          child: const Icon(
                                                            Icons
                                                                .fastfood_rounded,
                                                            color:
                                                                Colors.orange,
                                                          ),
                                                        );
                                                      },
                                                )
                                              : Image.file(
                                                  File(productObj.imagePath!),
                                                  width: 65,
                                                  height: 65,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          width: 65,
                                                          height: 65,
                                                          color: Colors
                                                              .orange
                                                              .shade50,
                                                          child: const Icon(
                                                            Icons
                                                                .fastfood_rounded,
                                                            color:
                                                                Colors.orange,
                                                          ),
                                                        );
                                                      },
                                                ))
                                        : Container(
                                            width: 65,
                                            height: 65,
                                            color: Colors.orange.shade50,
                                            child: const Icon(
                                              Icons.fastfood_rounded,
                                              color: Colors.orange,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productObj.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (productObj.category != null &&
                                            productObj.category!.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              productObj.category!,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "₹${productObj.price.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!_isEmployee)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.grey,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AddEditProductScreen(
                                                  product: productObj,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  if (isInCart)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
