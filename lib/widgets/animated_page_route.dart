import 'package:flutter/material.dart';

enum AnimationType { slideRight, slideLeft, slideUp, slideDown, fadeScale }

class AnimatedPageRoute<T> extends PageRoute<T> {
  final Widget child;
  final AnimationType animationType;
  final Duration duration;

  AnimatedPageRoute({
    required this.child,
    this.animationType = AnimationType.slideRight,
    this.duration = const Duration(milliseconds: 280),
  });

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    switch (animationType) {
      case AnimationType.slideRight:
        return _slide(
          animation: curvedAnimation,
          child: child,
          begin: const Offset(0.035, 0),
        );

      case AnimationType.slideLeft:
        return _slide(
          animation: curvedAnimation,
          child: child,
          begin: const Offset(-0.035, 0),
        );

      case AnimationType.slideUp:
        return _slide(
          animation: curvedAnimation,
          child: child,
          begin: const Offset(0, 0.025),
        );

      case AnimationType.slideDown:
        return _slide(
          animation: curvedAnimation,
          child: child,
          begin: const Offset(0, -0.025),
        );

      case AnimationType.fadeScale:
        return _fadeScale(animation: curvedAnimation, child: child);
    }
  }

  Widget _slide({
    required Animation<double> animation,
    required Widget child,
    required Offset begin,
  }) {
    final position = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(animation);

    return SlideTransition(position: position, child: child);
  }

  Widget _fadeScale({
    required Animation<double> animation,
    required Widget child,
  }) {
    final scale = Tween<double>(begin: 0.985, end: 1.0).animate(animation);

    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(animation);

    return FadeTransition(
      opacity: opacity,
      child: ScaleTransition(scale: scale, child: child),
    );
  }
}

/// Easy navigation extension
extension NavigationExtension on BuildContext {
  Future<T?> navigateWithAnimation<T>(
    Widget page, {
    AnimationType animationType = AnimationType.slideRight,
    Duration duration = const Duration(milliseconds: 280),
  }) {
    return Navigator.of(this).push<T>(
      AnimatedPageRoute<T>(
        child: page,
        animationType: animationType,
        duration: duration,
      ),
    );
  }
}
