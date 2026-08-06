import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/provider/auth_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ownerNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  String _storageType = 'Device Storage';

  @override
  void dispose() {
    _ownerNameController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Widget _buildTextField({
  //   required TextEditingController controller,
  //   required String label,
  //   required IconData icon,
  //   bool isOptional = false,
  //   bool isPassword = false,
  //   TextInputType keyboardType = TextInputType.text,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16.0),
  //     child: TextFormField(
  //       controller: controller,
  //       obscureText: isPassword && !_isPasswordVisible,
  //       keyboardType: keyboardType,
  //       validator: (value) {
  //         if (!isOptional && (value == null || value.trim().isEmpty)) {
  //           return 'Please enter $label';
  //         }
  //         if (value != null && value.isNotEmpty) {
  //           if (keyboardType == TextInputType.phone) {
  //             if (value.length != 10 || !RegExp(r'^\d+$').hasMatch(value)) {
  //               return 'Please enter a valid 10-digit number';
  //             }
  //           } else if (keyboardType == TextInputType.emailAddress) {
  //             final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  //             if (!emailRegex.hasMatch(value)) {
  //               return 'Please enter a valid email address';
  //             }
  //           }
  //         }
  //         if (isPassword &&
  //             value != null &&
  //             value.isNotEmpty &&
  //             value.length < 6) {
  //           return 'Password must be at least 6 characters';
  //         }
  //         return null;
  //       },
  //       decoration: InputDecoration(
  //         labelText: label + (isOptional ? ' (Optional)' : ''),
  //         prefixIcon: Icon(icon),
  //         suffixIcon: isPassword
  //             ? IconButton(
  //                 icon: Icon(
  //                   _isPasswordVisible
  //                       ? Icons.visibility_off_outlined
  //                       : Icons.visibility_outlined,
  //                 ),
  //                 onPressed: () {
  //                   setState(() {
  //                     _isPasswordVisible = !_isPasswordVisible;
  //                   });
  //                 },
  //               )
  //             : null,
  //         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  //         filled: true,
  //         fillColor: Theme.of(context).colorScheme.surface,
  //       ),
  //     ),
  //   );
  // }

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

          if (value != null && value.isNotEmpty) {
            if (keyboardType == TextInputType.phone) {
              if (value.length != 10) {
                return 'Please enter a valid 10-digit number';
              }
            } else if (keyboardType == TextInputType.emailAddress) {
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email address';
              }
            }
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
                      'Owner Details',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildTextField(
                      controller: _ownerNameController,
                      label: 'Owner Name',
                      icon: Icons.person_outline,
                    ),
                    _buildTextField(
                      controller: _mobileNumberController,
                      label: 'Mobile Number',
                      icon: Icons.phone_android,
                      keyboardType: TextInputType.phone,
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

                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        if (authProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1EA1F2),
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  final success = await authProvider.register(
                                    ownerName: _ownerNameController.text.trim(),
                                    mobileNumber: _mobileNumberController.text.trim(),
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                    storagePreference: _storageType,
                                  );

                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Registration successful! Please login.',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  } else if (mounted &&
                                      authProvider.errorMessage.isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          authProvider.errorMessage,
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1EA1F2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                        );
                      },
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
