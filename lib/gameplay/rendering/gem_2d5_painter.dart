import 'dart:math';
import 'package:flutter/material.dart';

/// 2.5D Procedural Painter for the BLINK "Shift Gem"
/// Features:
/// - Faceted 3D crystal geometry (table, upper facets, side facets, lower pavilion)
/// - Directional lighting (upper-left light source, specular highlights, facet shading)
/// - Inner luminous core with depth glow
/// - Animated light streak / glint across facet faces
/// - Micro-sparkle ambient particles orbiting the crystal
class Gem2d5Painter extends CustomPainter {
  final Color baseColor;
  final double animationProgress; // 0.0 to 1.0 for continuous idle glint / sparkles
  final double glowIntensity; // 0.0 to 1.0
  final bool isPressed;

  Gem2d5Painter({
    required this.baseColor,
    this.animationProgress = 0.0,
    this.glowIntensity = 0.6,
    this.isPressed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    // 1. Ambient / Outer Glow
    final glowRadius = radius * (1.4 + 0.2 * sin(animationProgress * 2 * pi));
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: (0.45 * glowIntensity).clamp(0.0, 1.0)),
          baseColor.withValues(alpha: (0.15 * glowIntensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    // 2. Micro-sparkle particles orbiting the gem
    _drawSparkles(canvas, center, radius, animationProgress);

    // 3. Faceted Crystal Geometry
    // Classic emerald/brilliant cut polygon coordinates
    final w = radius * 0.95;
    final h = radius * 1.15;

    // Top table vertices
    final tTopLeft = Offset(center.dx - w * 0.35, center.dy - h * 0.5);
    final tTopRight = Offset(center.dx + w * 0.35, center.dy - h * 0.5);
    final tMidLeft = Offset(center.dx - w * 0.55, center.dy - h * 0.1);
    final tMidRight = Offset(center.dx + w * 0.55, center.dy - h * 0.1);

    // Outer girdle vertices
    final gTopLeft = Offset(center.dx - w * 0.65, center.dy - h * 0.7);
    final gTopRight = Offset(center.dx + w * 0.65, center.dy - h * 0.7);
    final gLeft = Offset(center.dx - w * 0.95, center.dy - h * 0.1);
    final gRight = Offset(center.dx + w * 0.95, center.dy - h * 0.1);

    // Bottom pavilion tip
    final pBottom = Offset(center.dx, center.dy + h * 0.9);
    final pMidLeft = Offset(center.dx - w * 0.45, center.dy + h * 0.35);
    final pMidRight = Offset(center.dx + w * 0.45, center.dy + h * 0.35);

    // Color variations for 3D facets based on directional lighting
    final hsv = HSVColor.fromColor(baseColor);
    final litColor = hsv.withValue((hsv.value * 1.25).clamp(0.0, 1.0)).withSaturation((hsv.saturation * 0.8).clamp(0.0, 1.0)).toColor();
    final midColor = baseColor;
    final shadowColor = hsv.withValue((hsv.value * 0.65).clamp(0.0, 1.0)).toColor();
    final darkShadowColor = hsv.withValue((hsv.value * 0.45).clamp(0.0, 1.0)).toColor();
    final highlightWhite = Colors.white.withValues(alpha: 0.85);

    // ── LOWER PAVILION FACETS ──
    // Bottom Left Facet (shadow side)
    _drawFacet(canvas, [pMidLeft, gLeft, pBottom], shadowColor);
    // Bottom Center Facet
    _drawFacet(canvas, [pMidLeft, pBottom, pMidRight], midColor);
    // Bottom Right Facet (deeper shadow)
    _drawFacet(canvas, [pMidRight, pBottom, gRight], darkShadowColor);

    // ── MID SECTION FACETS ──
    _drawFacet(canvas, [tMidLeft, gLeft, pMidLeft], midColor);
    _drawFacet(canvas, [tMidLeft, pMidLeft, pMidRight, tMidRight], litColor);
    _drawFacet(canvas, [tMidRight, pMidRight, gRight], shadowColor);

    // ── TOP CROWN FACETS ──
    // Top-left facet (directly faces light source)
    _drawFacet(canvas, [gTopLeft, gTopRight, tTopRight, tTopLeft], litColor);
    _drawFacet(canvas, [gTopLeft, tTopLeft, tMidLeft, gLeft], litColor);
    _drawFacet(canvas, [gTopRight, gRight, tMidRight, tTopRight], shadowColor);

    // ── TABLE (Center face) ──
    final tablePath = Path()
      ..moveTo(tTopLeft.dx, tTopLeft.dy)
      ..lineTo(tTopRight.dx, tTopRight.dy)
      ..lineTo(tMidRight.dx, tMidRight.dy)
      ..lineTo(tMidLeft.dx, tMidLeft.dy)
      ..close();

    final tableShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        litColor,
        baseColor.withValues(alpha: 0.9),
      ],
    ).createShader(tablePath.getBounds());

    canvas.drawPath(tablePath, Paint()..shader = tableShader);

    // ── INNER LUMINOUS CORE ──
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.75),
          baseColor.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center + const Offset(-2, -2), radius: radius * 0.45));
    canvas.drawCircle(center + const Offset(-2, -2), radius * 0.45, corePaint);

    // ── ANIMATED LIGHT GLINT / SWEEP ──
    _drawGlint(canvas, center, radius, animationProgress);

    // ── CRISP BEVEL EDGES & SPECULAR ACCENTS ──
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.45);

    // Draw main crystal outer contour
    final outerContour = Path()
      ..moveTo(gTopLeft.dx, gTopLeft.dy)
      ..lineTo(gTopRight.dx, gTopRight.dy)
      ..lineTo(gRight.dx, gRight.dy)
      ..lineTo(pBottom.dx, pBottom.dy)
      ..lineTo(gLeft.dx, gLeft.dy)
      ..close();
    canvas.drawPath(outerContour, edgePaint);

    // Inner facet lines
    final innerLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = Colors.white.withValues(alpha: 0.28);
    canvas.drawLine(tTopLeft, tTopRight, innerLinePaint);
    canvas.drawLine(tTopRight, tMidRight, innerLinePaint);
    canvas.drawLine(tMidRight, tMidLeft, innerLinePaint);
    canvas.drawLine(tMidLeft, tTopLeft, innerLinePaint);
    canvas.drawLine(tMidLeft, pMidLeft, innerLinePaint);
    canvas.drawLine(tMidRight, pMidRight, innerLinePaint);
    canvas.drawLine(pMidLeft, pBottom, innerLinePaint);
    canvas.drawLine(pMidRight, pBottom, innerLinePaint);

    // Specular highlight star at the apex corner
    final apexPoint = tTopLeft + const Offset(2, 2);
    final specPaint = Paint()
      ..color = highlightWhite
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(apexPoint, 2.5, specPaint);
    canvas.drawCircle(apexPoint, 1.2, Paint()..color = Colors.white);
  }

  void _drawFacet(Canvas canvas, List<Offset> points, Color color) {
    if (points.length < 3) return;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  void _drawGlint(Canvas canvas, Offset center, double radius, double progress) {
    // A glint sweep travels across from -radius to +radius during 0.0..0.45 of animation cycle
    final cycle = (progress * 1.5) % 1.0;
    if (cycle > 0.45) return; // Silent period

    final t = cycle / 0.45; // 0.0 to 1.0
    final glintX = center.dx - radius * 1.2 + (radius * 2.4 * t);
    final glintWidth = radius * 0.25;

    final glintPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: (0.6 * sin(t * pi)).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(glintX - glintWidth, center.dy - radius, glintWidth * 2, radius * 2))
      ..blendMode = BlendMode.screen;

    canvas.save();
    canvas.drawRect(Rect.fromCircle(center: center, radius: radius), glintPaint);
    canvas.restore();
  }

  void _drawSparkles(Canvas canvas, Offset center, double radius, double progress) {
    const sparkleCount = 4;
    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i * 2 * pi / sparkleCount) + (progress * 2 * pi);
      final dist = radius * (1.15 + 0.15 * sin(progress * 4 * pi + i));
      final pos = center + Offset(cos(angle) * dist, sin(angle) * dist);
      final alpha = ((sin(progress * 6 * pi + i * 1.5) + 1) / 2 * 0.8).clamp(0.0, 1.0);

      if (alpha > 0.1) {
        final sparkPaint = Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(pos, 1.8, sparkPaint);
        canvas.drawCircle(pos, 0.9, Paint()..color = Colors.white.withValues(alpha: alpha));
      }
    }
  }

  @override
  bool shouldRepaint(covariant Gem2d5Painter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.isPressed != isPressed;
  }
}
