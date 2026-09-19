import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/views/hardware/hardware_orders_screen.dart';

class HardwareAddressCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const HardwareAddressCheckoutScreen({super.key, required this.product});

  @override
  State<HardwareAddressCheckoutScreen> createState() =>
      _HardwareAddressCheckoutScreenState();
}

class _HardwareAddressCheckoutScreenState
    extends State<HardwareAddressCheckoutScreen> {
  late Razorpay _razorpay;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _autoFillAddressFromSettings();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _autoFillAddressFromSettings() {
    final box = HiveBoxes.getSettingsBox();
    final name = box.get('user_name') ?? box.get('shop_name') ?? '';
    final phone = box.get('user_phone') ?? box.get('phone') ?? '';
    final address = box.get('address') ?? '';

    _nameController.text = name;
    _phoneController.text = phone;
    _addressLine1Controller.text = address;
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _startCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final box = HiveBoxes.getSettingsBox();
      final token = box.get('auth_token', defaultValue: '');
      final double price = (widget.product['price'] ?? 0).toDouble();

      final response = await http.post(
        Uri.parse('${ApiConstants.hardwareOrdersUrl}/create-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': price,
          'productId': widget.product['_id'],
          'quantity': 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String razorpayOrderId = data['order_id'];
        final String keyId = data['key_id'] ?? 'rzp_test_Tamlee9RTRuHdu';

        final options = {
          'key': keyId,
          'amount': (price * 100).round(),
          'name': 'Zyvionix POS Store',
          'description': widget.product['name'] ?? 'POS Hardware Purchase',
          'order_id': razorpayOrderId,
          'prefill': {
            'contact': _phoneController.text.trim(),
            'name': _nameController.text.trim(),
          },
          'external': {
            'wallets': ['paytm'],
          },
        };

        _razorpay.open(options);
      } else {
        setState(() {
          _isProcessing = false;
        });
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: 'Failed to create payment order. Try again.',
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: 'Error starting payment: $e'),
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final box = HiveBoxes.getSettingsBox();
      final token = box.get('auth_token', defaultValue: '');
      final double price = (widget.product['price'] ?? 0).toDouble();

      final shippingAddress = {
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
      };

      final items = [
        {
          'hardwareProduct': widget.product['_id'],
          'name': widget.product['name'],
          'price': price,
          'quantity': 1,
          'imageUrl': widget.product['imageUrl'] ?? '',
        },
      ];

      final verifyResponse = await http.post(
        Uri.parse('${ApiConstants.hardwareOrdersUrl}/verify-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'shippingAddress': shippingAddress,
          'items': items,
          'amount': price,
        }),
      );

      setState(() {
        _isProcessing = false;
      });

      if (verifyResponse.statusCode == 200 ||
          verifyResponse.statusCode == 201) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(
            message: 'Payment Successful! Your order has been placed.',
          ),
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HardwareOrdersScreen()),
        );
      } else {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: 'Payment verification failed. Please contact support.',
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: 'Verification Error: $e'),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessing = false;
    });
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.error(
        message:
            'Payment Failed: ${response.message ?? "Transaction Cancelled"}',
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('imageeeeeeeeeeeeeeeeee url ${widget.product['imageUrl']}');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double price = (widget.product['price'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Delivery Address & Payment',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: (() {
                        final String imgUrl = (widget.product['imageUrl'] ?? '')
                            .toString();
                        if (imgUrl.isEmpty) {
                          return const Icon(
                            Icons.print_rounded,
                            color: Color(0xFF4F46E5),
                          );
                        }
                        if (imgUrl.startsWith('data:image/')) {
                          try {
                            final base64Str = imgUrl.split(',').last;
                            final bytes = base64Decode(base64Str);
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(bytes, fit: BoxFit.cover),
                            );
                          } catch (_) {
                            return const Icon(
                              Icons.print_rounded,
                              color: Color(0xFF4F46E5),
                            );
                          }
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.print_rounded,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        );
                      })(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product['name'] ?? 'Hardware Item',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Quantity: 1 • Free Express Shipping',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(
              //       'Shipping Address',
              //       style: TextStyle(
              //         fontSize: 16,
              //         fontWeight: FontWeight.bold,
              //         color: isDark ? Colors.white : Colors.grey.shade900,
              //       ),
              //     ),
              //     TextButton.icon(
              //       onPressed: _autoFillAddressFromSettings,
              //       icon: const Icon(Icons.my_location_rounded, size: 16),
              //       label: const Text(
              //         'Auto-Fill',
              //         style: TextStyle(fontSize: 12),
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 8),

              // Address Form Fields
              _buildTextField(
                controller: _nameController,
                label: 'Full Name *',
                hint: 'e.g. Melvin',
                icon: Icons.person_outline_rounded,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter recipient name' : null,
              ),

              const SizedBox(height: 12),

              _buildTextField(
                controller: _phoneController,
                label: 'Mobile Number *',
                hint: 'e.g. 9876543210',
                keyboardType: TextInputType.phone,
                icon: Icons.phone_outlined,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter mobile number' : null,
              ),

              const SizedBox(height: 12),

              _buildTextField(
                controller: _addressLine1Controller,
                label: 'Street Address *',
                hint: 'MG Road Commercial Complex',
                icon: Icons.home_outlined,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter street address' : null,
              ),

              const SizedBox(height: 12),

              _buildTextField(
                controller: _addressLine2Controller,
                label: 'Landmark / Locality (Optional)',
                hint: 'e.g. Near Central Metro Station',
                icon: Icons.location_on_outlined,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City *',
                      hint: 'e.g. Kochi',
                      validator: (val) =>
                          val == null || val.isEmpty ? 'City required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'State *',
                      hint: 'e.g. Kerala',
                      validator: (val) =>
                          val == null || val.isEmpty ? 'State required' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildTextField(
                controller: _pincodeController,
                label: 'Pincode *',
                hint: 'e.g. 682001',
                keyboardType: TextInputType.number,
                icon: Icons.pin_drop_outlined,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Pincode required' : null,
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isProcessing ? null : _startCheckout,
                  child: _isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Opening Razorpay Gateway...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Pay ₹${price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // const SizedBox(height: 12),
              // const Center(
              //   child: Text(
              //     '🔒 Guaranteed Safe & Secure 256-Bit SSL Encrypted Payment',
              //     style: TextStyle(fontSize: 11, color: Colors.grey),
              //   ),
              // ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, size: 20, color: Colors.grey)
                : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
