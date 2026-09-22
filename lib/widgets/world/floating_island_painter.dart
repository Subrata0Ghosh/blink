import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// Enum defining the 5 cosmic biomes for floating islands in BLINK
enum IslandBiome {
  verdantAstral,   // Levels 1-4: Emerald grass, mossy cliff strata, crystal seeds
  cosmicCrystal,   // Levels 5-8: Violet crystal plateau, amethyst spires
  solarMagma,      // Levels 9-12: Obsidian basalt, glowing lava veins, golden embers
  aetherCloud,     // Levels 13-16: Celestial sky-marble, cloud cushion
  cyberStarforge,  // Levels 17-20: Hexagonal cyber-platform, cyan energy conduits
}

/// A standalone 3D Floating Island widget that cradles one or more level nodes.
/// Features:
/// - Isolated high-fidelity 3D platform asset without background
/// - Idle cosmic levitation physics with harmonic biome offsets
/// - True 3D orbiting crystal satellites (depth-sorted behind and in front of the island)
/// - Pulsing ancient rune dais glow on the active level
/// - Milestone realm gateway styling
class FloatingIslandWidget extends StatefulWidget {
  final IslandBiome biome;
  final double width;
  final double height;
  final bool isCurrent;
  final bool isMilestone;
  final Widget child;

  const FloatingIslandWidget({
    super.key,
    required this.biome,
    this.width = 150,
    this.height = 145,
    this.isCurrent = false,
    this.isMilestone = false,
    required this.child,
  });

  @override
  State<FloatingIslandWidget> createState() => _FloatingIslandWidgetState();
}

class _FloatingIslandWidgetState extends State<FloatingIslandWidget>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    final phaseOffset = (widget.biome.index * 0.22) % 1.0;
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
      value: phaseOffset,
    )..repeat(reverse: true);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    if (widget.isCurrent || widget.isMilestone) {
      _orbitController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant FloatingIslandWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.isCurrent || widget.isMilestone) && !_orbitController.isAnimating) {
      _orbitController.repeat();
    } else if (!widget.isCurrent && !widget.isMilestone && _orbitController.isAnimating) {
      _orbitController.stop();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  Color _getBiomeGlowColor() {
    switch (widget.biome) {
      case IslandBiome.verdantAstral:
        return const Color(0xFF22C55E);
      case IslandBiome.cosmicCrystal:
        return const Color(0xFFA855F7);
      case IslandBiome.solarMagma:
        return const Color(0xFFFF6D00);
      case IslandBiome.aetherCloud:
        return const Color(0xFF38BDF8);
      case IslandBiome.cyberStarforge:
        return AppColors.cyan;
    }
  }

  ColorFilter? _getBiomeColorFilter() {
    switch (widget.biome) {
      case IslandBiome.verdantAstral:
        return null;
      case IslandBiome.cosmicCrystal:
        return const ColorFilter.matrix(<double>[
          0.7, 0.0, 0.4, 0, 30,
          0.1, 0.4, 0.3, 0, 0,
          0.3, 0.0, 1.2, 0, 50,
          0.0, 0.0, 0.0, 1, 0,
        ]);
      case IslandBiome.solarMagma:
        return const ColorFilter.matrix(<double>[
          1.3, 0.1, 0.0, 0, 50,
          0.5, 0.6, 0.0, 0, 10,
          0.0, 0.0, 0.4, 0, 0,
          0.0, 0.0, 0.0, 1, 0,
        ]);
      case IslandBiome.aetherCloud:
        return const ColorFilter.matrix(<double>[
          0.6, 0.2, 0.4, 0, 40,
          0.4, 0.8, 0.4, 0, 50,
          0.5, 0.3, 1.2, 0, 80,
          0.0, 0.0, 0.0, 1, 0,
        ]);
      case IslandBiome.cyberStarforge:
        return const ColorFilter.matrix(<double>[
          0.3, 0.1, 0.4, 0, 0,
          0.2, 1.1, 0.4, 0, 40,
          0.3, 0.3, 1.4, 0, 60,
          0.0, 0.0, 0.0, 1, 0,
        ]);
    }
  }

  Widget _buildOrbitShard({
    required double angle,
    required double radiusX,
    required double radiusY,
    required Offset center,
    required Color color,
    required bool isForeground,
  }) {
    final sinVal = sin(angle);
    final inForeground = sinVal >= 0;
    if (inForeground != isForeground) return const SizedBox.shrink();

    final cosVal = cos(angle);
    final posX = center.dx + cosVal * radiusX;
    final posY = center.dy + sinVal * radiusY;
    final scale = isForeground ? 1.0 + (sinVal * 0.25) : 0.65 + (sinVal * 0.15);
    final opacity = isForeground ? (0.75 + sinVal * 0.25).clamp(0.0, 1.0) : 0.40;

    return Positioned(
      left: posX - 6 * scale,
      top: posY - 6 * scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 12 * scale,
          height: 12 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: color,
                blurRadius: 8 * scale,
                spreadRadius: 2 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = _getBiomeGlowColor();
    final filter = _getBiomeColorFilter();

    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _orbitController]),
      builder: (context, _) {
        final floatOffset = sin(_floatController.value * 2 * pi) * 2.8;
        final orbitAngle = _orbitController.value * 2 * pi;
        final daisCenter = Offset(widget.width * 0.50, (widget.height * 0.32) + floatOffset);
        final orbitRx = widget.width * 0.46;
        final orbitRy = widget.height * 0.16;

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. Ambient Biome Underglow / Void Depth Shadow
              Positioned(
                bottom: widget.height * 0.08 - floatOffset,
                child: Container(
                  width: widget.width * 0.62,
                  height: widget.height * 0.24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(
                          alpha: widget.isMilestone ? 0.55 : 0.35,
                        ),
                        blurRadius: widget.isMilestone ? 36 : 28,
                        spreadRadius: widget.isMilestone ? 6 : 4,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.50),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. 3D Orbiting Satellites (Far side - BEHIND island)
              if (widget.isCurrent || widget.isMilestone) ...[
                _buildOrbitShard(
                  angle: orbitAngle,
                  radiusX: orbitRx,
                  radiusY: orbitRy,
                  center: daisCenter,
                  color: glowColor,
                  isForeground: false,
                ),
                _buildOrbitShard(
                  angle: orbitAngle + (2 * pi / 3),
                  radiusX: orbitRx,
                  radiusY: orbitRy,
                  center: daisCenter,
                  color: widget.isMilestone ? const Color(0xFFFFD54F) : AppColors.cyan,
                  isForeground: false,
                ),
                _buildOrbitShard(
                  angle: orbitAngle + (4 * pi / 3),
                  radiusX: orbitRx,
                  radiusY: orbitRy,
                  center: daisCenter,
                  color: AppColors.cosmicCyanLight,
                  isForeground: false,
                ),
              ],

              // 3. 3D Floating Island Platform Artwork (Cutout transparent PNG)
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: filter != null
                      ? ColorFiltered(
                          colorFilter: filter,
                          child: Image.asset(
                            AppAssets.islandPlatform3d,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.asset(
                          AppAssets.islandPlatform3d,
                          fit: BoxFit.contain,
                        ),
                ),
              ),

              // 4. Pulsing Ancient Rune Dais Glow (Beneath level button on stone circle)
              if (widget.isCurrent)
                Positioned(
                  top: (widget.height * 0.10) + floatOffset,
                  child: Container(
                    width: widget.width * 0.44,
                    height: widget.width * 0.44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withValues(
                            alpha: 0.30 + (sin(_floatController.value * 2 * pi).abs() * 0.25),
                          ),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

              // 5. 3D Orbiting Satellites (Near side - IN FRONT of island)
              if (widget.isCurrent || widget.isMilestone) ...[
                _buildOrbitShard(
                  angle: orbitAngle,
                  radiusX: orbitRx,
                  radiusY: orbitRy,
                  center: daisCenter,
                  color: glowColor,
                  isForeground: true,
                ),
                _buildOrbitShard(
                  angle: orbitAngle + (2 * pi / 3),
                  radiusX: orbitRx,
                  radiusY: orbitRy,
                  center: daisCenter,
                  color: widget.isMilestone ? const Color(0xFFFFD54F) : AppColors.cyan,
                  isForeground: true,
                ),
                _buildOrbitShard(
                  angle: orbitAngle + (4 * pi / 3),
                  radiusX: orbitRx,
                  radiusY: orbitRy,
                  center: daisCenter,
                  color: AppColors.cosmicCyanLight,
                  isForeground: true,
                ),
              ],

              // 6. Island Content (3D Tactile Level Node Button / Lock)
              // Centered right on the stone circular dais
              Positioned(
                top: (widget.height * 0.08) + floatOffset,
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// CustomPainter that procedurally renders a 3D floating island with perspective depth,
/// cliff strata, rim lighting, and biome features as a vector fallback.
class FloatingIslandPainter extends CustomPainter {
  final IslandBiome biome;

  FloatingIslandPainter({required this.biome});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Plateau parameters
    final plateauCenterY = h * 0.42;
    final plateauRadiusX = w * 0.44;
    final plateauRadiusY = h * 0.22;
    final bottomTipY = h * 0.94;

    // ──── 1. AMBIENT GLOW / VOID SHADOW ────
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..color = _getBiomeGlowColor().withValues(alpha: 0.28);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, plateauCenterY + 12),
        width: plateauRadiusX * 1.8,
        height: plateauRadiusY * 1.8,
      ),
      glowPaint,
    );

    // ──── 2. 3D UNDERSIDE CLIFF STRATA (Tapers down to rock peak) ────
    final cliffPath = Path();
    cliffPath.moveTo(w * 0.08, plateauCenterY);

    // Left cliff crags
    cliffPath.cubicTo(
      w * 0.14, plateauCenterY + h * 0.24,
      w * 0.26, h * 0.65,
      w * 0.46, bottomTipY,
    );
    // Rocky bottom tip
    cliffPath.lineTo(w * 0.52, bottomTipY + 4);
    // Right cliff crags
    cliffPath.cubicTo(
      w * 0.72, h * 0.68,
      w * 0.86, plateauCenterY + h * 0.22,
      w * 0.92, plateauCenterY,
    );
    cliffPath.close();

    // Cliff base gradient (darker at bottom tip, illuminated near plateau)
    final cliffPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _getCliffLightColor(),
          _getCliffMidColor(),
          _getCliffDarkColor(),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, plateauCenterY, w, h - plateauCenterY));
    canvas.drawPath(cliffPath, cliffPaint);

    // ──── 3. CLIFF SHADING / 3D FACETS (Right-side shadow) ────
    final shadowCragPath = Path();
    shadowCragPath.moveTo(w * 0.50, plateauCenterY);
    shadowCragPath.lineTo(w * 0.52, bottomTipY + 4);
    shadowCragPath.cubicTo(
      w * 0.72, h * 0.68,
      w * 0.86, plateauCenterY + h * 0.22,
      w * 0.92, plateauCenterY,
    );
    shadowCragPath.close();

    final shadowCragPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawPath(shadowCragPath, shadowCragPaint);

    // Strata crack lines
    final strataPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _getStrataLineColor();

    final strataPath1 = Path()
      ..moveTo(w * 0.22, plateauCenterY + 16)
      ..quadraticBezierTo(w * 0.48, plateauCenterY + 28, w * 0.78, plateauCenterY + 18);
    canvas.drawPath(strataPath1, strataPaint);

    final strataPath2 = Path()
      ..moveTo(w * 0.32, plateauCenterY + 36)
      ..quadraticBezierTo(w * 0.50, plateauCenterY + 46, w * 0.68, plateauCenterY + 38);
    canvas.drawPath(strataPath2, strataPaint);

    // ──── 4. BIOME SPECIFIC EMBEDDED DETAILS UNDER CLIFF ────
    _paintBiomeUnderside(canvas, size, plateauCenterY, bottomTipY);

    // ──── 5. TOP PLATEAU SURFACE (3D Island Upper Rim & Deck) ────
    // Plateau rim extruded ledge
    final rimRect = Rect.fromCenter(
      center: Offset(w * 0.5, plateauCenterY + 4),
      width: plateauRadiusX * 2,
      height: plateauRadiusY * 2,
    );
    final rimPaint = Paint()..color = _getPlateauRimColor();
    canvas.drawOval(rimRect, rimPaint);

    // Plateau main deck
    final deckRect = Rect.fromCenter(
      center: Offset(w * 0.5, plateauCenterY),
      width: plateauRadiusX * 2,
      height: plateauRadiusY * 2,
    );
    final deckPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _getPlateauTopColor(),
          _getPlateauBottomColor(),
        ],
      ).createShader(deckRect);
    canvas.drawOval(deckRect, deckPaint);

    // Plateau edge highlight rim (light hitting top perimeter)
    final highlightEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.05),
        ],
      ).createShader(deckRect);
    canvas.drawOval(deckRect, highlightEdgePaint);

    // ──── 6. BIOME SPECIFIC SURFACE ACCENTS ────
    _paintBiomeSurface(canvas, size, deckRect);

    // ──── 7. FLOATING MINI SATELLITE ROCKS / ORBITS ────
    _paintSatelliteRocks(canvas, size, plateauCenterY);
  }

  void _paintBiomeUnderside(Canvas canvas, Size size, double plateauY, double bottomY) {
    final w = size.width;

    switch (biome) {
      case IslandBiome.verdantAstral:
        // Hanging moss roots
        final rootPaint = Paint()
          ..color = const Color(0xFF1B4D28).withValues(alpha: 0.8)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(w * 0.28, plateauY + 8), Offset(w * 0.26, plateauY + 28), rootPaint);
        canvas.drawLine(Offset(w * 0.38, plateauY + 12), Offset(w * 0.39, plateauY + 36), rootPaint);
        canvas.drawLine(Offset(w * 0.68, plateauY + 10), Offset(w * 0.67, plateauY + 30), rootPaint);
        break;

      case IslandBiome.cosmicCrystal:
        // Glowing amethyst crystal shard protruding from rock
        final shardPath = Path()
          ..moveTo(w * 0.30, plateauY + 14)
          ..lineTo(w * 0.25, plateauY + 34)
          ..lineTo(w * 0.33, plateauY + 28)
          ..close();
        final shardPaint = Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFD8B4FE), Color(0xFF7E22CE)],
          ).createShader(shardPath.getBounds());
        canvas.drawPath(shardPath, shardPaint);
        break;

      case IslandBiome.solarMagma:
        // Glowing molten lava stream down the rock
        final lavaPath = Path()
          ..moveTo(w * 0.44, plateauY + 4)
          ..quadraticBezierTo(w * 0.47, plateauY + 28, w * 0.50, bottomY - 6);
        final lavaPaint = Paint()
          ..color = const Color(0xFFFF6D00)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
        canvas.drawPath(lavaPath, lavaPaint);
        break;

      case IslandBiome.aetherCloud:
        // Soft clouds gathering under island base
        final cloudPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset(w * 0.36, bottomY - 10), 14, cloudPaint);
        canvas.drawCircle(Offset(w * 0.54, bottomY - 6), 18, cloudPaint);
        canvas.drawCircle(Offset(w * 0.66, bottomY - 12), 12, cloudPaint);
        break;

      case IslandBiome.cyberStarforge:
        // Cyan energy conduit lines
        final conduitPaint = Paint()
          ..color = AppColors.cyan.withValues(alpha: 0.8)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
        final p = Path()
          ..moveTo(w * 0.50, plateauY + 6)
          ..lineTo(w * 0.50, plateauY + 26)
          ..lineTo(w * 0.62, plateauY + 40);
        canvas.drawPath(p, conduitPaint);
        break;
    }
  }

  void _paintBiomeSurface(Canvas canvas, Size size, Rect deckRect) {
    final w = size.width;
    final cy = deckRect.center.dy;

    switch (biome) {
      case IslandBiome.verdantAstral:
        // Small bright flora specs
        final floraPaint = Paint()..color = const Color(0xFF86EFAC).withValues(alpha: 0.7);
        canvas.drawCircle(Offset(w * 0.22, cy - 4), 1.8, floraPaint);
        canvas.drawCircle(Offset(w * 0.76, cy + 2), 1.5, floraPaint);
        break;

      case IslandBiome.cosmicCrystal:
        // Faceted crystal glints
        final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
        canvas.drawCircle(Offset(w * 0.24, cy - 3), 1.5, glintPaint);
        canvas.drawCircle(Offset(w * 0.74, cy - 2), 2.0, glintPaint);
        break;

      case IslandBiome.solarMagma:
        // Fiery ember specks
        final emberPaint = Paint()..color = const Color(0xFFFFD54F);
        canvas.drawCircle(Offset(w * 0.24, cy - 2), 1.5, emberPaint);
        canvas.drawCircle(Offset(w * 0.76, cy - 4), 1.8, emberPaint);
        break;

      case IslandBiome.aetherCloud:
        // Golden runic arc
        final runePaint = Paint()
          ..color = AppColors.gold.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.5, cy), width: deckRect.width * 0.85, height: deckRect.height * 0.7),
          0,
          pi,
          false,
          runePaint,
        );
        break;

      case IslandBiome.cyberStarforge:
        // Cyber circuit dots
        final nodePaint = Paint()..color = AppColors.cyan;
        canvas.drawCircle(Offset(w * 0.24, cy), 2.0, nodePaint);
        canvas.drawCircle(Offset(w * 0.76, cy), 2.0, nodePaint);
        break;
    }
  }

  void _paintSatelliteRocks(Canvas canvas, Size size, double plateauY) {
    final w = size.width;

    final rockPaint = Paint()..color = _getCliffMidColor();
    final rockLight = Paint()..color = _getPlateauTopColor().withValues(alpha: 0.8);

    // Left mini floating rock
    canvas.drawCircle(Offset(w * 0.07, plateauY + 12), 4.5, rockPaint);
    canvas.drawCircle(Offset(w * 0.07, plateauY + 11), 3.0, rockLight);

    // Right mini floating rock
    canvas.drawCircle(Offset(w * 0.93, plateauY + 18), 3.5, rockPaint);
    canvas.drawCircle(Offset(w * 0.93, plateauY + 17), 2.2, rockLight);
  }

  // ──── COLOR RESOLVERS ────

  Color _getBiomeGlowColor() {
    switch (biome) {
      case IslandBiome.verdantAstral:
        return const Color(0xFF22C55E);
      case IslandBiome.cosmicCrystal:
        return const Color(0xFFA855F7);
      case IslandBiome.solarMagma:
        return const Color(0xFFFF6D00);
      case IslandBiome.aetherCloud:
        return const Color(0xFF38BDF8);
      case IslandBiome.cyberStarforge:
        return AppColors.cyan;
    }
  }

  Color _getCliffLightColor() {
    switch (biome) {
      case IslandBiome.verdantAstral:
        return const Color(0xFF2D3A30);
      case IslandBiome.cosmicCrystal:
        return const Color(0xFF3B2856);
      case IslandBiome.solarMagma:
        return const Color(0xFF3A201A);
      case IslandBiome.aetherCloud:
        return const Color(0xFF283A52);
      case IslandBiome.cyberStarforge:
        return const Color(0xFF1E3246);
    }
  }

  Color _getCliffMidColor() {
    switch (biome) {
      case IslandBiome.verdantAstral:
        return const Color(0xFF1C251F);
      case IslandBiome.cosmicCrystal:
        return const Color(0xFF241838);
      case IslandBiome.solarMagma:
        return const Color(0xFF241410);
      case IslandBiome.aetherCloud:
        return const Color(0xFF1A2638);
      case IslandBiome.cyberStarforge:
        return const Color(0xFF122030);
    }
  }

  Color _getCliffDarkColor() {
    return const Color(0xFF090D18);
  }

  Color _getStrataLineColor() {
    return Colors.black.withValues(alpha: 0.35);
  }

  Color _getPlateauRimColor() {
    switch (biome) {
      case IslandBiome.verdantAstral:
        return const Color(0xFF14532D);
      case IslandBiome.cosmicCrystal:
        return const Color(0xFF581C87);
      case IslandBiome.solarMagma:
        return const Color(0xFF7C2D12);
      case IslandBiome.aetherCloud:
        return const Color(0xFF0369A1);
      case IslandBiome.cyberStarforge:
        return const Color(0xFF0E7490);
    }
  }

  Color _getPlateauTopColor() {
    switch (biome) {
      case IslandBiome.verdantAstral:
        return const Color(0xFF4ADE80);
      case IslandBiome.cosmicCrystal:
        return const Color(0xFFC084FC);
      case IslandBiome.solarMagma:
        return const Color(0xFFFB923C);
      case IslandBiome.aetherCloud:
        return const Color(0xFF7DD3FC);
      case IslandBiome.cyberStarforge:
        return const Color(0xFF22D3EE);
    }
  }

  Color _getPlateauBottomColor() {
    switch (biome) {
      case IslandBiome.verdantAstral:
        return const Color(0xFF16A34A);
      case IslandBiome.cosmicCrystal:
        return const Color(0xFF9333EA);
      case IslandBiome.solarMagma:
        return const Color(0xFFEA580C);
      case IslandBiome.aetherCloud:
        return const Color(0xFF0284C7);
      case IslandBiome.cyberStarforge:
        return const Color(0xFF0891B2);
    }
  }

  @override
  bool shouldRepaint(covariant FloatingIslandPainter oldDelegate) {
    return oldDelegate.biome != biome;
  }
}
