import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../models/player_state.dart';
import '../../services/haptic_service.dart';
import '../particles/particles.dart';

/// Seamless 3D World Diorama for BLINK
/// Blends directly into the cosmic background with ZERO square boundaries:
/// - Radial alpha mask / shader feathering: outer perimeter of island artwork dissolves into dark space
/// - Volumetric space fog drifting under the floating island base
/// - Radial cosmic god rays radiating from behind the sanctuary
/// - Standalone 3D Nova companion floating freely above sanctuary (no clipped avatar badge)
/// - Interactive touch 3D perspective tilt (Matrix4 with perspective projection)
/// - Orbiting 3D crystal shards passing in front and behind
class World3dDiorama extends ConsumerStatefulWidget {
  final PlayerState player;
  final double size;

  const World3dDiorama({
    super.key,
    required this.player,
    this.size = 300.0,
  });

  @override
  ConsumerState<World3dDiorama> createState() => _World3dDioramaState();
}

class _World3dDioramaState extends ConsumerState<World3dDiorama>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _springController;
  late Animation<double> _springX;
  late Animation<double> _springY;
  late AnimationController _novaSpinController;

  double _tiltX = 0.0;
  double _tiltY = 0.0;
  double _dragStartX = 0.0;
  double _dragStartY = 0.0;
  bool _isDragging = false;
  bool _showNovaSparkles = false;

  @override
  void initState() {
    super.initState();

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _novaSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void dispose() {
    _idleController.dispose();
    _springController.dispose();
    _novaSpinController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _springController.stop();
    _isDragging = true;
    _dragStartX = _tiltX;
    _dragStartY = _tiltY;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      const sensitivity = 0.007;
      _tiltX = (_dragStartX + details.localPosition.dx * sensitivity).clamp(-0.40, 0.40);
      _tiltY = (_dragStartY - details.localPosition.dy * sensitivity).clamp(-0.30, 0.30);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    _springX = Tween<double>(begin: _tiltX, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );
    _springY = Tween<double>(begin: _tiltY, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );

    _springController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _tiltX = 0.0;
          _tiltY = 0.0;
        });
      }
    });
  }

  void _handleNovaTap() {
    if (_novaSpinController.isAnimating) return;

    triggerHaptic(ref, HapticService.mediumTap);
    setState(() => _showNovaSparkles = true);

    _novaSpinController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _showNovaSparkles = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return AnimatedBuilder(
      animation: Listenable.merge([_idleController, _springController, _novaSpinController]),
      builder: (context, _) {
        final t = _idleController.value;

        final idlePitch = sin(t * 2 * pi) * 0.06;
        final idleYaw = cos(t * 2 * pi) * 0.07;

        final currentTiltX = _isDragging
            ? _tiltX
            : (_springController.isAnimating ? _springX.value : _tiltX) + idleYaw;
        final currentTiltY = _isDragging
            ? _tiltY
            : (_springController.isAnimating ? _springY.value : _tiltY) + idlePitch;

        // 3D Perspective Matrix
        final worldMatrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0018)
          ..rotateX(currentTiltY)
          ..rotateY(currentTiltX);

        final islandFloatY = sin(t * 2 * pi) * 8.0;

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // ── LAYER 0: VOLUMETRIC GOD RAYS (Z = -60) ──
                Transform.translate(
                  offset: Offset(-currentTiltX * 18, -currentTiltY * 15),
                  child: CustomPaint(
                    painter: _CosmicGodRaysPainter(t),
                    size: Size(size * 1.15, size * 1.15),
                  ),
                ),

                // ── LAYER 1: DEEP ATMOSPHERIC NEBULA GLOW (Z = -50) ──
                Transform.translate(
                  offset: Offset(-currentTiltX * 28, -currentTiltY * 22),
                  child: Container(
                    width: size * 1.05,
                    height: size * 1.05,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.38),
                          AppColors.cyan.withValues(alpha: 0.16),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── LAYER 2: DYNAMIC 3D CONTACT SHADOW (Z = -20) ──
                Positioned(
                  bottom: 12,
                  child: Transform.translate(
                    offset: Offset(-currentTiltX * 40, currentTiltY * 30 - islandFloatY * 0.35),
                    child: Container(
                      width: size * 0.72,
                      height: size * 0.24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.elliptical(size * 0.36, size * 0.12)),
                        gradient: RadialGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.75),
                            AppColors.primaryDark.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── LAYER 3: VOLUMETRIC UNDER-ISLAND FOG (Z = -10) ──
                Positioned(
                  bottom: 24,
                  child: Transform.translate(
                    offset: Offset(-currentTiltX * 25, currentTiltY * 18 + islandFloatY * 0.4),
                    child: CustomPaint(
                      painter: _VolumetricFogPainter(t),
                      size: Size(size * 0.85, size * 0.30),
                    ),
                  ),
                ),

                // ── LAYER 4: ORBITING CRYSTALS (Behind Island, Z < 0) ──
                ..._buildOrbitingCrystals(size, t, currentTiltX, currentTiltY, isBehind: true),

                // ── LAYER 5: 3D FLOATING ISLAND (Z = 0) with SEAMLESS RADIAL FEATHERING ──
                Transform(
                  alignment: Alignment.center,
                  transform: worldMatrix,
                  child: Transform.translate(
                    offset: Offset(0, islandFloatY),
                    child: SizedBox(
                      width: size * 0.92,
                      height: size * 0.92,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Seamlessly feathered island artwork (NO square edges!)
                          ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return RadialGradient(
                                center: Alignment.center,
                                radius: 0.70,
                                colors: const [
                                  Colors.white,
                                  Colors.white,
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.70, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: Image.asset(
                              AppAssets.floatingIsland,
                              width: size * 0.92,
                              height: size * 0.92,
                              fit: BoxFit.contain,
                            ),
                          ),

                          // Dynamic 3D specular light sheen shifting with tilt
                          Positioned.fill(
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return RadialGradient(
                                  center: Alignment.center,
                                  radius: 0.68,
                                  colors: const [Colors.white, Colors.transparent],
                                  stops: const [0.55, 1.0],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.dstIn,
                              child: CustomPaint(
                                painter: _SpecularLightSheenPainter(
                                  tiltX: currentTiltX,
                                  tiltY: currentTiltY,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── LAYER 6: ORBITING CRYSTALS (In Front of Island, Z > 0) ──
                ..._buildOrbitingCrystals(size, t, currentTiltX, currentTiltY, isBehind: false),

                // ── LAYER 7: STANDALONE 3D NOVA COMPANION (Z = +45, NO circular badge!) ──
                Positioned(
                  top: size * 0.04 + islandFloatY * 1.25 + sin(t * 4 * pi) * 3.5,
                  child: Transform.translate(
                    offset: Offset(currentTiltX * 50, -currentTiltY * 38),
                    child: _buildStandaloneNova(size),
                  ),
                ),

                // ── LAYER 8: FOREGROUND COSMIC STARDUST (Z = +70) ──
                IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(currentTiltX * 65, currentTiltY * 55),
                    child: CustomPaint(
                      painter: _ForegroundStardustPainter(t),
                      size: Size(size * 1.05, size * 1.05),
                    ),
                  ),
                ),

                // Nova tap sparkles
                if (_showNovaSparkles)
                  Positioned(
                    top: size * 0.02,
                    child: SparkBurst(
                      color: AppColors.cyan,
                      size: 80,
                      onComplete: () => setState(() => _showNovaSparkles = false),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStandaloneNova(double size) {
    final spinAngle = _novaSpinController.value * 2 * pi;

    return GestureDetector(
      onTap: _handleNovaTap,
      behavior: HitTestBehavior.opaque,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateY(spinAngle),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Ambient luminous aura instead of an artificial dark badge
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.75),
                blurRadius: 22,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 36,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Image.asset(
            _novaSpinController.isAnimating ? AppAssets.novaHappy : AppAssets.novaIdle,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOrbitingCrystals(
    double size,
    double t,
    double tiltX,
    double tiltY, {
    required bool isBehind,
  }) {
    const crystalCount = 5;
    final widgets = <Widget>[];

    for (int i = 0; i < crystalCount; i++) {
      final orbitAngle = (t * 2 * pi) + (i * 2 * pi / crystalCount);
      final sinA = sin(orbitAngle);
      final cosA = cos(orbitAngle);

      final isBack = sinA < 0;
      if (isBack != isBehind) continue;

      final radiusX = size * 0.46;
      final radiusY = size * 0.18;
      final posX = cosA * radiusX + (tiltX * 32);
      final posY = sinA * radiusY + (tiltY * 22) + 20;

      final depthScale = 0.75 + (sinA + 1.0) * 0.28;
      final depthOpacity = (0.55 + (sinA + 1.0) * 0.24).clamp(0.25, 1.0);

      widgets.add(
        Transform.translate(
          offset: Offset(posX, posY),
          child: Transform.scale(
            scale: depthScale,
            child: Opacity(
              opacity: depthOpacity,
              child: _buildCrystalShard(i),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildCrystalShard(int index) {
    final colors = [
      AppColors.cyan,
      AppColors.primaryLight,
      AppColors.gemPurple,
      AppColors.mint,
      AppColors.gold,
    ];
    final color = colors[index % colors.length];

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.85),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _MiniCrystalPainter(color),
      ),
    );
  }
}

/// Volumetric Cosmic God Rays radiating from behind the sanctuary
class _CosmicGodRaysPainter extends CustomPainter {
  final double time;
  _CosmicGodRaysPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.42);
    const rayCount = 8;
    final maxRadius = size.width * 0.65;

    for (int i = 0; i < rayCount; i++) {
      final baseAngle = (i * 2 * pi / rayCount) + (time * 0.2);
      final rayWidth = 0.14 + 0.04 * sin(time * 2 * pi + i);
      final alpha = (0.10 + 0.06 * sin(time * 3 * pi + i * 1.5)).clamp(0.0, 1.0);

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + cos(baseAngle - rayWidth) * maxRadius,
          center.dy + sin(baseAngle - rayWidth) * maxRadius,
        )
        ..lineTo(
          center.dx + cos(baseAngle + rayWidth) * maxRadius,
          center.dy + sin(baseAngle + rayWidth) * maxRadius,
        )
        ..close();

      final rayPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.cyan.withValues(alpha: alpha * 0.8),
            AppColors.primary.withValues(alpha: alpha * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

      canvas.drawPath(path, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicGodRaysPainter oldDelegate) => true;
}

/// Volumetric Fog puff painter drifting beneath the island rock
class _VolumetricFogPainter extends CustomPainter {
  final double time;
  _VolumetricFogPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      final offsetX = sin(time * 2 * pi * 0.4 + i * 2) * 16.0;
      final offsetY = cos(time * 2 * pi * 0.3 + i * 1.5) * 4.0;
      final fogCenter = center + Offset(offsetX + (i - 1) * 35, offsetY);
      final fogRadius = size.width * (0.28 + i * 0.05);

      final fogPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.cyan.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: fogCenter, radius: fogRadius));

      canvas.drawCircle(fogCenter, fogRadius, fogPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VolumetricFogPainter oldDelegate) => true;
}

/// Dynamic 3D Specular Light Sheen Painter
class _SpecularLightSheenPainter extends CustomPainter {
  final double tiltX;
  final double tiltY;

  _SpecularLightSheenPainter({required this.tiltX, required this.tiltY});

  @override
  void paint(Canvas canvas, Size size) {
    final sheenX = size.width * (0.4 + tiltX * 1.4);
    final sheenY = size.height * (0.35 - tiltY * 1.4);
    final sheenRadius = size.width * 0.5;

    final sheenPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (sheenX / size.width) * 2 - 1,
          (sheenY / size.height) * 2 - 1,
        ),
        radius: 0.6,
        colors: [
          Colors.white.withValues(alpha: 0.32),
          AppColors.cyan.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(sheenX, sheenY), radius: sheenRadius))
      ..blendMode = BlendMode.screen;

    canvas.drawRect(Offset.zero & size, sheenPaint);
  }

  @override
  bool shouldRepaint(covariant _SpecularLightSheenPainter oldDelegate) {
    return oldDelegate.tiltX != tiltX || oldDelegate.tiltY != tiltY;
  }
}

/// Mini 2.5D crystal diamond shard
class _MiniCrystalPainter extends CustomPainter {
  final Color color;
  _MiniCrystalPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;

    final litPath = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx - r * 0.7, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..close();
    canvas.drawPath(litPath, Paint()..color = Colors.white.withValues(alpha: 0.95));

    final shadowPath = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.7, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..close();
    canvas.drawPath(shadowPath, Paint()..color = color);

    canvas.drawLine(
      Offset(center.dx, center.dy - r),
      Offset(center.dx, center.dy + r),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Foreground stardust
class _ForegroundStardustPainter extends CustomPainter {
  final double time;
  _ForegroundStardustPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(88);
    const dustCount = 8;

    for (int i = 0; i < dustCount; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final radius = 1.2 + rng.nextDouble() * 2.0;

      final floatY = baseY + sin(time * 2 * pi * (0.5 + i * 0.1) + i) * 6.0;
      final alpha = ((sin(time * 2 * pi * 0.8 + i) + 1) / 2 * 0.75 + 0.25).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = [AppColors.cyan, Colors.white, AppColors.gold][i % 3].withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(Offset(baseX, floatY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ForegroundStardustPainter oldDelegate) => true;
}
