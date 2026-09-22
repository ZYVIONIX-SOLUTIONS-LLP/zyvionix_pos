import 'package:flutter/material.dart';
import 'package:zyvionix_pos/l10n/app_translations.dart';

class LanguageTransitionOverlay {
  static void show(BuildContext context, {required String targetLangCode}) {
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    final nativeName = AppTranslations.languageNativeNames[targetLangCode] ?? 'Language';
    final flag = AppTranslations.languageFlags[targetLangCode] ?? '🌐';
    final updatingText = AppTranslations.get('changing_language', targetLangCode);

    entry = OverlayEntry(
      builder: (context) => _LanguageTransitionWidget(
        nativeName: nativeName,
        flag: flag,
        updatingText: updatingText,
        onComplete: () {
          entry.remove();
        },
      ),
    );

    overlayState.insert(entry);
  }
}

class _LanguageTransitionWidget extends StatefulWidget {
  final String nativeName;
  final String flag;
  final String updatingText;
  final VoidCallback onComplete;

  const _LanguageTransitionWidget({
    required this.nativeName,
    required this.flag,
    required this.updatingText,
    required this.onComplete,
  });

  @override
  State<_LanguageTransitionWidget> createState() =>
      __LanguageTransitionWidgetState();
}

class __LanguageTransitionWidgetState extends State<_LanguageTransitionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.forward();

    // Fade out and finish after 1.3 seconds
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onComplete());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value.clamp(0.0, 1.0),
          child: Material(
            color: Colors.black.withOpacity(0.65),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withOpacity(0.25),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          RotationTransition(
                            turns: _rotationAnimation,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const SweepGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF38BDF8),
                                    Color(0xFF818CF8),
                                    Color(0xFF2563EB),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 66,
                            height: 66,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                widget.flag,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.nativeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              widget.updatingText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
        );
      },
    );
  }
}
