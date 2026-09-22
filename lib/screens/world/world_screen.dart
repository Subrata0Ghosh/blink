import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/navigation/candy_top_bar.dart';
import '../../widgets/navigation/game_bottom_nav.dart';
import '../../widgets/particles/particles.dart';
import '../../widgets/world/floating_island_painter.dart';

/// Cosmic Floating Islands Level Progression Map for BLINK
/// Features:
/// - Seamless cosmic deep space with stardust (no harsh flat banding)
/// - 5 Biomes of 3D Floating Islands along the journey
/// - Level nodes rendered as authentic 3D tactile buttons with push-down tapping physics
/// - Current active level with pulsating 3D avatar indicator
/// - Interactive Level Details popup with Image 2 Close button and 3D Play button
class WorldScreen extends ConsumerStatefulWidget {
  const WorldScreen({super.key});

  @override
  ConsumerState<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends ConsumerState<WorldScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 1400);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scroll near the player's active level after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final player = ref.read(gameStateProvider);
        final levelIndex = (player.level - 1).clamp(0, 19);
        final waypoints = _getWaypoints(MediaQuery.of(context).size.width);
        final levelY = waypoints[levelIndex].dy;
        final viewportHeight = _scrollController.position.viewportDimension;
        final targetScroll = (levelY - viewportHeight / 2).clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.jumpTo(targetScroll);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  IslandBiome _getBiomeForLevel(int level) {
    if (level <= 4) return IslandBiome.verdantAstral;
    if (level <= 8) return IslandBiome.cosmicCrystal;
    if (level <= 12) return IslandBiome.solarMagma;
    if (level <= 16) return IslandBiome.aetherCloud;
    return IslandBiome.cyberStarforge;
  }

  void _showLevelDialog(int levelNum, int stars, bool isUnlocked) {
    triggerHaptic(ref, HapticService.mediumTap);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Modal Card
              Container(
                margin: const EdgeInsets.only(top: 16, right: 8),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF2E3858), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.65),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.nebulaPurpleLight, AppColors.nebulaPurpleDark],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.nebulaPurpleRim,
                            offset: const Offset(0, 3),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'LEVEL $levelNum',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: AppColors.nebulaPurpleRim,
                              offset: const Offset(0, 1.5),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Star Rating Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final isEarned = i < stars;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            isEarned ? Icons.star_rounded : Icons.star_border_rounded,
                            color: isEarned ? AppColors.gold : AppColors.textMuted.withValues(alpha: 0.5),
                            size: 38,
                            shadows: isEarned
                                ? [
                                    BoxShadow(
                                      color: AppColors.gold.withValues(alpha: 0.6),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // Target Objective Info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.track_changes_rounded, color: AppColors.cyan, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Spot all shifts & changes',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Play Button (3D Cosmic Cyan)
                    if (isUnlocked)
                      TactileButton.cosmic(
                        label: 'PLAY',
                        height: 58,
                        fontSize: 22,
                        width: double.infinity,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/play');
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Complete previous level',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // ──── 3D CROSS / CLOSE BUTTON (Matching Image 2) ────
              Positioned(
                top: 0,
                right: 0,
                child: TactileButton.close(
                  size: 42,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);
    final currentLevel = player.level.clamp(1, 20);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ──── 1. 3D COSMIC TOP BAR ────
          const CandyTopBar(),

          // ──── 2. 3D FLOATING ISLANDS MAP ────
          Expanded(
            child: Stack(
              children: [
                // Deep space gradient (no flat bands, smooth cosmic aura)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.0, -0.2),
                        radius: 1.5,
                        colors: [
                          Color(0xFF141936),
                          Color(0xFF0C1022),
                          Color(0xFF070A14),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),

                // Floating cosmic particle field
                const Positioned.fill(
                  child: StarField(starCount: 40),
                ),

                // Scrollable floating islands map
                Positioned.fill(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: double.infinity,
                      height: 2050,
                      child: CustomPaint(
                        painter: _ConstellationPathPainter(
                          waypoints: _getWaypoints(MediaQuery.of(context).size.width),
                          activeLevel: currentLevel,
                        ),
                        child: Stack(
                          children: _buildLevelNodes(currentLevel, MediaQuery.of(context).size.width),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ──── 3. 3D COSMIC BOTTOM NAVIGATION ────
          const GameBottomNav(currentIndex: 0),
        ],
      ),
    );
  }

  List<Offset> _getWaypoints(double screenWidth) {
    // S-curve journey waypoints
    return [
      Offset(screenWidth * 0.50, 1920),  // Level 1 (bottom)
      Offset(screenWidth * 0.72, 1830),
      Offset(screenWidth * 0.78, 1730),
      Offset(screenWidth * 0.65, 1630),
      Offset(screenWidth * 0.45, 1540),
      Offset(screenWidth * 0.28, 1450),
      Offset(screenWidth * 0.22, 1350),
      Offset(screenWidth * 0.35, 1250),
      Offset(screenWidth * 0.52, 1160),
      Offset(screenWidth * 0.70, 1070),
      Offset(screenWidth * 0.75, 970),
      Offset(screenWidth * 0.62, 870),
      Offset(screenWidth * 0.45, 780),
      Offset(screenWidth * 0.30, 690),
      Offset(screenWidth * 0.22, 590),
      Offset(screenWidth * 0.35, 490),
      Offset(screenWidth * 0.52, 400),
      Offset(screenWidth * 0.70, 310),
      Offset(screenWidth * 0.58, 210),
      Offset(screenWidth * 0.40, 120),  // Level 20 (top)
    ];
  }

  List<Widget> _buildLevelNodes(int activeLevel, double screenWidth) {
    final List<Widget> nodes = [];
    final waypoints = _getWaypoints(screenWidth);

    for (int i = 0; i < waypoints.length; i++) {
      final levelNum = i + 1;
      final wp = waypoints[i];
      final isCurrent = levelNum == activeLevel;
      final isUnlocked = levelNum <= activeLevel;
      final stars = isUnlocked ? (levelNum < activeLevel ? 3 : 2) : 0;
      final biome = _getBiomeForLevel(levelNum);

      const islandWidth = 146.0;
      const islandHeight = 120.0;

      nodes.add(
        Positioned(
          top: wp.dy - (islandHeight * 0.45),
          left: wp.dx - (islandWidth * 0.5),
          child: FloatingIslandWidget(
            biome: biome,
            width: islandWidth,
            height: islandHeight,
            child: _TactileLevelNode(
              levelNum: levelNum,
              stars: stars,
              isCurrent: isCurrent,
              isUnlocked: isUnlocked,
              pulseAnimation: _pulseAnimation,
              onTap: () => _showLevelDialog(levelNum, stars, isUnlocked),
            ),
          ),
        ),
      );
    }

    return nodes;
  }
}

/// 3D Tactile Level Node Button with physical press-down depression physics,
/// specular glass highlight arc, and 3D extruded rim
class _TactileLevelNode extends StatefulWidget {
  final int levelNum;
  final int stars;
  final bool isCurrent;
  final bool isUnlocked;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  const _TactileLevelNode({
    required this.levelNum,
    required this.stars,
    required this.isCurrent,
    required this.isUnlocked,
    required this.pulseAnimation,
    required this.onTap,
  });

  @override
  State<_TactileLevelNode> createState() => _TactileLevelNodeState();
}

class _TactileLevelNodeState extends State<_TactileLevelNode> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _pressController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    const size = 52.0;
    const rimHeight = 5.0;

    Color rimColor;
    Color faceTop;
    Color faceBottom;
    Color glowColor;

    if (widget.isCurrent) {
      rimColor = AppColors.cosmicCyanRim;
      faceTop = AppColors.cosmicCyanLight;
      faceBottom = AppColors.cosmicCyanDark;
      glowColor = AppColors.cyan;
    } else if (widget.isUnlocked) {
      rimColor = AppColors.nebulaPurpleRim;
      faceTop = AppColors.nebulaPurpleLight;
      faceBottom = AppColors.nebulaPurpleDark;
      glowColor = AppColors.primary;
    } else {
      rimColor = const Color(0xFF090D18);
      faceTop = const Color(0xFF262E48);
      faceBottom = const Color(0xFF131828);
      glowColor = Colors.transparent;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current Player floating indicator
          if (widget.isCurrent) ...[
            AnimatedBuilder(
              animation: widget.pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.pulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.cosmicCyanLight, AppColors.cosmicCyanDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.7),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
            const SizedBox(height: 3),
          ],

          // 3D Tactile Button Node
          AnimatedBuilder(
            animation: _pressController,
            builder: (context, _) {
              final t = _pressController.value;
              final pushDown = t * (rimHeight - 0.5);

              return SizedBox(
                width: size,
                height: size + rimHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Bottom 3D Rim (Extruded Base)
                    Positioned(
                      top: rimHeight,
                      left: 0,
                      right: 0,
                      height: size,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rimColor,
                          boxShadow: [
                            if (widget.isUnlocked)
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.45),
                                blurRadius: widget.isCurrent ? 14.0 - (t * 4) : 8.0,
                                spreadRadius: widget.isCurrent ? 2 : 1,
                              ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 6.0 - (t * 2),
                              offset: Offset(0, 3.0 - (t * 1.5)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Top Glossy Dome Face
                    Positioned(
                      top: pushDown,
                      left: 0,
                      right: 0,
                      height: size,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [faceTop, faceBottom],
                          ),
                          border: Border.all(
                            color: widget.isUnlocked
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Specular highlight crescent
                            Positioned(
                              top: 2,
                              left: size * 0.16,
                              right: size * 0.16,
                              height: size * 0.40,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.elliptical(size * 0.35, size * 0.18),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.65),
                                      Colors.white.withValues(alpha: 0.05),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Number / Lock Icon
                            Center(
                              child: widget.isUnlocked
                                  ? Text(
                                      '${widget.levelNum}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: rimColor,
                                            offset: const Offset(0, 2),
                                            blurRadius: 2,
                                          ),
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            offset: const Offset(0, 3),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    )
                                  : Icon(
                                      Icons.lock_rounded,
                                      color: AppColors.textMuted.withValues(alpha: 0.7),
                                      size: 22,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.8),
                                          offset: const Offset(0, 1.5),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ──── 3D GOLDEN STAR CREST (High contrast, clearly visible on all biomes) ────
          if (widget.isUnlocked) ...[
            Transform.translate(
              offset: const Offset(0, -5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C101E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.stars > 0
                        ? const Color(0xFFFFB800).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                    if (widget.stars > 0)
                      BoxShadow(
                        color: const Color(0xFFFFB800).withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 0.5,
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCrestStar(hasStar: widget.stars >= 1, size: 13),
                    const SizedBox(width: 2.5),
                    Transform.translate(
                      offset: const Offset(0, -1.5),
                      child: _buildCrestStar(hasStar: widget.stars >= 2, size: 16),
                    ),
                    const SizedBox(width: 2.5),
                    _buildCrestStar(hasStar: widget.stars >= 3, size: 13),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCrestStar({required bool hasStar, required double size}) {
    if (hasStar) {
      return Icon(
        Icons.star_rounded,
        size: size,
        color: const Color(0xFFFFD54F),
        shadows: const [
          Shadow(
            color: Color(0xFFB45309),
            offset: Offset(0, 1),
            blurRadius: 1.5,
          ),
          Shadow(
            color: Color(0xFFFFB300),
            blurRadius: 6,
          ),
        ],
      );
    } else {
      return Icon(
        Icons.star_rounded,
        size: size,
        color: const Color(0xFF232B40),
        shadows: const [
          Shadow(
            color: Colors.black54,
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      );
    }
  }
}

/// Custom painter that draws glowing constellation lines between floating island waypoints
class _ConstellationPathPainter extends CustomPainter {
  final List<Offset> waypoints;
  final int activeLevel;

  _ConstellationPathPainter({required this.waypoints, required this.activeLevel});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < waypoints.length - 1; i++) {
      final from = waypoints[i];
      final to = waypoints[i + 1];

      final isActive = (i + 1) < activeLevel;
      final isCurrent = (i + 1) == activeLevel;

      final paint = Paint()
        ..strokeWidth = isActive ? 2.5 : 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      if (isActive) {
        paint.color = AppColors.cyan.withValues(alpha: 0.55);
        paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
      } else if (isCurrent) {
        paint.color = AppColors.cosmicCyanLight.withValues(alpha: 0.4);
      } else {
        paint.color = Colors.white.withValues(alpha: 0.10);
      }

      _drawDashedLine(canvas, from, to, paint);
    }

    // Small decorative cosmic stars
    final rng = Random(42);
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.2);
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = sqrt(dx * dx + dy * dy);
    const dashLength = 8.0;
    const gapLength = 6.0;
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
  bool shouldRepaint(covariant _ConstellationPathPainter oldDelegate) {
    return oldDelegate.activeLevel != activeLevel;
  }
}
