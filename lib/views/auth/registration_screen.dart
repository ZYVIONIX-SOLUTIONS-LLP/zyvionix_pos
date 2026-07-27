import 'package:flutter/material.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _gstController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  String _storageType = 'Device Storage';

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _businessTypeController.dispose();
    _mobileNumberController.dispose();
    _gstController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isOptional = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        validator: (value) {
          if (!isOptional && (value == null || value.trim().isEmpty)) {
            return 'Please enter $label';
          }
          if (isPassword &&
              value != null &&
              value.isNotEmpty &&
              value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label + (isOptional ? ' (Optional)' : ''),
          prefixIcon: Icon(icon),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo Placeholder
                    // Center(
                    //   child: Image.asset(
                    //     'assets/splashimage.png',
                    //     height: 80,
                    //     width: 80,
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    Text(
                      'Business Details',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildTextField(
                      controller: _companyNameController,
                      label: 'Company Name',
                      icon: Icons.business,
                    ),
                    _buildTextField(
                      controller: _companyAddressController,
                      label: 'Company Address',
                      icon: Icons.location_on_outlined,
                    ),
                    _buildTextField(
                      controller: _businessTypeController,
                      label: 'Business Type',
                      icon: Icons.category_outlined,
                    ),
                    _buildTextField(
                      controller: _mobileNumberController,
                      label: 'Mobile Number',
                      icon: Icons.phone_android,
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
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      isOptional: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Storage Preference',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Storage Type Radio Buttons
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text(
                              'Device Storage',
                              style: TextStyle(fontSize: 14),
                            ),
                            value: 'Device Storage',
                            groupValue: _storageType,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (String? value) {
                              setState(() {
                                _storageType = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text(
                              'Cloud Storage',
                              style: TextStyle(fontSize: 14),
                            ),
                            value: 'Cloud Storage',
                            groupValue: _storageType,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (String? value) {
                              setState(() {
                                _storageType = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // Save the storage preference for the login/home flow
                          final box = HiveBoxes.getSettingsBox();
                          await box.put('storageType', _storageType);
                          await box.put('subscriptionModalShown', false);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Registration successful! Please login.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1EA1F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Register',
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
      ),
    );
  }
}
