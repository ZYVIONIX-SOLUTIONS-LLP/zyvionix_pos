import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:zyvionix_pos/controllers/language_controller.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';

class HardwareOrdersScreen extends StatefulWidget {
  const HardwareOrdersScreen({super.key});

  @override
  State<HardwareOrdersScreen> createState() => _HardwareOrdersScreenState();
}

class _HardwareOrdersScreenState extends State<HardwareOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMyOrders();
  }

  Future<void> _fetchMyOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final box = HiveBoxes.getSettingsBox();
      final token = box.get('auth_token', defaultValue: '');

      final response = await http.get(
        Uri.parse('${ApiConstants.hardwareOrdersUrl}/my-orders'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status code for my orderss ${response.statusCode}');
      print('Response  bodyyyyyyyyyyyy for my orderss ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _orders = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load order history';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  int _getStepIndex(String status) {
    switch (status) {
      case 'Placed':
        return 0;
      case 'Processing':
        return 1;
      case 'Shipped':
        return 2;
      case 'Delivered':
        return 3;
      case 'Cancelled':
        return -1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        // title: const Text(
        //   'My  Orders',
        //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        // ),
        title: Text(
          context.tr('my_orders'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMyOrders,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              )
            : _errorMessage.isNotEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetchMyOrders,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _orders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 64,
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hardware orders placed yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your thermal printer and scanner purchases will appear here.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final String orderId = (order['_id'] ?? '').toString();
                  final String shortId = orderId.length >= 8
                      ? orderId.substring(orderId.length - 8).toUpperCase()
                      : orderId;
                  final double amount = (order['amount'] ?? 0).toDouble();
                  final String orderStatus = order['orderStatus'] ?? 'Placed';
                  final String trackingNumber = order['trackingNumber'] ?? '';
                  final List items = order['items'] ?? [];
                  final address = order['shippingAddress'] ?? {};
                  final String createdAtRaw = order['createdAt'] ?? '';

                  String formattedDate = '';
                  if (createdAtRaw.isNotEmpty) {
                    try {
                      final dt = DateTime.parse(createdAtRaw);
                      formattedDate = DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(dt);
                    } catch (_) {}
                  }

                  final currentStep = _getStepIndex(orderStatus);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID & Date Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Color(0xFF4F46E5),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Order #$shortId',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Paid via Razorpay',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (formattedDate.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Purchased Items List
                        ...items.map((item) {
                          final itemName = item['name'] ?? 'Hardware Item';
                          final itemPrice = (item['price'] ?? 0).toDouble();
                          final itemQty = item['quantity'] ?? 1;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '$itemName (x$itemQty)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.grey.shade200
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${itemPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount Paid',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ORDER STATUS TRACKER STEPPER
                        if (orderStatus == 'Cancelled') ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'This order was cancelled.',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Order Tracking Lifecycle',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildTrackerStepper(currentStep, isDark),
                        ],

                        if (trackingNumber.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF4F46E5).withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_shipping_rounded,
                                  color: Color(0xFF4F46E5),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Courier AWB / Tracking #: $trackingNumber',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Delivery Address Snippet
                        if (address['city'] != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Delivering to: ${address['fullName'] ?? ''}, ${address['addressLine1'] ?? ''}, ${address['city'] ?? ''} (${address['pincode'] ?? ''})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTrackerStepper(int currentStep, bool isDark) {
    final steps = ['Placed', 'Processing', 'Shipped', 'Delivered'];

    return Row(
      children: List.generate(steps.length, (idx) {
        final isCompleted = idx <= currentStep;
        final isCurrent = idx == currentStep;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  // Left Line
                  Expanded(
                    child: Container(
                      height: 3,
                      color: idx == 0
                          ? Colors.transparent
                          : (idx <= currentStep
                                ? const Color(0xFF10B981)
                                : (isDark
                                      ? const Color(0xFF334155)
                                      : Colors.grey.shade300)),
                    ),
                  ),
                  // Step Node Circle
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : (isDark
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade200),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : (isDark
                                  ? const Color(0xFF334155)
                                  : Colors.grey.shade400),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            )
                          : Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700,
                              ),
                            ),
                    ),
                  ),
                  // Right Line
                  Expanded(
                    child: Container(
                      height: 3,
                      color: idx == steps.length - 1
                          ? Colors.transparent
                          : (idx < currentStep
                                ? const Color(0xFF10B981)
                                : (isDark
                                      ? const Color(0xFF334155)
                                      : Colors.grey.shade300)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[idx],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent
                      ? const Color(0xFF10B981)
                      : (isCompleted
                            ? (isDark ? Colors.white : Colors.orange.shade800)
                            : Colors.grey),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
