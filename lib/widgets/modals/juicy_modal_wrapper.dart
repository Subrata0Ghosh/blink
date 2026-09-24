import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable Juicy Cosmic Modal Wrapper
/// Features:
/// - Springy elastic pop-in entrance physics (Curves.easeOutBack)
/// - Mesmerizing rotating celestial sunburst god-rays behind header
/// - Ambient breathing cosmic aura
/// - Floating starlight particle motes
/// - Beveled glassmorphic frame with specular rim sheen
class JuicyCosmicModal extends StatefulWidget {
  final Widget child;
  final Widget? headerBadge;
  final Color primaryGlowColor;
  final Color secondaryGlowColor;
  final double maxWidth;

  const JuicyCosmicModal({
    super.key,
    required this.child,
    this.headerBadge,
    this.primaryGlowColor = AppColors.cyan,
    this.secondaryGlowColor = AppColors.primary,
    this.maxWidth = 380,
  });

  @override
  State<JuicyCosmicModal> createState() => _JuicyCosmicModalState();
}

class _JuicyCosmicModalState extends State<JuicyCosmicModal>
    with TickerProviderStateMixin {
  // Elastic pop-in entrance controller
  late AnimationController _entranceController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // Continuous rotating celestial sunburst rays
  late AnimationController _sunburstController;

  // Gentle breathing aura
  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();

    // 1. Springy entrance (480ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _scaleAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _entranceController.forward();

    // 2. Rotating celestial sunburst rays (20s continuous rotation)
    _sunburstController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    // 3. Ambient breathing aura (3.2s)
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _sunburstController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _entranceController,
          _sunburstController,
          _breatheController,
        ]),
        builder: (context, _) {
          final scale = _scaleAnim.value;
          final sunburstAngle = _sunburstController.value * 2 * pi;
          final breathe = sin(_breatheController.value * pi);

          return FadeTransition(
            opacity: _fadeAnim,
            child: Transform.scale(
              scale: scale,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxWidth),
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // ──── 1. ROTATING CELESTIAL SUNBURST GOD-RAYS ────
                    Positioned(
                      top: -110,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _SunburstPainter(
                            rotation: sunburstAngle,
                            color: widget.primaryGlowColor.withValues(alpha: 0.22 + (breathe * 0.08)),
                            rayCount: 20,
                          ),
                          size: const Size(420, 420),
                        ),
                      ),
                    ),

                    // ──── 2. RADIANT AMBIENT BACKDROP GLOW ────
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: widget.primaryGlowColor.withValues(alpha: 0.35 + (breathe * 0.12)),
                              blurRadius: 44,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: widget.secondaryGlowColor.withValues(alpha: 0.25),
                              blurRadius: 64,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ──── 3. CORE BEVELED GLASS CONTAINER ────
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1528),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF2A3A62),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.75),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Top specular glass gleam
                          Positioned(
                            top: 0,
                            left: 20,
                            right: 20,
                            height: 1.5,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    widget.primaryGlowColor.withValues(alpha: 0.8),
                                    Colors.white.withValues(alpha: 0.9),
                                    widget.primaryGlowColor.withValues(alpha: 0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Inner modal content
                          widget.child,
                        ],
                      ),
                    ),

                    // ──── 4. OPTIONAL FLOATING TOP HEADER BADGE ────
                    if (widget.headerBadge != null)
                      Positioned(
                        top: -26,
                        child: widget.headerBadge!,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for mesmerizing rotating celestial sunburst god-rays
class _SunburstPainter extends CustomPainter {
  final double rotation;
  final Color color;
  final int rayCount;

  _SunburstPainter({
    required this.rotation,
    required this.color,
    this.rayCount = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweep = (2 * pi) / rayCount;

    final rayPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < rayCount; i++) {
      if (i % 2 == 0) {
        final startAngle = rotation + (i * sweep);
        final path = Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(
            Rect.fromCircle(center: center, radius: radius),
            startAngle,
            sweep * 0.70,
            false,
          )
          ..close();
        canvas.drawPath(path, rayPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter old) =>
      old.rotation != rotation || old.color != color || old.rayCount != rayCount;
}
