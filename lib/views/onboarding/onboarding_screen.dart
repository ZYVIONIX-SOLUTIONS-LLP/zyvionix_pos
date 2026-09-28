import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/views/auth/login_screen.dart';
import 'package:zyvionix_pos/controllers/language_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      illustrationPath: 'assets/onboarding/illustration_1.png',
      cropPath: 'assets/onboarding/crop_screen_1.png',
      titleKey: 'Create bills in seconds',
      descriptionKey:
          'Make fast and simple bills with an easy-to-use billing system designed for your shop',
    ),

    OnboardingItem(
      illustrationPath: 'assets/onboarding/illustration_2.png',
      cropPath: 'assets/onboarding/crop_screen_2.png',
      titleKey: 'Manage your products easily',
      descriptionKey:
          'Add products, update prices and keep your entire product list organized in one place',
    ),

    OnboardingItem(
      illustrationPath: 'assets/onboarding/illustration_3.png',
      cropPath: 'assets/onboarding/crop_screen_3.png',
      titleKey: 'Track your business with ease',
      descriptionKey:
          'View your sales, check bill history and keep your business running smoothly every day',
    ),
  ];

  void _onFinishOnboarding() async {
    final box = HiveBoxes.getSettingsBox();
    await box.put('has_seen_onboarding', true);

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _onNextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _onFinishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryPurple = Color(0xFF8C52FF);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Spacer to center top if needed
                  TextButton(
                    onPressed: _onFinishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Onboarding PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Column(
                    children: [
                      // Curved Purple Illustration Container
                      Expanded(
                        flex: 6,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Purple Soft Circle Backdrop
                              Positioned(
                                top: 20,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.72,
                                  height:
                                      MediaQuery.of(context).size.width * 0.72,
                                  decoration: BoxDecoration(
                                    color: primaryPurple.withOpacity(
                                      isDark ? 0.25 : 0.15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              // Soft Gradient Curve Accent
                              ClipPath(
                                clipper: TopCurveClipper(),
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryPurple.withOpacity(0.2),
                                        primaryPurple.withOpacity(0.05),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),

                              // Illustration Image
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Image.asset(
                                    item.illustrationPath,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback to cropped screen asset if primary illustration is loading
                                      return Image.asset(
                                        item.cropPath,
                                        fit: BoxFit.contain,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Text Section (Title + Subtitle)
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                context.tr(item.titleKey),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E1E1E),
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                context.tr(item.descriptionKey),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Bottom Navigation & Controls
            Padding(
              padding: const EdgeInsets.only(bottom: 36, top: 12),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? primaryPurple
                              : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  GestureDetector(
                    onTap: _onNextPage,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: primaryPurple,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryPurple.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String illustrationPath;
  final String cropPath;
  final String titleKey;
  final String descriptionKey;

  OnboardingItem({
    required this.illustrationPath,
    required this.cropPath,
    required this.titleKey,
    required this.descriptionKey,
  });
}

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      size.width,
      size.height * 0.75,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
