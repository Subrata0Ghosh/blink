import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Calm Atmospheric Cosmic Glow & Floating Motes
/// Delivers a deeply relaxing, eye-catching, and satisfying visual presence.
class CalmAmbientGlow extends StatefulWidget {
  final Widget? child;
  final bool enableMotes;

  const CalmAmbientGlow({
    super.key,
    this.child,
    this.enableMotes = true,
  });

  @override
  State<CalmAmbientGlow> createState() => _CalmAmbientGlowState();
}

class _CalmAmbientGlowState extends State<CalmAmbientGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat(reverse: true);

    _breathingAnimation = CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        final t = _breathingAnimation.value;

        return Stack(
          children: [
            // Soft Breathing Nebula Center
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.2 + (t * 0.1)),
                    radius: 0.9 + (t * 0.3),
                    colors: [
                      Color.lerp(
                        const Color(0xFF1E2652),
                        const Color(0xFF122C44),
                        t,
                      )!.withValues(alpha: 0.5 + t * 0.25),
                      const Color(0xFF0F142A).withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Gentle Floating Stardust Motes
            if (widget.enableMotes)
              Positioned.fill(
                child: CustomPaint(
                  painter: _CalmMotesPainter(progress: t),
                ),
              ),

            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}

class _CalmMotesPainter extends CustomPainter {
  final double progress;
  _CalmMotesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(1337);
    final count = 18;

    for (int i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final radius = 1.0 + rng.nextDouble() * 2.2;
      final phase = (i * 0.35 + progress) % 1.0;

      // Gentle vertical float and fade
      final dy = baseY - (phase * 30.0);
      final alpha = sin(phase * pi).clamp(0.0, 1.0) * (0.2 + rng.nextDouble() * 0.35);

      final paint = Paint()
        ..color = (i % 2 == 0 ? AppColors.cyan : AppColors.gold).withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      canvas.drawCircle(Offset(baseX, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CalmMotesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
