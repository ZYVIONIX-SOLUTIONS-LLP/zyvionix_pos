// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/controllers/bill_controller.dart';
import 'package:zyvionix_pos/models/product.dart';
import 'package:zyvionix_pos/views/billing/cart_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  String selectedCategory = "All";

  final List<Map<String, dynamic>> products = [
    {
      "name": "Burger",
      "price": 180,
      "category": "Fast Food",
      "rating": 4.5,
      "image":
          "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300",
    },
    {
      "name": "Pizza",
      "price": 350,
      "category": "Italian",
      "rating": 4.8,
      "image":
          "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=300",
    },
    {
      "name": "Chicken Biryani",
      "price": 220,
      "category": "Meals",
      "rating": 4.7,
      "image":
          "https://images.unsplash.com/photo-1701579231378-37291cfd5d9b?w=300",
    },
    {
      "name": "Porotta",
      "price": 20,
      "category": "Kerala",
      "rating": 4.9,
      "image":
          "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=300",
    },
    {
      "name": "Tea",
      "price": 15,
      "category": "Drinks",
      "rating": 4.3,
      "image":
          "https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=300",
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BillController>();

    final filteredProducts = searchController.text.isEmpty
        ? products.where((product) {
            return controller.cart.any((item) => item.product.name == product["name"]);
          }).toList()
        : products.where((product) {
            final matchesQuery = product["name"].toLowerCase().contains(
              searchController.text.toLowerCase(),
            );
            final matchesCategory =
                selectedCategory == "All" || product["category"] == selectedCategory;
            return matchesQuery && matchesCategory;
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'proceed',
        onPressed: () {
          // Hide keyboard when navigating to Cart
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
              color: Colors.white,
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
                              // DO NOT unfocus here to keep keyboard open
                              searchFocusNode.requestFocus();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            searchController.text.isEmpty
                                ? Icons.search_rounded
                                : Icons.search_off_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            searchController.text.isEmpty
                                ? "Search for a product"
                                : "No items found",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final productMap = filteredProducts[index];
                        final isInCart = controller.cart.any((item) => item.product.name == productMap["name"]);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isInCart ? Colors.blue.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isInCart ? Colors.blue : Colors.transparent,
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
                                final product = Product.create(
                                  name: productMap["name"],
                                  price: (productMap["price"] as num).toDouble(),
                                  category: productMap["category"],
                                );
                                controller.addToCart(product);
                              } else {
                                final itemToRemove = controller.cart.firstWhere(
                                  (item) => item.product.name == productMap["name"],
                                );
                                controller.removeFromCart(itemToRemove);
                              }
                              
                              setState(() {
                                searchController.clear();
                                // Keep keyboard open!
                                searchFocusNode.requestFocus();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      productMap["image"],
                                      width: 65,
                                      height: 65,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 65,
                                              height: 65,
                                              color: Colors.orange.shade50,
                                              child: const Icon(
                                                Icons.fastfood_rounded,
                                                color: Colors.orange,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productMap["name"],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            productMap["category"],
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "₹${productMap["price"]}",
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isInCart)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 12),
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
