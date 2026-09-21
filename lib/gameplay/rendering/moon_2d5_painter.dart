import 'dart:math';
import 'package:flutter/material.dart';

/// 2.5D Procedural Painter for the BLINK "Luminous Moon"
/// Features:
/// - True 2.5D spherical crescent geometry
/// - Directional rim lighting along the outer curve
/// - Crater depth texture impressions with subtle inner shading
/// - Spherical falloff gradient giving volume and depth
/// - Soft celestial back-glow
/// - Tiny floating lunar dust specks near the tips
class Moon2d5Painter extends CustomPainter {
  final Color baseColor;
  final double animationProgress; // 0.0 to 1.0
  final double glowIntensity;
  final bool isPressed;

  Moon2d5Painter({
    required this.baseColor,
    this.animationProgress = 0.0,
    this.glowIntensity = 0.6,
    this.isPressed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.40;

    // 1. Ambient Celestial Glow
    final glowRadius = radius * (1.35 + 0.15 * sin(animationProgress * 2 * pi));
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: (0.38 * glowIntensity).clamp(0.0, 1.0)),
          const Color(0xFF00E5FF).withValues(alpha: (0.15 * glowIntensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    // 2. Drifting Lunar Dust
    _drawLunarDust(canvas, center, radius, animationProgress);

    // 3. Moon Crescent Path
    // Outer circle centered at `center`, inner cutout circle offset slightly right/up
    final innerOffset = Offset(radius * 0.48, -radius * 0.18);
    final innerRadius = radius * 0.78;

    final crescentPath = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      Path()..addOval(Rect.fromCircle(center: center + innerOffset, radius: innerRadius)),
    );

    // 4. 2.5D Spherical Shading Gradient
    final hsv = HSVColor.fromColor(baseColor);
    final litColor = hsv
        .withValue((hsv.value * 1.25).clamp(0.0, 1.0))
        .withSaturation((hsv.saturation * 0.75).clamp(0.0, 1.0))
        .toColor();
    final midColor = baseColor;
    final darkColor = hsv.withValue((hsv.value * 0.5).clamp(0.0, 1.0)).toColor();

    final sphereGradient = RadialGradient(
      center: const Alignment(-0.55, -0.55),
      radius: 0.95,
      colors: [
        Colors.white.withValues(alpha: 0.95),
        litColor,
        midColor,
        darkColor,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(crescentPath, Paint()..shader = sphereGradient);

    // 5. Craters / Subtle Lunar Surface Details (clipped to crescent)
    canvas.save();
    canvas.clipPath(crescentPath);

    _drawCrater(canvas, center + Offset(-radius * 0.35, -radius * 0.15), radius * 0.18, darkColor);
    _drawCrater(canvas, center + Offset(-radius * 0.15, radius * 0.35), radius * 0.22, darkColor);
    _drawCrater(canvas, center + Offset(-radius * 0.5, radius * 0.2), radius * 0.12, darkColor);

    // Subtle inner shadow gradient along the inner curve
    final innerShadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.4, -0.1),
        radius: 0.8,
        colors: [
          Colors.black.withValues(alpha: 0.55),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7],
      ).createShader(Rect.fromCircle(center: center + innerOffset, radius: innerRadius + 10));
    canvas.drawPath(crescentPath, innerShadowPaint);

    canvas.restore();

    // 6. Crisp Outer Rim Highlight
    // Draw an arc along the outer rim facing light (top-left)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Colors.white.withValues(alpha: 0.8),
          baseColor.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final rimRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rimRect, pi * 0.65, pi * 1.1, false, rimPaint);

    // 7. Tip Specular Highlights
    // Tip 1 (top horn)
    final tipPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    final topHorn = Offset(center.dx + radius * 0.15, center.dy - radius * 0.95);
    canvas.drawCircle(topHorn, 1.8, tipPaint);
    canvas.drawCircle(topHorn, 0.9, Paint()..color = Colors.white);
  }

  void _drawCrater(Canvas canvas, Offset center, double radius, Color shadowColor) {
    // Crater shadow rim
    final craterShadow = Paint()
      ..color = shadowColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, craterShadow);

    // Crater lit rim (facing top-left)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi * 0.75, pi * 0.9, false, rimPaint);
  }

  void _drawLunarDust(Canvas canvas, Offset center, double radius, double progress) {
    const count = 4;
    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * pi / count) + (progress * 2 * pi * 0.5);
      final dist = radius * (1.1 + 0.15 * sin(progress * 3 * pi + i * 2));
      final pos = center + Offset(cos(angle) * dist, sin(angle) * dist);
      final alpha = ((sin(progress * 5 * pi + i) + 1) / 2 * 0.7).clamp(0.0, 1.0);

      if (alpha > 0.08) {
        final dotPaint = Paint()
          ..color = const Color(0xFF80D8FF).withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        canvas.drawCircle(pos, 1.5, dotPaint);
        canvas.drawCircle(pos, 0.7, Paint()..color = Colors.white.withValues(alpha: alpha));
      }
    }
  }

  @override
  bool shouldRepaint(covariant Moon2d5Painter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.isPressed != isPressed;
  }
}
