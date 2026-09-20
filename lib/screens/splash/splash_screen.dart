import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// Splash screen — Dark cosmic background, crystal animation forming BLINK logo
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _lightController;
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late Animation<double> _lightExpand;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _pulse;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    // Phase 1: Light point appears and expands (0-600ms)
    _lightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _lightExpand = CurvedAnimation(parent: _lightController, curve: Curves.easeOutCubic);

    // Phase 2: Logo forms (300-1200ms)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Phase 3: Pulse (1200-1800ms)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _taglineFade = CurvedAnimation(parent: _pulseController, curve: Curves.easeIn);

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _lightController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    _pulseController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    widget.onComplete();
  }

  @override
  void dispose() {
    _lightController.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Star field background
          AnimatedBuilder(
            animation: _lightController,
            builder: (context, _) {
              return CustomPaint(
                painter: _SplashBgPainter(_lightExpand.value),
                size: Size.infinite,
              );
            },
          ),
          // Central light + logo
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_lightController, _logoController, _pulseController]),
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Crystal/eye icon
                    Transform.scale(
                      scale: _logoScale.value * _pulse.value,
                      child: Opacity(
                        opacity: _logoFade.value,
                        child: _buildCrystalIcon(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // BLINK text
                    Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _pulse.value,
                        child: Text(
                          'BLINK',
                          style: GoogleFonts.outfit(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: 8,
                            shadows: [
                              Shadow(
                                color: AppColors.primary.withValues(alpha: 0.6),
                                blurRadius: 30,
                              ),
                              Shadow(
                                color: AppColors.cyan.withValues(alpha: 0.3),
                                blurRadius: 60,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tagline
                    Opacity(
                      opacity: _taglineFade.value,
                      child: Text(
                        'The World Changes When You Look Away',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrystalIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.5),
            blurRadius: 36,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _CrystalPainter(),
            size: const Size(120, 120),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              AppAssets.blinkLogo,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrystalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Outer broken ring
    final ringPaint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Draw broken ring (3 arcs)
    final rect = Rect.fromCircle(center: center, radius: radius + 8);
    canvas.drawArc(rect, -0.5, 1.8, false, ringPaint);
    canvas.drawArc(rect, 2.0, 1.2, false, ringPaint);
    canvas.drawArc(rect, 3.8, 1.0, false, ringPaint);

    // Glowing crystal/eye shape
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.cyan.withValues(alpha: 0.8),
          AppColors.primary.withValues(alpha: 0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.8, glowPaint);

    // Inner diamond
    final path = Path();
    path.moveTo(center.dx, center.dy - radius * 0.6);
    path.lineTo(center.dx + radius * 0.4, center.dy);
    path.lineTo(center.dx, center.dy + radius * 0.6);
    path.lineTo(center.dx - radius * 0.4, center.dy);
    path.close();

    final diamondPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.cyan, AppColors.primary],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(path, diamondPaint);

    // Center bright point
    final dotPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplashBgPainter extends CustomPainter {
  final double progress;
  _SplashBgPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle radial glow from center
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.5 * progress;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.08 * progress),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);

    // A few fixed stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.3 * progress);
    final rng = Random(42);
    for (int i = 0; i < 30; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * size.height;
      final ss = 0.5 + rng.nextDouble() * 1.5;
      canvas.drawCircle(Offset(sx, sy), ss, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashBgPainter old) => old.progress != progress;
}
