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
  String selectedCategory = "All";
  Set<String> selectedProductNames = {};

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
    super.dispose();
  }

  void _proceedToCart() {
    final controller = context.read<BillController>();

    // Add all selected products to the cart
    for (var productName in selectedProductNames) {
      final prodMap = products.firstWhere((p) => p["name"] == productName);
      final product = Product.create(
        name: prodMap["name"],
        price: (prodMap["price"] as num).toDouble(),
        category: prodMap["category"],
      );
      controller.addToCart(product);
    }

    // Clear selection so if they come back it's fresh (optional, but good UX)
    setState(() {
      selectedProductNames.clear();
    });

    // Navigate to Cart Screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      "All",
      ...products.map((e) => e["category"] as String).toSet(),
    ];

    final filteredProducts = products.where((product) {
      final matchesQuery = product["name"].toLowerCase().contains(
        searchController.text.toLowerCase(),
      );
      final matchesCategory =
          selectedCategory == "All" || product["category"] == selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: selectedProductNames.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _proceedToCart,
              backgroundColor: const Color.fromARGB(255, 91, 91, 238),
              elevation: 4,
              icon: const Icon(
                Icons.shopping_cart_checkout_rounded,
                color: Colors.white,
              ),
              label: Text(
                'Proceed (${selectedProductNames.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Delicious Food",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Discover & Order",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Modern Search Bar
                  TextField(
                    controller: searchController,
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
                  const SizedBox(height: 16),
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
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No items found",
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
                        final product = filteredProducts[index];
                        final isSelected = selectedProductNames.contains(
                          product["name"],
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedProductNames.remove(product["name"]);
                                } else {
                                  selectedProductNames.add(product["name"]);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      product["image"],
                                      width: 85,
                                      height: 85,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 85,
                                              height: 85,
                                              color: Colors.orange.shade50,
                                              child: const Icon(
                                                Icons.fastfood_rounded,
                                                color: Colors.orange,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              product["name"],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            product["category"],
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "₹${product["price"]}",
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Add Button Action
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.green
                                          : Colors.blue.shade700,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        isSelected
                                            ? Icons.check_rounded
                                            : Icons.add_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
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
