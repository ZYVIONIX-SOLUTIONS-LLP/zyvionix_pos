import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _ambientController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, child) {
              return CustomPaint(
                painter: _AuroraPainter(progress: _ambientController.value),
              );
            },
          ),

          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(progress: _ambientController.value),
              );
            },
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulseScale =
                              1.0 + (_pulseController.value * 0.03);
                          final glowOpacity =
                              0.4 + (_pulseController.value * 0.4);
                          return Transform.scale(
                            scale: pulseScale,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00D4FF,
                                    ).withOpacity(glowOpacity * 0.5),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: const Color(
                                      0xFF7000FF,
                                    ).withOpacity(glowOpacity * 0.3),
                                    blurRadius: 60,
                                    spreadRadius: -10,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 15.0,
                                    sigmaY: 15.0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.05),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/splashimage.png',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.storefront_rounded,
                                                size: 50,
                                                color: Colors.white,
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Colors.white,
                            Color(0xFFE0F0FF),
                            Color(0xFFB0D0FF),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: const Text(
                          'Zyvionix Solutions',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Innovating the Future',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.5,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
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

class _AuroraPainter extends CustomPainter {
  final double progress;
  _AuroraPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    final paint2 = Paint()
      ..color = const Color(0xFF7000FF).withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 150);

    final paint3 = Paint()
      ..color = const Color(0xFF00FFB2).withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    final angle1 = progress * 2 * pi;
    final angle2 = (progress * 2 * pi) + pi;
    final angle3 = (progress * 2 * pi) + (pi / 2);

    final cx = size.width / 2;
    final cy = size.height / 2;

    final rX = size.width * 0.4;
    final rY = size.height * 0.3;

    canvas.drawCircle(
      Offset(cx + cos(angle1) * rX, cy + sin(angle1) * rY),
      200,
      paint1,
    );
    canvas.drawCircle(
      Offset(cx + cos(angle2) * rX * 0.8, cy + sin(angle2) * rY * 1.2),
      250,
      paint2,
    );
    canvas.drawCircle(
      Offset(cx + cos(angle3) * rX * 1.2, cy + sin(angle3) * rY * 0.9),
      180,
      paint3,
    );

    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00D4FF).withOpacity(0.1),
          const Color(0xFF00D4FF).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 300));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), centerGlow);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) => true;
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter({required this.progress});

  static final Random _rng = Random(42);
  static final List<Offset> _startPos = List.generate(
    40,
    (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );
  static final List<double> _speeds = List.generate(
    40,
    (_) => 0.2 + _rng.nextDouble() * 0.8,
  );
  static final List<double> _sizes = List.generate(
    40,
    (_) => 1.0 + _rng.nextDouble() * 2.5,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    for (int i = 0; i < 40; i++) {
      // Particles slowly move upwards
      double y = _startPos[i].dy - (progress * _speeds[i]);
      y = y - y.floor(); // Wrap around 0.0 to 1.0

      double x =
          _startPos[i].dx + (sin((progress + i) * 2 * pi) * 0.02 * _speeds[i]);

      final dx = x * size.width;
      final dy = y * size.height;

      double opacity = 1.0;
      if (y < 0.1) opacity = y / 0.1;
      if (y > 0.9) opacity = (1.0 - y) / 0.1;

      paint.color = Colors.white.withOpacity(opacity * 0.6);
      canvas.drawCircle(Offset(dx, dy), _sizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
