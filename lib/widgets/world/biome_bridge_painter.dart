import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'floating_island_painter.dart';

/// Renders biome-specific bridges between floating islands:
/// - Verdant: Rope & Timber Suspension Bridge with hanging vines & fireflies
/// - Crystal: Prismatic Aurora Rainbow Light Bridge with sparkling refraction
/// - Magma: Molten Basalt Stepping Stones with arcing plasma heat
/// - Aether: Golden Celestial Skyway with cloud cushion steps
/// - Starforge: Neon Cyan Cyber Data-Grid Conduit with pulsing data packets
class BiomeBridgePainter extends CustomPainter {
  final List<Offset> waypoints;
  final int activeLevel;
  final double pulseValue;

  BiomeBridgePainter({
    required this.waypoints,
    required this.activeLevel,
    required this.pulseValue,
  });

  IslandBiome _getBiomeForRealm(int realmIdx) {
    switch (realmIdx) {
      case 0:
        return IslandBiome.verdantAstral;
      case 1:
        return IslandBiome.cosmicCrystal;
      case 2:
        return IslandBiome.solarMagma;
      case 3:
        return IslandBiome.aetherCloud;
      case 4:
      default:
        return IslandBiome.cyberStarforge;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (waypoints.isEmpty) return;

    // 1. Draw Biome Atmosphere Nebula under each archipelago
    final baseYs = [2850.0, 2250.0, 1650.0, 1050.0, 450.0];
    final nebulaColors = [
      const Color(0xFF10B981), // Verdant Emerald
      const Color(0xFFA855F7), // Cosmic Purple
      const Color(0xFFFF5722), // Solar Magma
      const Color(0xFF38BDF8), // Aether Sky Blue
      AppColors.cyan,          // Cyber Cyan
    ];

    for (int b = 0; b < baseYs.length; b++) {
      final cy = baseYs[b];
      final color = nebulaColors[b];
      final rect = Rect.fromCircle(center: Offset(size.width * 0.50, cy), radius: 260);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect);
      canvas.drawCircle(Offset(size.width * 0.50, cy), 260, paint);
    }

    // 2. Draw Biome-Specific Bridges within each Realm
    for (int b = 0; b < 5; b++) {
      final baseIdx = 4 * b;
      if (baseIdx + 3 >= waypoints.length) break;

      final pBase = waypoints[baseIdx];
      final pWest = waypoints[baseIdx + 1];
      final pEast = waypoints[baseIdx + 2];
      final pGate = waypoints[baseIdx + 3];

      final biome = _getBiomeForRealm(b);

      _drawBiomeBridge(canvas, pBase, pWest, biome, (baseIdx + 2) <= activeLevel);
      _drawBiomeBridge(canvas, pBase, pEast, biome, (baseIdx + 3) <= activeLevel);
      _drawBiomeBridge(canvas, pWest, pGate, biome, (baseIdx + 4) <= activeLevel);
      _drawBiomeBridge(canvas, pEast, pGate, biome, (baseIdx + 4) <= activeLevel);

      // 3. Draw Massive Cosmic Interplanetary Stargate Bridge between Gateways
      if (b < 4 && baseIdx + 4 < waypoints.length) {
        final pNextBase = waypoints[baseIdx + 4];
        final isBridgeActive = (baseIdx + 5) <= activeLevel;
        _drawInterplanetaryWarp(canvas, pGate, pNextBase, isBridgeActive, biome);
      }
    }
  }

  void _drawBiomeBridge(Canvas canvas, Offset from, Offset to, IslandBiome biome, bool isActive) {
    switch (biome) {
      case IslandBiome.verdantAstral:
        _drawVerdantVineBridge(canvas, from, to, isActive);
        break;
      case IslandBiome.cosmicCrystal:
        _drawPrismaticRainbowBridge(canvas, from, to, isActive);
        break;
      case IslandBiome.solarMagma:
        _drawMagmaBasaltBridge(canvas, from, to, isActive);
        break;
      case IslandBiome.aetherCloud:
        _drawAetherCloudBridge(canvas, from, to, isActive);
        break;
      case IslandBiome.cyberStarforge:
        _drawCyberDataBridge(canvas, from, to, isActive);
        break;
    }
  }

  // ──── 1. VERDANT VINE & TIMBER SUSPENSION BRIDGE ────
  void _drawVerdantVineBridge(Canvas canvas, Offset from, Offset to, bool isActive) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final steps = (dist / 16).round().clamp(6, 24);

    // Natural hanging curve
    final path = Path()..moveTo(from.dx, from.dy);
    final midX = (from.dx + to.dx) / 2;
    final midY = (from.dy + to.dy) / 2 + 14.0; // Gravity sag
    path.quadraticBezierTo(midX, midY, to.dx, to.dy);

    final ropePaint = Paint()
      ..color = isActive ? const Color(0xFF10B981) : const Color(0xFF334155).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 2.5 : 1.2;

    if (isActive) {
      ropePaint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    }
    canvas.drawPath(path, ropePaint);

    // Wooden bridge crossbar planks along the sag
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final px = (1 - t) * (1 - t) * from.dx + 2 * (1 - t) * t * midX + t * t * to.dx;
      final py = (1 - t) * (1 - t) * from.dy + 2 * (1 - t) * t * midY + t * t * to.dy;

      final plankPaint = Paint()
        ..color = isActive ? const Color(0xFFD97706) : const Color(0xFF475569)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      // Perpendicular angle
      final normalX = -dy / dist * 6;
      final normalY = dx / dist * 6;
      canvas.drawLine(
        Offset(px - normalX, py - normalY),
        Offset(px + normalX, py + normalY),
        plankPaint,
      );
    }

    // Floating Starlight Fireflies
    if (isActive) {
      for (int f = 0; f < 3; f++) {
        final ft = (pulseValue + (f * 0.33)) % 1.0;
        final fx = (1 - ft) * (1 - ft) * from.dx + 2 * (1 - ft) * ft * midX + ft * ft * to.dx;
        final fy = (1 - ft) * (1 - ft) * from.dy + 2 * (1 - ft) * ft * midY + ft * ft * to.dy - 6;

        canvas.drawCircle(
          Offset(fx, fy),
          3.0,
          Paint()
            ..color = const Color(0xFF86EFAC)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(Offset(fx, fy), 1.5, Paint()..color = Colors.white);
      }
    }
  }

  // ──── 2. COSMIC PRISMATIC RAINBOW AURORA BRIDGE ────
  void _drawPrismaticRainbowBridge(Canvas canvas, Offset from, Offset to, bool isActive) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final nx = -dy / dist;
    final ny = dx / dist;

    // 3 Radiant refracted crystal light ribbons (Cyan, Violet, Magenta)
    final ribbons = [
      {'color': const Color(0xFF38BDF8), 'offset': -4.0},
      {'color': const Color(0xFFA855F7), 'offset': 0.0},
      {'color': const Color(0xFFF472B6), 'offset': 4.0},
    ];

    for (final r in ribbons) {
      final offset = r['offset'] as double;
      final color = r['color'] as Color;

      final p1 = Offset(from.dx + nx * offset, from.dy + ny * offset);
      final p2 = Offset(to.dx + nx * offset, to.dy + ny * offset);

      final paint = Paint()
        ..color = isActive ? color.withValues(alpha: 0.8) : color.withValues(alpha: 0.15)
        ..strokeWidth = isActive ? 2.0 : 1.0
        ..style = PaintingStyle.stroke;

      if (isActive) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
      }

      _drawDashedLine(canvas, p1, p2, paint, dashLength: 9, gapLength: 4);
    }

    // Shimmering diamond prism sparkle
    if (isActive) {
      final t = pulseValue;
      final px = from.dx + dx * t;
      final py = from.dy + dy * t;

      canvas.drawCircle(
        Offset(px, py),
        4.0,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  // ──── 3. SOLAR MAGMA & BASALT PLASMA BRIDGE ────
  void _drawMagmaBasaltBridge(Canvas canvas, Offset from, Offset to, bool isActive) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    // Glowing core magma beam
    final plasmaPaint = Paint()
      ..color = isActive ? const Color(0xFFFF6D00) : const Color(0xFF7C2D12).withValues(alpha: 0.3)
      ..strokeWidth = isActive ? 3.5 : 1.5
      ..style = PaintingStyle.stroke;

    if (isActive) {
      plasmaPaint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    }
    canvas.drawLine(from, to, plasmaPaint);

    // Floating basalt stepping platforms
    final stepCount = (dist / 22).round().clamp(4, 14);
    for (int i = 1; i < stepCount; i++) {
      final t = i / stepCount;
      final px = from.dx + dx * t;
      final py = from.dy + dy * t;

      // Dark volcanic basalt stone
      canvas.drawCircle(Offset(px, py), 5.0, Paint()..color = const Color(0xFF1C1917));
      if (isActive) {
        // Glowing molten magma fissure in the stone
        canvas.drawCircle(
          Offset(px, py),
          2.5,
          Paint()..color = const Color(0xFFFFB74D),
        );
      }
    }

    // Traveling magma spark
    if (isActive) {
      final t = (pulseValue * 1.5) % 1.0;
      final px = from.dx + dx * t;
      final py = from.dy + dy * t;
      canvas.drawCircle(
        Offset(px, py),
        3.5,
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  // ──── 4. AETHER GOLDEN CELESTIAL CLOUD BRIDGE ────
  void _drawAetherCloudBridge(Canvas canvas, Offset from, Offset to, bool isActive) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    // Twin golden balustrades
    final nx = -dy / dist * 5;
    final ny = dx / dist * 5;

    final goldPaint = Paint()
      ..color = isActive ? const Color(0xFFFACC15) : const Color(0xFF94A3B8).withValues(alpha: 0.2)
      ..strokeWidth = isActive ? 1.8 : 1.0
      ..style = PaintingStyle.stroke;

    _drawDashedLine(canvas, Offset(from.dx + nx, from.dy + ny), Offset(to.dx + nx, to.dy + ny), goldPaint);
    _drawDashedLine(canvas, Offset(from.dx - nx, from.dy - ny), Offset(to.dx - nx, to.dy - ny), goldPaint);

    // Fluffy cloud stepping cushions
    final puffCount = (dist / 24).round().clamp(4, 12);
    for (int i = 1; i < puffCount; i++) {
      final t = i / puffCount;
      final px = from.dx + dx * t;
      final py = from.dy + dy * t;

      final cloudPaint = Paint()
        ..color = isActive
            ? Colors.white.withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(px, py), 6.0, cloudPaint);
    }
  }

  // ──── 5. CYBER STARFORGE DATA CONDUIT ────
  void _drawCyberDataBridge(Canvas canvas, Offset from, Offset to, bool isActive) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final cyberPaint = Paint()
      ..color = isActive ? AppColors.cyan : const Color(0xFF0F172A)
      ..strokeWidth = isActive ? 2.5 : 1.0
      ..style = PaintingStyle.stroke;

    if (isActive) {
      cyberPaint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    }

    _drawDashedLine(canvas, from, to, cyberPaint, dashLength: 10, gapLength: 4);

    // Traveling glowing binary data packets (high-speed cyber cubes)
    if (isActive) {
      for (int i = 0; i < 2; i++) {
        final t = (pulseValue + (i * 0.5)) % 1.0;
        final px = from.dx + dx * t;
        final py = from.dy + dy * t;

        canvas.drawRect(
          Rect.fromCenter(center: Offset(px, py), width: 6, height: 6),
          Paint()..color = Colors.white,
        );
        canvas.drawRect(
          Rect.fromCenter(center: Offset(px, py), width: 10, height: 10),
          Paint()
            ..color = AppColors.cyan.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }
  }

  // ──── INTERPLANETARY WARP BRIDGE (BETWEEN REALMS) ────
  void _drawInterplanetaryWarp(
    Canvas canvas,
    Offset from,
    Offset to,
    bool isActive,
    IslandBiome biome,
  ) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final nx = -dy / dist * 10;
    final ny = dx / dist * 10;

    final beamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 3.5 : 1.5;

    if (isActive) {
      beamPaint.color = AppColors.cyan.withValues(alpha: 0.6);
      beamPaint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 5);
    } else {
      beamPaint.color = Colors.white.withValues(alpha: 0.10);
    }

    _drawDashedLine(canvas, Offset(from.dx + nx, from.dy + ny), Offset(to.dx + nx, to.dy + ny), beamPaint, dashLength: 12, gapLength: 6);
    _drawDashedLine(canvas, Offset(from.dx - nx, from.dy - ny), Offset(to.dx - nx, to.dy - ny), beamPaint, dashLength: 12, gapLength: 6);

    if (isActive) {
      // Traveling warp spheres
      for (int i = 0; i < 4; i++) {
        final t = (pulseValue + (i * 0.25)) % 1.0;
        final px = from.dx + dx * t;
        final py = from.dy + dy * t;

        canvas.drawCircle(
          Offset(px, py),
          5.0,
          Paint()
            ..color = AppColors.cosmicCyanLight
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(Offset(px, py), 2.5, Paint()..color = Colors.white);
      }
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint, {
    double dashLength = 8.0,
    double gapLength = 6.0,
  }) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;

    var currentDist = 0.0;
    while (currentDist < distance) {
      final startX = from.dx + unitX * currentDist;
      final startY = from.dy + unitY * currentDist;
      final endDist = (currentDist + dashLength).clamp(0.0, distance);
      final endX = from.dx + unitX * endDist;
      final endY = from.dy + unitY * endDist;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      currentDist += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant BiomeBridgePainter oldDelegate) {
    return oldDelegate.activeLevel != activeLevel || oldDelegate.pulseValue != pulseValue;
  }
}
