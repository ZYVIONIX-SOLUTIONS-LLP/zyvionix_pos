import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:zyvionix_pos/widgets/custom_text_field.dart';
import 'package:zyvionix_pos/widgets/primary_button.dart';

class CreateEmployeeScreen extends StatefulWidget {
  final String initialShopId;

  const CreateEmployeeScreen({super.key, required this.initialShopId});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isFetchingShops = true;
  List<dynamic> _allShops = [];
  List<String> _selectedShopIds = [];
  String _role = 'Cashier';

  @override
  void initState() {
    super.initState();
    _selectedShopIds = [widget.initialShopId];
    _fetchShops();
  }

  Future<void> _fetchShops() async {
    final box = HiveBoxes.getSettingsBox();
    final token = box.get('auth_token');

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/shops'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _allShops = jsonDecode(response.body);
          _isFetchingShops = false;
        });
      } else {
        setState(() => _isFetchingShops = false);
      }
    } catch (e) {
      setState(() => _isFetchingShops = false);
    }
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedShopIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one shop'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final box = HiveBoxes.getSettingsBox();
    final token = box.get('auth_token');

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/employees'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'mobileNumber': _mobileController.text.trim(),
          'password': _passwordController.text,
          'role': _role,
          'assignedShops': _selectedShopIds,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to create employee'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text(
          'Add Employee',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Employee Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  hint: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                CustomTextField(
                  label: 'Mobile Number',
                  controller: _mobileController,
                  hint: 'Mobile',
                  prefixIcon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length != 10) return 'Must be 10 digits';
                    return null;
                  },
                ),
                CustomTextField(
                  label: 'Password',
                  controller: _passwordController,
                  hint: 'Password',

                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.length < 6 ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Role',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _role,
                      isExpanded: true,
                      items: ['Cashier', 'Manager'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          if (newValue != null) _role = newValue;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Assign to Shops',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select which shops this employee can access.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                _isFetchingShops
                    ? const Center(child: SpinKitFadingCircle(color: Color(0xFF1EA1F2), size: 50.0))
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _allShops.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final shop = _allShops[index];
                            final shopId = shop['_id'];
                            return CheckboxListTile(
                              title: Text(
                                shop['name'] ?? 'Shop',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(shop['address'] ?? ''),
                              value: _selectedShopIds.contains(shopId),
                              activeColor: const Color(0xFF1EA1F2),
                              onChanged: (bool? checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedShopIds.add(shopId);
                                  } else {
                                    _selectedShopIds.remove(shopId);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                const SizedBox(height: 40),
                _isLoading
                    ? const Center(child: SpinKitFadingCircle(color: Color(0xFF1EA1F2), size: 50.0))
                    : PrimaryButton(
                        text: 'Save Employee',
                        onPressed: _saveEmployee,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
