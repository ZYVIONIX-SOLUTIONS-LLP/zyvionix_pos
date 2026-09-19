import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:zyvionix_pos/constants/api_constants.dart';

class EditShopScreen extends StatefulWidget {
  final dynamic shop;

  const EditShopScreen({super.key, required this.shop});

  @override
  State<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends State<EditShopScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _mobileController;
  late TextEditingController _gstController;
  late TextEditingController _emailController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shop['name'] ?? '');
    _addressController = TextEditingController(
      text: widget.shop['address'] ?? '',
    );
    _mobileController = TextEditingController(
      text: widget.shop['mobile'] ?? '',
    );
    _gstController = TextEditingController(text: widget.shop['gst'] ?? '');
    _emailController = TextEditingController(text: widget.shop['email'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _gstController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final box = HiveBoxes.getSettingsBox();

      // Save to Cloud via API
      try {
        final token = box.get('auth_token');
        final response = await http.put(
          Uri.parse('${ApiConstants.baseUrl}/shops/${widget.shop['_id']}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': _nameController.text.trim(),
            'address': _addressController.text.trim(),
            'mobile': _mobileController.text.trim(),
            'gst': _gstController.text.trim(),
            'email': _emailController.text.trim(),
            'status': widget.shop['status'] ?? 'Active',
          }),
        );

        print(
          'Response status code for update shopsssss ${response.statusCode}',
        );

        print('Response bodyyyyyyyyyyyy for update shopsssss ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          final updatedShop = responseData['shop'] ?? widget.shop;

          final isCurrentShop =
              box.get('current_shop_id') == widget.shop['_id'];
          if (isCurrentShop) {
            await box.put('shop_name', _nameController.text.trim());
            await box.put(
              'offline_company_address',
              _addressController.text.trim(),
            );
            await box.put('shop_mobile', _mobileController.text.trim());
          }

          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Shop updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, updatedShop);
          }
        } else {
          final data = jsonDecode(response.body);
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Failed to update shop'),
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text('Edit Shop'),
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
                    onPressed: _updateShop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1EA1F2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Update Shop',
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
    );
  }
}
