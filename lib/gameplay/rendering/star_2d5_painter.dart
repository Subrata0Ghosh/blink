import 'dart:math';
import 'package:flutter/material.dart';

/// 2.5D Procedural Painter for the BLINK "Cosmic Star"
/// Features:
/// - 10 3D bevel triangular facets (each star point has lit and shadowed halves)
/// - Center peak with 3D elevation
/// - Directional illumination (upper-left light angle)
/// - Soft multi-layered glow halo (pink / violet / gold accents)
/// - Orbiting cosmic star-dust particles
/// - Shimmering center core and tip glints
class Star2d5Painter extends CustomPainter {
  final Color baseColor;
  final double animationProgress; // 0.0 to 1.0
  final double glowIntensity;
  final bool isPressed;

  Star2d5Painter({
    required this.baseColor,
    this.animationProgress = 0.0,
    this.glowIntensity = 0.6,
    this.isPressed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.44;
    final innerRadius = outerRadius * 0.46;

    // 1. Multi-layered Ambient Glow
    final glowRadius = outerRadius * (1.35 + 0.15 * sin(animationProgress * 2 * pi));
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: (0.4 * glowIntensity).clamp(0.0, 1.0)),
          const Color(0xFFFF6EE6).withValues(alpha: (0.2 * glowIntensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    // 2. Orbiting Star Dust Particles
    _drawStarDust(canvas, center, outerRadius, animationProgress);

    // 3. Compute 10 Star Vertices (5 outer tips, 5 inner valleys)
    const points = 5;
    const angleStep = pi / points;
    final outerTips = <Offset>[];
    final innerValleys = <Offset>[];

    for (int i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? outerRadius : innerRadius;
      final angle = -pi / 2 + (i * angleStep);
      final pt = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (isOuter) {
        outerTips.add(pt);
      } else {
        innerValleys.add(pt);
      }
    }

    // 4. Directional Shading for 10 3D Bevel Facets
    // Light source from (-0.5, -0.866) (approx 10 o'clock)
    final lightDir = const Offset(-0.6, -0.8).direction;
    final hsv = HSVColor.fromColor(baseColor);

    for (int i = 0; i < points; i++) {
      final tip = outerTips[i];
      final prevValley = innerValleys[(i - 1 + points) % points];
      final nextValley = innerValleys[i];

      // Left facet of this point (center -> prevValley -> tip)
      final leftFacetNorm = (tip - prevValley);
      final leftAngle = atan2(leftFacetNorm.dy, leftFacetNorm.dx) - pi / 2;
      final leftLightFactor = ((cos(leftAngle - lightDir) + 1) / 2).clamp(0.15, 1.0);

      // Right facet of this point (center -> tip -> nextValley)
      final rightFacetNorm = (nextValley - tip);
      final rightAngle = atan2(rightFacetNorm.dy, rightFacetNorm.dx) - pi / 2;
      final rightLightFactor = ((cos(rightAngle - lightDir) + 1) / 2).clamp(0.15, 1.0);

      final leftColor = hsv
          .withValue((hsv.value * (0.65 + 0.55 * leftLightFactor)).clamp(0.0, 1.0))
          .withSaturation((hsv.saturation * (1.1 - 0.25 * leftLightFactor)).clamp(0.0, 1.0))
          .toColor();

      final rightColor = hsv
          .withValue((hsv.value * (0.55 + 0.45 * rightLightFactor)).clamp(0.0, 1.0))
          .withSaturation((hsv.saturation * (1.1 - 0.25 * rightLightFactor)).clamp(0.0, 1.0))
          .toColor();

      // Draw left facet
      _drawTriangle(canvas, center, prevValley, tip, leftColor);
      // Draw right facet
      _drawTriangle(canvas, center, tip, nextValley, rightColor);
    }

    // 5. Bevel Ridge Lines & Specular Highlights
    final ridgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.4);

    for (int i = 0; i < points; i++) {
      canvas.drawLine(center, outerTips[i], ridgePaint);
    }

    final valleyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.black.withValues(alpha: 0.35);

    for (int i = 0; i < points; i++) {
      canvas.drawLine(center, innerValleys[i], valleyPaint);
    }

    // 6. Central Elevated Apex Shimmer
    final apexPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.85),
          baseColor.withValues(alpha: 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius * 0.9));
    canvas.drawCircle(center, innerRadius * 0.9, apexPaint);

    // 7. Top-Left Tip Glint
    final topTip = outerTips[0];
    final glintPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(topTip, 2.0, glintPaint);
    canvas.drawCircle(topTip, 1.0, Paint()..color = Colors.white);
  }

  void _drawTriangle(Canvas canvas, Offset p1, Offset p2, Offset p3, Color color) {
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  void _drawStarDust(Canvas canvas, Offset center, double radius, double progress) {
    const count = 5;
    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * pi / count) + (progress * 2 * pi * 0.75);
      final dist = radius * (1.12 + 0.18 * sin(progress * 3 * pi + i * 2));
      final pos = center + Offset(cos(angle) * dist, sin(angle) * dist);
      final alpha = ((sin(progress * 4 * pi + i) + 1) / 2 * 0.75).clamp(0.0, 1.0);

      if (alpha > 0.08) {
        final dotPaint = Paint()
          ..color = const Color(0xFFFF80DF).withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
        canvas.drawCircle(pos, 1.6, dotPaint);
        canvas.drawCircle(pos, 0.8, Paint()..color = Colors.white.withValues(alpha: alpha));
      }
    }
  }

  @override
  bool shouldRepaint(covariant Star2d5Painter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.isPressed != isPressed;
  }
}
