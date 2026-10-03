import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/solar_realm_model.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';
import 'floating_island_painter.dart';

/// 3D Procedural Citadel Castle with twin watchtowers, crenellated ramparts,
/// glowing arched portal, and animated fluttering royal pennants
class CitadelCastleStructure extends StatefulWidget {
  final IslandBiome biome;
  final double width;
  final double height;

  const CitadelCastleStructure({
    super.key,
    required this.biome,
    this.width = 110,
    this.height = 70,
  });

  @override
  State<CitadelCastleStructure> createState() => _CitadelCastleStructureState();
}

class _CitadelCastleStructureState extends State<CitadelCastleStructure>
    with SingleTickerProviderStateMixin {
  late AnimationController _flagController;

  @override
  void initState() {
    super.initState();
    _flagController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flagController,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _CitadelCastlePainter(
            biome: widget.biome,
            flagWave: _flagController.value,
          ),
        );
      },
    );
  }
}

class _CitadelCastlePainter extends CustomPainter {
  final IslandBiome biome;
  final double flagWave;

  _CitadelCastlePainter({
    required this.biome,
    required this.flagWave,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Palette per biome
    Color wallBase;
    Color wallShade;
    Color roofBase;
    Color roofLight;
    Color gateGlow;
    Color flagColor;

    switch (biome) {
      case IslandBiome.verdantAstral:
        wallBase = const Color(0xFF334155);
        wallShade = const Color(0xFF1E293B);
        roofBase = const Color(0xFF047857);
        roofLight = const Color(0xFF10B981);
        gateGlow = const Color(0xFF34D399);
        flagColor = const Color(0xFFFBBF24);
        break;
      case IslandBiome.cosmicCrystal:
        wallBase = const Color(0xFF4C1D95);
        wallShade = const Color(0xFF2E1065);
        roofBase = const Color(0xFF7C3AED);
        roofLight = const Color(0xFFA855F7);
        gateGlow = const Color(0xFFE879F9);
        flagColor = const Color(0xFF38BDF8);
        break;
      case IslandBiome.solarMagma:
        wallBase = const Color(0xFF27272A);
        wallShade = const Color(0xFF18181B);
        roofBase = const Color(0xFFB45309);
        roofLight = const Color(0xFFFF7A00);
        gateGlow = const Color(0xFFFF3D00);
        flagColor = const Color(0xFFFACC15);
        break;
      case IslandBiome.aetherCloud:
        wallBase = const Color(0xFFE2E8F0);
        wallShade = const Color(0xFF94A3B8);
        roofBase = const Color(0xFF0284C7);
        roofLight = const Color(0xFF38BDF8);
        gateGlow = const Color(0xFFFDE047);
        flagColor = const Color(0xFF38BDF8);
        break;
      case IslandBiome.cyberStarforge:
        wallBase = const Color(0xFF0F172A);
        wallShade = const Color(0xFF020617);
        roofBase = const Color(0xFF007799);
        roofLight = AppColors.cyan;
        gateGlow = const Color(0xFF00E5FF);
        flagColor = const Color(0xFFE040FB);
        break;
    }

    final wallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [wallBase, wallShade],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // 1. Central Keep Body
    final keepWidth = w * 0.44;
    final keepHeight = h * 0.52;
    final keepLeft = (w - keepWidth) / 2;
    final keepTop = h - keepHeight;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(keepLeft, keepTop, keepWidth, keepHeight),
        const Radius.circular(3),
      ),
      wallPaint,
    );

    // Crenellations (castellated teeth on central keep)
    final toothCount = 4;
    final toothW = keepWidth / (toothCount * 2 - 1);
    for (int t = 0; t < toothCount; t++) {
      final tx = keepLeft + (t * 2 * toothW);
      canvas.drawRect(Rect.fromLTWH(tx, keepTop - 4, toothW, 5), wallPaint);
    }

    // 2. Twin Flank Watchtowers (Left & Right)
    final towerWidth = w * 0.22;
    final towerHeight = h * 0.70;
    final towerTop = h - towerHeight;

    void drawTower(double tx) {
      final tRect = Rect.fromLTWH(tx, towerTop, towerWidth, towerHeight);
      final towerShader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [wallBase.withValues(alpha: 0.9), wallShade],
      ).createShader(tRect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(tRect, const Radius.circular(3)),
        Paint()..shader = towerShader,
      );

      // Tower conical roof
      final roofPath = Path()
        ..moveTo(tx - 2, towerTop)
        ..lineTo(tx + towerWidth / 2, towerTop - 16)
        ..lineTo(tx + towerWidth + 2, towerTop)
        ..close();

      final roofShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [roofLight, roofBase],
      ).createShader(Rect.fromLTWH(tx - 2, towerTop - 16, towerWidth + 4, 16));

      canvas.drawPath(roofPath, Paint()..shader = roofShader);

      // Flagpole and waving pennant on top of roof
      final poleX = tx + towerWidth / 2;
      final poleTop = towerTop - 25;
      canvas.drawLine(
        Offset(poleX, towerTop - 14),
        Offset(poleX, poleTop),
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..strokeWidth = 1.2,
      );

      // Waving pennant flag
      final waveOffset = sin(flagWave * pi * 2) * 2.0;
      final flagPath = Path()
        ..moveTo(poleX, poleTop)
        ..lineTo(poleX + 10 + waveOffset, poleTop + 3)
        ..lineTo(poleX, poleTop + 6)
        ..close();
      canvas.drawPath(flagPath, Paint()..color = flagColor);
    }

    drawTower(keepLeft - towerWidth + 4);
    drawTower(keepLeft + keepWidth - 4);

    // 3. Glowing Arched Portcullis Portal Gate
    final gateWidth = keepWidth * 0.46;
    final gateHeight = keepHeight * 0.58;
    final gateX = (w - gateWidth) / 2;
    final gateY = h - gateHeight;

    final gatePath = Path()
      ..moveTo(gateX, h)
      ..lineTo(gateX, gateY + gateWidth / 2)
      ..arcToPoint(
        Offset(gateX + gateWidth, gateY + gateWidth / 2),
        radius: Radius.circular(gateWidth / 2),
      )
      ..lineTo(gateX + gateWidth, h)
      ..close();

    // Portal deep dark cavity
    canvas.drawPath(gatePath, Paint()..color = const Color(0xFF020617));

    // Radiant inner glow
    final glowPaint = Paint()
      ..color = gateGlow.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(gatePath, glowPaint);

    // Inner bright core
    canvas.drawCircle(Offset(w / 2, gateY + gateHeight * 0.5), gateWidth * 0.25, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CitadelCastlePainter oldDelegate) {
    return oldDelegate.flagWave != flagWave || oldDelegate.biome != biome;
  }
}

/// Interactive Living Alien Companion Widget
/// Has idle floating, breathing bounce, blinking alien eyes, and tap interaction!
class AlienCompanionWidget extends StatefulWidget {
  final AlienCompanion alien;
  final double size;
  final bool bubbleOnLeft;

  const AlienCompanionWidget({
    super.key,
    required this.alien,
    this.size = 54,
    this.bubbleOnLeft = false,
  });

  @override
  State<AlienCompanionWidget> createState() => _AlienCompanionWidgetState();
}

class _AlienCompanionWidgetState extends State<AlienCompanionWidget>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _bubblePopController;
  Timer? _greetingTimer;
  bool _showGreeting = false;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _bubblePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _idleController.dispose();
    _bubblePopController.dispose();
    super.dispose();
  }

  void _onAlienTap() {
    HapticService.lightTap();
    AudioService().playPowerUp();

    setState(() {
      _showGreeting = true;
    });

    _bubblePopController.forward(from: 0.0);

    // Keep speech bubble visible for 8 seconds so the player can comfortably read it
    _greetingTimer?.cancel();
    _greetingTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        _bubblePopController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showGreeting = false;
            });
          }
        });
      }
    });
  }

  void _dismissGreeting() {
    HapticService.lightTap();
    _greetingTimer?.cancel();
    _bubblePopController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showGreeting = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onAlienTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _idleController,
        builder: (context, _) {
          final t = _idleController.value;
          final hoverOffset = sin(t * pi) * 4.0;
          final squashX = 1.0 + (sin(t * pi * 2) * 0.05);
          final squashY = 1.0 - (sin(t * pi * 2) * 0.05);

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. Alien Ground Shadow
              Positioned(
                bottom: 2,
                child: Container(
                  width: widget.size * 0.55 * (1.0 - hoverOffset * 0.05),
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ),

              // 2. Animated Floating Alien Creature
              Transform.translate(
                offset: Offset(0, -hoverOffset),
                child: Transform.scale(
                  scaleX: squashX,
                  scaleY: squashY,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [widget.alien.secondaryColor, widget.alien.primaryColor],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.alien.glowColor.withValues(alpha: 0.65),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cute Alien Eyes
                        Positioned(
                          top: widget.size * 0.28,
                          left: widget.size * 0.22,
                          child: _buildAlienEye(t),
                        ),
                        Positioned(
                          top: widget.size * 0.28,
                          right: widget.size * 0.22,
                          child: _buildAlienEye(t),
                        ),

                        // Alien Icon / Characteristic Emblem on lower chest
                        Positioned(
                          bottom: widget.size * 0.12,
                          child: Icon(
                            widget.alien.icon,
                            size: widget.size * 0.32,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Speech Bubble Greeting (Tapped dialogue)
              // Anchored inward towards screen center so it NEVER cuts off on screen edges
              if (_showGreeting)
                Positioned(
                  bottom: widget.size + 8,
                  left: widget.bubbleOnLeft ? null : -6,
                  right: widget.bubbleOnLeft ? -6 : null,
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _bubblePopController,
                      curve: Curves.easeOutBack,
                    ),
                    alignment: widget.bubbleOnLeft
                        ? Alignment.bottomRight
                        : Alignment.bottomLeft,
                    child: GestureDetector(
                      onTap: _dismissGreeting,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        constraints: const BoxConstraints(maxWidth: 190, minWidth: 125),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.alien.glowColor,
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.alien.glowColor.withValues(alpha: 0.35),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Name + Close Button
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.alien.icon,
                                      size: 11,
                                      color: widget.alien.glowColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.alien.name.toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        color: widget.alien.glowColor,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Dialogue Greeting
                            Text(
                              widget.alien.greeting,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlienEye(double t) {
    // Periodic blink (approx 5% of cycle)
    final isBlinking = t > 0.92;
    if (isBlinking) {
      return Container(
        width: 7,
        height: 2,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(1),
        ),
      );
    }

    return Container(
      width: 7,
      height: 9,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        shape: BoxShape.circle,
      ),
      child: Align(
        alignment: const Alignment(-0.3, -0.3),
        child: Container(
          width: 2.5,
          height: 2.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Towering Crystalline Obelisks protruding upward from the island
class CrystalSpireStructure extends StatelessWidget {
  final IslandBiome biome;
  final double width;
  final double height;

  const CrystalSpireStructure({
    super.key,
    required this.biome,
    this.width = 70,
    this.height = 55,
  });

  @override
  Widget build(BuildContext context) {
    Color crystalTop;
    Color crystalBottom;
    Color crystalGlow;

    switch (biome) {
      case IslandBiome.verdantAstral:
        crystalTop = const Color(0xFF6EE7B7);
        crystalBottom = const Color(0xFF059669);
        crystalGlow = const Color(0xFF10B981);
        break;
      case IslandBiome.cosmicCrystal:
        crystalTop = const Color(0xFFF0ABFC);
        crystalBottom = const Color(0xFF7E22CE);
        crystalGlow = const Color(0xFFA855F7);
        break;
      case IslandBiome.solarMagma:
        crystalTop = const Color(0xFFFDE047);
        crystalBottom = const Color(0xFFEA580C);
        crystalGlow = const Color(0xFFFF6D00);
        break;
      case IslandBiome.aetherCloud:
        crystalTop = const Color(0xFFBAE6FD);
        crystalBottom = const Color(0xFF0284C7);
        crystalGlow = const Color(0xFF38BDF8);
        break;
      case IslandBiome.cyberStarforge:
        crystalTop = const Color(0xFFE0F2FE);
        crystalBottom = const Color(0xFF0891B2);
        crystalGlow = AppColors.cyan;
        break;
    }

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CrystalSpirePainter(
          topColor: crystalTop,
          bottomColor: crystalBottom,
          glowColor: crystalGlow,
        ),
      ),
    );
  }
}

class _CrystalSpirePainter extends CustomPainter {
  final Color topColor;
  final Color bottomColor;
  final Color glowColor;

  _CrystalSpirePainter({
    required this.topColor,
    required this.bottomColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void drawSpire(double cx, double width, double height, double angleOffset) {
      final top = h - height;
      final path = Path()
        ..moveTo(cx, top)
        ..lineTo(cx + width / 2, top + height * 0.4)
        ..lineTo(cx + width / 2, h)
        ..lineTo(cx - width / 2, h)
        ..lineTo(cx - width / 2, top + height * 0.4)
        ..close();

      // Glow behind
      canvas.drawPath(
        path,
        Paint()
          ..color = glowColor.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Crystal gradient
      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, bottomColor],
      ).createShader(Rect.fromLTWH(cx - width / 2, top, width, height));

      canvas.drawPath(path, Paint()..shader = shader);

      // Specular ridge line down the center
      canvas.drawLine(
        Offset(cx, top),
        Offset(cx, h),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 1.2,
      );
    }

    // Three clustered crystal shards of varying heights
    drawSpire(w * 0.32, 12, h * 0.70, -0.1);
    drawSpire(w * 0.68, 14, h * 0.85, 0.1);
    drawSpire(w * 0.50, 18, h * 1.00, 0.0);
  }

  @override
  bool shouldRepaint(covariant _CrystalSpirePainter oldDelegate) {
    return oldDelegate.glowColor != glowColor;
  }
}

/// Cosmic Ancient Stargate Gateway Ring with rotating celestial runes
class RealmGatewayStructure extends StatefulWidget {
  final IslandBiome biome;
  final double size;

  const RealmGatewayStructure({
    super.key,
    required this.biome,
    this.size = 65,
  });

  @override
  State<RealmGatewayStructure> createState() => _RealmGatewayStructureState();
}

class _RealmGatewayStructureState extends State<RealmGatewayStructure>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color portalColor;
    switch (widget.biome) {
      case IslandBiome.verdantAstral:
        portalColor = const Color(0xFF10B981);
        break;
      case IslandBiome.cosmicCrystal:
        portalColor = const Color(0xFFA855F7);
        break;
      case IslandBiome.solarMagma:
        portalColor = const Color(0xFFFF5722);
        break;
      case IslandBiome.aetherCloud:
        portalColor = const Color(0xFF38BDF8);
        break;
      case IslandBiome.cyberStarforge:
        portalColor = AppColors.cyan;
        break;
    }

    return AnimatedBuilder(
      animation: _spinController,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size * 0.7,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Spinning runic Stargate arch
              Transform.rotate(
                angle: _spinController.value * 2 * pi,
                child: Container(
                  width: widget.size * 0.85,
                  height: widget.size * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: portalColor.withValues(alpha: 0.6),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: portalColor.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Swirling Vortex Core
              Container(
                width: widget.size * 0.45,
                height: widget.size * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      portalColor.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
