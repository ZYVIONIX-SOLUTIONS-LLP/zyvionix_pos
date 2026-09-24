import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zyvionix_pos/provider/navbar/navbar_provider.dart';
import 'package:zyvionix_pos/views/auth/device_override_otp_screen.dart';
import 'package:zyvionix_pos/views/auth/registration_screen.dart';
import 'package:zyvionix_pos/views/auth/select_assigned_shop_screen.dart';
import 'package:zyvionix_pos/views/navbar/navbar_screen.dart';
import 'package:provider/provider.dart';
import 'package:zyvionix_pos/provider/auth_provider.dart';
import 'package:zyvionix_pos/controllers/product_controller.dart';
import 'package:zyvionix_pos/controllers/bill_controller.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isEmployeeLogin = false;
  bool _rememberMe = true;

  void _showDeviceOverrideDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Device Lock Active'),
        content: Text(
          result['message'] ?? 'Already logged in on another device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeviceOverrideOtpScreen(
                    mobileNumber:
                        result['mobileNumber'] ?? _emailController.text.trim(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue with new device',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                        // Top Illustration / Lottie Animation
                        Center(
                          child: Container(
                            height: 200,
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: Lottie.network(
                              'https://assets9.lottiefiles.com/packages/lf20_mjlh3hcy.json',
                              height: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/pos_login_illustration.png',
                                  height: 190,
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Headline Title & Subtitle
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please Sign in to continue.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Owner / Employee Pill Toggle
                        // Container(
                        //   padding: const EdgeInsets.all(4),
                        //   decoration: BoxDecoration(
                        //     color: cardBgColor,
                        //     borderRadius: BorderRadius.circular(24),
                        //   ),
                        //   child: Row(
                        //     children: [
                        //       Expanded(
                        //         child: GestureDetector(
                        //           onTap: () {
                        //             setState(() {
                        //               _isEmployeeLogin = false;
                        //               _emailController.clear();
                        //             });
                        //           },
                        //           child: AnimatedContainer(
                        //             duration: const Duration(milliseconds: 200),
                        //             padding: const EdgeInsets.symmetric(
                        //               vertical: 10,
                        //             ),
                        //             decoration: BoxDecoration(
                        //               color: !_isEmployeeLogin
                        //                   ? buttonBgColor
                        //                   : Colors.transparent,
                        //               borderRadius: BorderRadius.circular(20),
                        //             ),
                        //             child: Text(
                        //               'Owner',
                        //               textAlign: TextAlign.center,
                        //               style: TextStyle(
                        //                 fontSize: 14,
                        //                 fontWeight: FontWeight.bold,
                        //                 color: !_isEmployeeLogin
                        //                     ? buttonTextColor
                        //                     : secondaryTextColor,
                        //               ),
                        //             ),
                        //           ),
                        //         ),
                        //       ),
                        //       Expanded(
                        //         child: GestureDetector(
                        //           onTap: () {
                        //             setState(() {
                        //               _isEmployeeLogin = true;
                        //               _emailController.clear();
                        //             });
                        //           },
                        //           child: AnimatedContainer(
                        //             duration: const Duration(milliseconds: 200),
                        //             padding: const EdgeInsets.symmetric(
                        //               vertical: 10,
                        //             ),
                        //             decoration: BoxDecoration(
                        //               color: _isEmployeeLogin
                        //                   ? buttonBgColor
                        //                   : Colors.transparent,
                        //               borderRadius: BorderRadius.circular(20),
                        //             ),
                        //             child: Text(
                        //               'Employee',
                        //               textAlign: TextAlign.center,
                        //               style: TextStyle(
                        //                 fontSize: 14,
                        //                 fontWeight: FontWeight.bold,
                        //                 color: _isEmployeeLogin
                        //                     ? buttonTextColor
                        //                     : secondaryTextColor,
                        //               ),
                        //             ),
                        //           ),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        const SizedBox(height: 20),

                        // Username / Email / Mobile Input Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: _isEmployeeLogin
                              ? TextInputType.phone
                              : TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 15,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _isEmployeeLogin
                                  ? 'Please enter mobile number'
                                  : 'Please enter username, email or mobile';
                            }

                            if (_isEmployeeLogin) {
                              if (value.length != 10 ||
                                  !RegExp(r'^\d+$').hasMatch(value)) {
                                return 'Mobile number must be exactly 10 digits';
                              }
                            } else {
                              if (value.contains('@')) {
                                final emailRegex = RegExp(
                                  r'^[^@]+@[^@]+\.[^@]+',
                                );
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                              } else if (RegExp(r'^\d+$').hasMatch(value)) {
                                if (value.length != 10) {
                                  return 'Mobile number must be exactly 10 digits';
                                }
                              }
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: _isEmployeeLogin
                                ? 'Mobile Number'
                                : 'Username or Email',
                            hintStyle: TextStyle(
                              color: secondaryTextColor.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 12,
                              ),
                              child: Icon(
                                _isEmployeeLogin
                                    ? Icons.phone_android_outlined
                                    : Icons.person_outline_rounded,
                                color: secondaryTextColor,
                                size: 22,
                              ),
                            ),
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
                              borderSide: BorderSide(
                                color: buttonBgColor,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 15,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(
                              color: secondaryTextColor.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 12,
                              ),
                              child: Icon(
                                Icons.lock_outline_rounded,
                                color: secondaryTextColor,
                                size: 22,
                              ),
                            ),
                            suffixIcon: Padding(
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
                            ),
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
                              borderSide: BorderSide(
                                color: buttonBgColor,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Reminder me next time switch row
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     Text(
                        //       'Reminder me next time',
                        //       style: TextStyle(
                        //         fontSize: 13,
                        //         fontWeight: FontWeight.w500,
                        //         color: secondaryTextColor,
                        //       ),
                        //     ),
                        //     Transform.scale(
                        //       scale: 0.85,
                        //       child: Switch.adaptive(
                        //         value: _rememberMe,
                        //         activeColor: buttonBgColor,
                        //         onChanged: (val) {
                        //           setState(() {
                        //             _rememberMe = val;
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        const SizedBox(height: 24),

                        // Login / Sign in Button
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
                                    final result = await authProvider.login(
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                    );
                                    if (result['success'] == true && mounted) {
                                      context.read<ProductController>().init();
                                      context.read<BillController>().init();
                                      context
                                          .read<BottomNavbarProvider>()
                                          .setIndex(0);

                                      showTopSnackBar(
                                        Overlay.of(context),
                                        const CustomSnackBar.success(
                                          message: 'LoggedIn successfully',
                                        ),
                                        displayDuration: const Duration(
                                          seconds: 2,
                                        ),
                                      );

                                      if (result['role'] == 'Employee') {
                                        final assignedShops =
                                            result['assignedShops']
                                                as List<dynamic>?;
                                        if (assignedShops == null ||
                                            assignedShops.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'No shops assigned to your account. Contact owner.',
                                              ),
                                            ),
                                          );
                                        } else {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  SelectAssignedShopScreen(
                                                    assignedShops:
                                                        assignedShops,
                                                  ),
                                            ),
                                          );
                                        }
                                      } else {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const NavbarScreen(),
                                          ),
                                        );
                                      }
                                    } else if (result['isDeviceMismatch'] ==
                                            true &&
                                        mounted) {
                                      _showDeviceOverrideDialog(result);
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
                                  'Sign in',
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

                        // Register Link
                        if (!_isEmployeeLogin)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have account? ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: secondaryTextColor,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegistrationScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: buttonBgColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
