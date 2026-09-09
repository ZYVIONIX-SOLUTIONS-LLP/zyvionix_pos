import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/models/shop.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:zyvionix_pos/constants/api_constants.dart';

class CreateShopScreen extends StatefulWidget {
  final bool isForced;

  const CreateShopScreen({super.key, this.isForced = false});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _gstController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _gstController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final box = HiveBoxes.getSettingsBox();
    final storageType = box.get('storageType', defaultValue: 'Device Storage');
    final userId = box.get('user_id');

    final shopName = _nameController.text.trim();
    final shopId = DateTime.now().millisecondsSinceEpoch.toString();

    if (storageType == 'Device Storage') {
      // Save locally to Hive
      final shop = Shop(
        id: shopId,
        ownerId: userId,
        name: shopName,
        address: _addressController.text.trim(),
        mobile: _mobileController.text.trim(),
        gst: _gstController.text.trim(),
        email: _emailController.text.trim(),
      );

      // Save shop data in settings box for easy access in offline mode
      await box.put('shop_id', shopId);
      await box.put('shop_name', shopName);
      await box.put('current_shop_id', shopId);
      await box.put('offline_company_address', _addressController.text.trim());
      await box.put('shop_mobile', _mobileController.text.trim());
      await box.put('shop_email', _emailController.text.trim());
      await box.put('shop_gst', _gstController.text.trim());

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop created locally!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      // Save to Cloud via API
      try {
        final token = box.get('auth_token');
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/shops'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': shopName,
            'address': _addressController.text.trim(),
            'mobile': _mobileController.text.trim(),
            'gst': _gstController.text.trim(),
            'email': _emailController.text.trim(),
          }),
        );

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final newShopId = data['shop']['_id'];

          await box.put('current_shop_id', newShopId);
          await box.put('shop_id', newShopId);
          await box.put('shop_name', shopName);
          await box.put(
            'offline_company_address',
            _addressController.text.trim(),
          );
          await box.put('shop_mobile', _mobileController.text.trim());

          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Shop created on Cloud!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          final data = jsonDecode(response.body);
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Failed to create shop'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network error.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isOptional = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.phone
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ]
            : null,
        validator: (value) {
          if (!isOptional && (value == null || value.trim().isEmpty)) {
            return 'Please enter $label';
          }
          if (value != null &&
              value.isNotEmpty &&
              keyboardType == TextInputType.phone) {
            if (value.length != 10) {
              return 'Please enter a valid 10-digit number';
            }
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label + (isOptional ? ' (Optional)' : ''),
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return !widget.isForced;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: widget.isForced
              ? const SizedBox()
              : IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
          title: const Text('Create Shop'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isForced) ...[
                    const Text(
                      'Welcome! Let\'s set up your first shop.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildTextField(
                    controller: _nameController,
                    label: 'Shop Name',
                    icon: Icons.store,
                  ),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                  ),
                  _buildTextField(
                    controller: _mobileController,
                    label: 'Shop Mobile Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildTextField(
                    controller: _gstController,
                    label: 'GST Number',
                    icon: Icons.receipt_long,
                    isOptional: true,
                  ),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Shop Email',
                    icon: Icons.email,
                    isOptional: true,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: SpinKitFadingCircle(color: Color(0xFF1EA1F2), size: 50.0))
                  else
                    ElevatedButton(
                      onPressed: _createShop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1EA1F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Shop',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
