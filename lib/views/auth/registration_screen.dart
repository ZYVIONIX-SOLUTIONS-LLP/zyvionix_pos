import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
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

  @override
  void dispose() {
    _ownerNameController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildCapsuleTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color cardBgColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color buttonBgColor,
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
        style: TextStyle(color: primaryTextColor, fontSize: 15),
        inputFormatters: keyboardType == TextInputType.phone
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ]
            : null,
        validator: (value) {
          if (!isOptional && (value == null || value.trim().isEmpty)) {
            return 'Please enter $hintText';
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
          hintText: hintText + (isOptional ? ' (Optional)' : ''),
          hintStyle: TextStyle(
            color: secondaryTextColor.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, color: secondaryTextColor, size: 22),
          ),
          suffixIcon: isPassword
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: secondaryTextColor,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                )
              : null,
          filled: true,
          fillColor: cardBgColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: buttonBgColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final cardBgColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final secondaryTextColor = isDark
        ? Colors.grey.shade400
        : const Color(0xFF64748B);
    final buttonBgColor = isDark
        ? const Color(0xFF38BDF8)
        : const Color(0xFF1E293B);
    final buttonTextColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Decorative Gradient Circles
          Positioned(
            top: -90,
            left: -90,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                    : const Color(0xFFDCE4EC).withValues(alpha: 0.6),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.3)
                    : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back Button Header
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: primaryTextColor,
                            size: 22,
                          ),
                        ),

                        // Top Illustration / Lottie Animation
                        Center(
                          child: Container(
                            height: 190,
                            constraints: const BoxConstraints(maxHeight: 210),
                            child: Lottie.network(
                              'https://assets9.lottiefiles.com/packages/lf20_mjlh3hcy.json',
                              height: 190,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/login_illustration.png',
                                  height: 180,
                                  fit: BoxFit.contain,
                                  errorBuilder: (ctx, err, stack) {
                                    return Image.asset(
                                      'assets/pos_login_illustration.png',
                                      height: 180,
                                      fit: BoxFit.contain,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title & Subtitle
                        Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please register to login.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        _buildCapsuleTextField(
                          controller: _ownerNameController,
                          hintText: 'Username',
                          icon: Icons.person_outline_rounded,
                          cardBgColor: cardBgColor,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          buttonBgColor: buttonBgColor,
                        ),
                        _buildCapsuleTextField(
                          controller: _mobileNumberController,
                          hintText: 'Mobile Number',
                          icon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          cardBgColor: cardBgColor,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          buttonBgColor: buttonBgColor,
                        ),
                        _buildCapsuleTextField(
                          controller: _emailController,
                          hintText: 'Email Address',
                          icon: Icons.email_outlined,
                          isOptional: true,
                          keyboardType: TextInputType.emailAddress,
                          cardBgColor: cardBgColor,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          buttonBgColor: buttonBgColor,
                        ),
                        _buildCapsuleTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          cardBgColor: cardBgColor,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          buttonBgColor: buttonBgColor,
                        ),
                        const SizedBox(height: 12),

                        // Sign Up Button
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            if (authProvider.isLoading) {
                              return Center(
                                child: SpinKitFadingCircle(
                                  color: buttonBgColor,
                                  size: 50.0,
                                ),
                              );
                            }
                            return SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    final success = await authProvider.register(
                                      ownerName: _ownerNameController.text
                                          .trim(),
                                      mobileNumber: _mobileNumberController.text
                                          .trim(),
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text,
                                    );

                                    if (success && mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                  backgroundColor: buttonBgColor,
                                  foregroundColor: buttonTextColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Already have account? Sign in Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have account? ',
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Sign in',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: buttonBgColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
