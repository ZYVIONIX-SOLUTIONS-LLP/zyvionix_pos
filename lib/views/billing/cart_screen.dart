import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zyvionix_pos/controllers/language_controller.dart';
import 'package:zyvionix_pos/utils/subscription_helper.dart';
import 'package:provider/provider.dart';
import '../../controllers/bill_controller.dart';
import 'bill_preview_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            final billController = Provider.of<BillController>(
              context,
              listen: false,
            );
            if (billController.editingBill != null) {
              billController.clearCart();
            }
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          context.tr('your_cart'),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Consumer<BillController>(
        builder: (context, controller, child) {
          if (controller.cart.isEmpty) {
            return Center(
              child: Text(
                context.tr('cart_is_empty'),
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
              // child: Text(
              //   'Cart is empty',
              //   style: TextStyle(color: Colors.black54, fontSize: 16),
              // ),
            );
          }

          final stripColors = [
            Colors.green.shade600,
            Colors.pink.shade400,
            Colors.orange.shade500,
            Colors.blue.shade500,
            Colors.purple.shade400,
          ];

          final totalItems = controller.cart.fold(
            0,
            (sum, item) => sum + item.quantity,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Items List
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = controller.cart[index];
                      final color = stripColors[index % stripColors.length];

                      return IntrinsicHeight(
                        child: Row(
                          children: [
                            // Left Color Strip
                            Container(
                              width: 6,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.only(
                                  topLeft: index == 0
                                      ? const Radius.circular(12)
                                      : Radius.zero,
                                  bottomLeft:
                                      index == controller.cart.length - 1
                                      ? const Radius.circular(12)
                                      : Radius.zero,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item.product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    // Quantity Controls
                                    Row(
                                      children: [
                                        _buildQtyButton(
                                          Icons.remove,
                                          () => controller.updateQuantity(
                                            item,
                                            -1,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 32,
                                          child: Text(
                                            '${item.quantity}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        _buildQtyButton(
                                          Icons.add,
                                          () => controller.updateQuantity(
                                            item,
                                            1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    // Price
                                    SizedBox(
                                      width: 45,
                                      child: Text(
                                        '₹${item.total.toStringAsFixed(0)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Delete Icon
                                    GestureDetector(
                                      onTap: () {
                                        controller.removeFromCart(item);
                                        if (controller.cart.isEmpty) {
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Total Info Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: Colors.green.shade700,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // const Text(
                              //   'ITEMS',
                              //   style: TextStyle(
                              //     color: Colors.grey,
                              //     fontSize: 10,
                              //     fontWeight: FontWeight.bold,
                              //     letterSpacing: 0.5,
                              //   ),
                              // ),
                              Text(
                                context.tr('items_label'),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '$totalItems',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey.shade300,
                      ),
                      Row(
                        children: [
                          // const Text(
                          //   'TOTAL',
                          //   style: TextStyle(
                          //     color: Colors.grey,
                          //     fontSize: 12,
                          //     fontWeight: FontWeight.bold,
                          //     letterSpacing: 0.5,
                          //   ),
                          // ),
                          Text(
                            context.tr('total_label'),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '₹${controller.grandTotal.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E6C45),
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    // Check subscription before allowing checkout
                    final canProceed =
                        await SubscriptionHelper.checkAndEnforcePlan(context);
                    if (!canProceed) return;

                    final bill = await controller.saveBill();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BillPreviewScreen(bill: bill),
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.print_outlined, color: Colors.white),
                      const SizedBox(width: 12),

                      // Expanded(
                      //   child: Text(
                      //     controller.editingBill != null
                      //         ? 'UPDATE / PRINT BILL'
                      //         : 'PAY / PRINT BILL',
                      //     style: const TextStyle(
                      //       color: Colors.white,
                      //       fontWeight: FontWeight.bold,
                      //       fontSize: 15,
                      //       letterSpacing: 0.5,
                      //     ),
                      //   ),
                      // ),
                      Expanded(
                        child: Text(
                          controller.editingBill != null
                              ? context.tr('update_print_bill')
                              : context.tr('pay_print_bill'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${controller.grandTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF1E6C45),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD54F),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_shopping_cart,
                              color: Colors.black87,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              context.tr('add_more'),
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          controller.clearCart();
                          Navigator.pop(context);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              context.tr('clear'),
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
  //   return InkWell(
  //     onTap: onTap,
  //     borderRadius: BorderRadius.circular(8),
  //     child: Container(
  //       padding: const EdgeInsets.all(4),
  //       decoration: BoxDecoration(
  //         border: Border.all(color: Colors.grey.shade300),
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: Icon(icon, size: 14, color: Colors.black87),
  //     ),
  //   );
  // }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }
}
