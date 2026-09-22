import 'dart:async';
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

  Timer? _t1;
  Timer? _t2;
  Timer? _t3;
  Timer? _t4;

  void _startAnimation() {
    _t1 = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _lightController.forward();
      _t2 = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _logoController.forward();
        _t3 = Timer(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          _pulseController.forward();
          _t4 = Timer(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            widget.onComplete();
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _t1?.cancel();
    _t2?.cancel();
    _t3?.cancel();
    _t4?.cancel();
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
                    // 3D Embossed BLINK Typography
                    Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _pulse.value,
                        child: Text(
                          'BLINK',
                          style: GoogleFonts.outfit(
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 8,
                            shadows: [
                              // Top highlight rim
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.8),
                                offset: const Offset(0, -1),
                                blurRadius: 1,
                              ),
                              // 3D extruded bevel edge
                              const Shadow(
                                color: Color(0xFF007A99),
                                offset: Offset(0, 3),
                                blurRadius: 2,
                              ),
                              const Shadow(
                                color: Color(0xFF004455),
                                offset: Offset(0, 5),
                                blurRadius: 4,
                              ),
                              // Deep space ambient glow
                              Shadow(
                                color: AppColors.cyan.withValues(alpha: 0.8),
                                blurRadius: 36,
                              ),
                              Shadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 60,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Tagline
                    Opacity(
                      opacity: _taglineFade.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'THE COSMOS SHIFTS WHEN YOU BLINK',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cyanLight,
                            letterSpacing: 2.2,
                          ),
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
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Ambient pulsing aura
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.6),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 65,
                  spreadRadius: 12,
                ),
              ],
            ),
          ),

          // 2. Custom 3D Crystal Relic Painter
          CustomPaint(
            painter: _CrystalPainter(),
            size: const Size(130, 130),
          ),

          // 3. 3D Convex Glossy Dome with BLINK Logo
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF060914),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.55),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  offset: const Offset(0, 8),
                  blurRadius: 14,
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // Full edge-to-edge logo image filling the circle seamlessly
                  Image.asset(
                    AppAssets.blinkLogo,
                    fit: BoxFit.cover,
                  ),
                  // Curved top glass specular sheen along the dome perimeter
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.38),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom inner sphere shadow for 3D depth
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 26,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
