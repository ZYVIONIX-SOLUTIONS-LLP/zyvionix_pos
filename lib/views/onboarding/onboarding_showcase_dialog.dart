import 'package:flutter/material.dart';
import '../../database/hive_boxes.dart';
import '../../services/api_service.dart';

class OnboardingShowcaseDialog extends StatefulWidget {
  const OnboardingShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const OnboardingShowcaseDialog(),
    );
  }

  @override
  State<OnboardingShowcaseDialog> createState() =>
      _OnboardingShowcaseDialogState();
}

class _OnboardingShowcaseDialogState extends State<OnboardingShowcaseDialog> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isCompleting = false;

  final List<ShowcaseStep> _steps = [
    const ShowcaseStep(
      icon: Icons.storefront_rounded,
      iconColor: Color(0xFF1C64F2),
      title: 'Welcome to Zyvionix POS!',
      subtitle:
          'Your complete billing and retail management solution. Let us show you around key features to get started.',
      badgeText: 'Step 1 of 4',
      highlights: [
        'Cloud Support',
        'Multi-shop management',
        'Instant receipt generation',
      ],
    ),
    const ShowcaseStep(
      icon: Icons.inventory_2_rounded,
      iconColor: Color(0xFF10B981),
      title: 'Add & Manage Products',
      subtitle:
          'Easily list your items with custom pricing, categories, and images. You can also quickly add new products directly inside the billing screen!',
      badgeText: 'Step 2 of 4',
      highlights: [
        'Organize by categories',
        'Add items directly from billing page (+ button)',
        'Track product pricing & stock',
      ],
    ),
    const ShowcaseStep(
      icon: Icons.receipt_long_rounded,
      iconColor: Color(0xFF8B5CF6),
      title: 'Billing & Checkout Session',
      subtitle:
          'Fast and intuitive billing session. Select items, search by name, apply discounts, and complete payments via UPI, Cash, or Card.',
      badgeText: 'Step 3 of 4',
      highlights: [
        'Real-time item search & quick add',
        'Thermal wireless bluetooth printing',
        'Instant bill history & bill preview',
      ],
    ),
    const ShowcaseStep(
      icon: Icons.analytics_rounded,
      iconColor: Color(0xFFF59E0B),
      title: 'Reports & Hardware Store',
      subtitle:
          'Monitor your business performance with live analytics charts and order official POS hardware like receipt printers, scanners & paper rolls directly in-app.',
      badgeText: 'Step 4 of 4',
      highlights: [
        'Daily & weekly sales breakdown',
        'POS Printers, Scanners & Paper Rolls store',
        'Doorstep hardware delivery tracking',
      ],
    ),
  ];

  Future<void> _finishOnboarding() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      await ApiService.completeOnboarding();
    } catch (_) {}

    final box = HiveBoxes.getSettingsBox();
    await box.put('is_new_user', false);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentIndex];
    final isLastStep = _currentIndex == _steps.length - 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 580),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: currentStep.iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentStep.badgeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: currentStep.iconColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isCompleting ? null : _finishOnboarding,
                  child: const Text(
                    'Skip Tour',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Page View Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 84,
                        width: 84,
                        decoration: BoxDecoration(
                          color: step.iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(step.icon, size: 44, color: step.iconColor),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        step.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: step.highlights
                            .map(
                              (h) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: step.iconColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        h,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentIndex == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? currentStep.iconColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bottom Navigation Buttons
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isCompleting
                        ? null
                        : () {
                            if (isLastStep) {
                              _finishOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentStep.iconColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isCompleting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isLastStep ? 'Get Started 🎉' : 'Next Step',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShowcaseStep {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badgeText;
  final List<String> highlights;

  const ShowcaseStep({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.highlights,
  });
}
