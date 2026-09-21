import 'dart:math';
import 'package:flutter/material.dart';
import '../challenge_engine/game_objects.dart';

/// 2.5D Procedural Painters for Orb, Cube, Crystal, Ring, Leaf, Bolt, Triangle
/// Gives every object in the BLINK universe tactile depth, specular highlights, and ambient glow.
class Object2d5Painter extends CustomPainter {
  final GameObjectType type;
  final Color baseColor;
  final double animationProgress;
  final double glowIntensity;
  final bool isPressed;

  Object2d5Painter({
    required this.type,
    required this.baseColor,
    this.animationProgress = 0.0,
    this.glowIntensity = 0.6,
    this.isPressed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.40;

    // Ambient Glow
    final glowRadius = radius * (1.35 + 0.15 * sin(animationProgress * 2 * pi));
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: (0.35 * glowIntensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    switch (type) {
      case GameObjectType.orb:
        _drawOrb(canvas, center, radius);
        break;
      case GameObjectType.cube:
        _drawIsometricCube(canvas, center, radius);
        break;
      case GameObjectType.crystal:
        _drawHexagonalCrystal(canvas, center, radius);
        break;
      case GameObjectType.ring:
        _drawTorusRing(canvas, center, radius);
        break;
      case GameObjectType.leaf:
        _drawOrganicLeaf(canvas, center, radius);
        break;
      case GameObjectType.bolt:
        _drawBeveledBolt(canvas, center, radius);
        break;
      case GameObjectType.triangle:
        _drawPyramidTriangle(canvas, center, radius);
        break;
      default:
        _drawOrb(canvas, center, radius);
        break;
    }
  }

  // ── 1. GLOSSY 2.5D ORB ──
  void _drawOrb(Canvas canvas, Offset center, double radius) {
    final hsv = HSVColor.fromColor(baseColor);
    final litColor = hsv
        .withValue((hsv.value * 1.3).clamp(0.0, 1.0))
        .withSaturation((hsv.saturation * 0.7).clamp(0.0, 1.0))
        .toColor();
    final darkColor = hsv.withValue((hsv.value * 0.45).clamp(0.0, 1.0)).toColor();

    // 3D Spherical Volume Gradient
    final sphereGradient = RadialGradient(
      center: const Alignment(-0.45, -0.45),
      radius: 0.9,
      colors: [
        Colors.white.withValues(alpha: 0.95),
        litColor,
        baseColor,
        darkColor,
      ],
      stops: const [0.0, 0.25, 0.65, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, Paint()..shader = sphereGradient);

    // Inner Glowing Core
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: 0.8),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.6));
    canvas.drawCircle(center, radius * 0.6, corePaint);

    // Specular Highlight Node (Top-Left)
    final highlightPos = center + Offset(-radius * 0.35, -radius * 0.35);
    final specPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(highlightPos, radius * 0.16, specPaint);
    canvas.drawCircle(highlightPos, radius * 0.08, Paint()..color = Colors.white);

    // Subtle Rim Light (Bottom-Right bounce light)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          baseColor.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.5),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 1), 0, pi * 0.7, false, rimPaint);
  }

  // ── 2. ISOMETRIC 3-FACE CUBE ──
  void _drawIsometricCube(Canvas canvas, Offset center, double radius) {
    final s = radius * 0.95;
    final hsv = HSVColor.fromColor(baseColor);
    final topColor = hsv
        .withValue((hsv.value * 1.3).clamp(0.0, 1.0))
        .withSaturation((hsv.saturation * 0.7).clamp(0.0, 1.0))
        .toColor();
    final leftColor = baseColor;
    final rightColor = hsv.withValue((hsv.value * 0.55).clamp(0.0, 1.0)).toColor();

    final cTop = Offset(center.dx, center.dy - s * 0.85);
    final cCenter = Offset(center.dx, center.dy - s * 0.05);
    final cBottom = Offset(center.dx, center.dy + s * 0.85);
    final cTopRight = Offset(center.dx + s * 0.85, center.dy - s * 0.45);
    final cTopLeft = Offset(center.dx - s * 0.85, center.dy - s * 0.45);
    final cBottomRight = Offset(center.dx + s * 0.85, center.dy + s * 0.45);
    final cBottomLeft = Offset(center.dx - s * 0.85, center.dy + s * 0.45);

    // Top Face (Lit)
    _drawPolygon(canvas, [cTop, cTopRight, cCenter, cTopLeft], topColor);
    // Left Face (Mid)
    _drawPolygon(canvas, [cTopLeft, cCenter, cBottom, cBottomLeft], leftColor);
    // Right Face (Shadow)
    _drawPolygon(canvas, [cCenter, cTopRight, cBottomRight, cBottom], rightColor);

    // Edge Highlights
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.45);

    canvas.drawLine(cTop, cCenter, edgePaint);
    canvas.drawLine(cCenter, cBottom, edgePaint);
    canvas.drawLine(cCenter, cTopLeft, edgePaint);
    canvas.drawLine(cCenter, cTopRight, edgePaint);

    // Top Vertex Glint
    canvas.drawCircle(cTop, 2.0, Paint()..color = Colors.white);
  }

  // ── 3. HEXAGONAL CRYSTAL PRISM ──
  void _drawHexagonalCrystal(Canvas canvas, Offset center, double radius) {
    final w = radius * 0.7;
    final h = radius * 1.1;
    final hsv = HSVColor.fromColor(baseColor);

    final lit = hsv.withValue((hsv.value * 1.25).clamp(0.0, 1.0)).toColor();
    final mid = baseColor;
    final shadow = hsv.withValue((hsv.value * 0.6).clamp(0.0, 1.0)).toColor();

    final topTip = Offset(center.dx, center.dy - h);
    final botTip = Offset(center.dx, center.dy + h);

    final pTopL = Offset(center.dx - w, center.dy - h * 0.45);
    final pTopM = Offset(center.dx, center.dy - h * 0.35);
    final pTopR = Offset(center.dx + w, center.dy - h * 0.45);

    final pBotL = Offset(center.dx - w, center.dy + h * 0.45);
    final pBotM = Offset(center.dx, center.dy + h * 0.55);
    final pBotR = Offset(center.dx + w, center.dy + h * 0.45);

    // Top cap facets
    _drawPolygon(canvas, [topTip, pTopL, pTopM], lit);
    _drawPolygon(canvas, [topTip, pTopM, pTopR], mid);

    // Middle body facets
    _drawPolygon(canvas, [pTopL, pTopM, pBotM, pBotL], lit);
    _drawPolygon(canvas, [pTopM, pTopR, pBotR, pBotM], shadow);

    // Bottom cap facets
    _drawPolygon(canvas, [pBotL, pBotM, botTip], mid);
    _drawPolygon(canvas, [pBotM, pBotR, botTip], shadow);

    // Central Bevel Line & Highlights
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawLine(topTip, pTopM, edgePaint);
    canvas.drawLine(pTopM, pBotM, edgePaint);
    canvas.drawLine(pBotM, botTip, edgePaint);
  }

  // ── 4. 2.5D TORUS RING ──
  void _drawTorusRing(Canvas canvas, Offset center, double radius) {
    final strokeW = radius * 0.32;
    final ringRadius = radius * 0.8;

    // Torus Gradient Shader
    final sweepGradient = SweepGradient(
      center: Alignment.center,
      colors: [
        Colors.white.withValues(alpha: 0.9),
        baseColor,
        baseColor.withValues(alpha: 0.5),
        baseColor,
        Colors.white.withValues(alpha: 0.9),
      ],
      stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
      transform: const GradientRotation(-pi / 4),
    ).createShader(Rect.fromCircle(center: center, radius: ringRadius));

    final ringPaint = Paint()
      ..shader = sweepGradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    canvas.drawCircle(center, ringRadius, ringPaint);

    // Inner Rim Highlight
    final innerHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(center, ringRadius - strokeW / 2, innerHighlight);

    // Outer Rim Highlight
    final outerHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(center, ringRadius + strokeW / 2, outerHighlight);
  }

  // ── 5. ORGANIC CURVED LEAF ──
  void _drawOrganicLeaf(Canvas canvas, Offset center, double radius) {
    final hsv = HSVColor.fromColor(baseColor);
    final litColor = hsv.withValue((hsv.value * 1.25).clamp(0.0, 1.0)).toColor();
    final shadowColor = hsv.withValue((hsv.value * 0.65).clamp(0.0, 1.0)).toColor();

    final topTip = Offset(center.dx, center.dy - radius);
    final botTip = Offset(center.dx, center.dy + radius);

    // Left Leaf Half (Lit)
    final leftPath = Path()
      ..moveTo(topTip.dx, topTip.dy)
      ..cubicTo(center.dx - radius * 1.3, center.dy - radius * 0.4, center.dx - radius * 1.1, center.dy + radius * 0.6, botTip.dx, botTip.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = litColor);

    // Right Leaf Half (Shadow)
    final rightPath = Path()
      ..moveTo(topTip.dx, topTip.dy)
      ..cubicTo(center.dx + radius * 1.1, center.dy - radius * 0.6, center.dx + radius * 1.3, center.dy + radius * 0.4, botTip.dx, botTip.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = shadowColor);

    // Central Leaf Vein
    final veinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawLine(topTip, botTip, veinPaint);
  }

  // ── 6. BEVELED LIGHTNING BOLT ──
  void _drawBeveledBolt(Canvas canvas, Offset center, double radius) {
    final hsv = HSVColor.fromColor(baseColor);
    final litColor = hsv.withValue((hsv.value * 1.3).clamp(0.0, 1.0)).toColor();
    final shadowColor = hsv.withValue((hsv.value * 0.6).clamp(0.0, 1.0)).toColor();

    final pTop = Offset(center.dx, center.dy - radius);
    final pRight1 = Offset(center.dx + radius * 0.6, center.dy - radius * 0.1);
    final pMid1 = Offset(center.dx + radius * 0.1, center.dy - radius * 0.1);
    final pBottom = Offset(center.dx + radius * 0.5, center.dy + radius);
    final pMid2 = Offset(center.dx - radius * 0.1, center.dy + radius * 0.2);
    final pLeft1 = Offset(center.dx - radius * 0.5, center.dy + radius * 0.2);

    final boltPath = Path()
      ..moveTo(pTop.dx, pTop.dy)
      ..lineTo(pRight1.dx, pRight1.dy)
      ..lineTo(pMid1.dx, pMid1.dy)
      ..lineTo(pBottom.dx, pBottom.dy)
      ..lineTo(pMid2.dx, pMid2.dy)
      ..lineTo(pLeft1.dx, pLeft1.dy)
      ..close();

    // Fill with gradient
    final boltGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [litColor, shadowColor],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(boltPath, Paint()..shader = boltGradient);

    // Bevel ridge line
    final ridgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.65);
    canvas.drawLine(pTop, pMid1, ridgePaint);
    canvas.drawLine(pMid1, pMid2, ridgePaint);
    canvas.drawLine(pMid2, pBottom, ridgePaint);
  }

  // ── 7. 3-FACET PYRAMID TRIANGLE ──
  void _drawPyramidTriangle(Canvas canvas, Offset center, double radius) {
    final hsv = HSVColor.fromColor(baseColor);
    final topColor = hsv.withValue((hsv.value * 1.3).clamp(0.0, 1.0)).toColor();
    final leftColor = baseColor;
    final rightColor = hsv.withValue((hsv.value * 0.55).clamp(0.0, 1.0)).toColor();

    final apex = Offset(center.dx, center.dy - radius);
    final botLeft = Offset(center.dx - radius * 0.9, center.dy + radius * 0.75);
    final botRight = Offset(center.dx + radius * 0.9, center.dy + radius * 0.75);
    final faceCenter = Offset(center.dx, center.dy + radius * 0.2);

    // Left Facet
    _drawPolygon(canvas, [apex, botLeft, faceCenter], leftColor);
    // Right Facet
    _drawPolygon(canvas, [apex, faceCenter, botRight], rightColor);
    // Bottom Facet
    _drawPolygon(canvas, [faceCenter, botLeft, botRight], topColor);

    // Bevel Ridge Lines
    final ridgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawLine(apex, faceCenter, ridgePaint);
    canvas.drawLine(faceCenter, botLeft, ridgePaint);
    canvas.drawLine(faceCenter, botRight, ridgePaint);

    canvas.drawCircle(apex, 2.0, Paint()..color = Colors.white);
  }

  void _drawPolygon(Canvas canvas, List<Offset> points, Color color) {
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

  @override
  bool shouldRepaint(covariant Object2d5Painter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.type != type ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.isPressed != isPressed;
  }
}
