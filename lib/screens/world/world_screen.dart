import 'dart:math';
import 'package:flutter/material.dart';
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

/// Cosmic Constellation Level Progression Map for BLINK
/// Features:
/// - Deep space background with floating particles
/// - Constellation path connecting level nodes with light trails
/// - Glowing cosmic orb level pedestals
/// - Current active level with pulsing purple aura & player indicator
/// - Interactive Level Details card popup with cosmic Play button
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

  void _showLevelDialog(int levelNum, int stars, bool isUnlocked) {
    triggerHaptic(ref, HapticService.mediumTap);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.glassBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
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
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
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
                        color: isEarned ? AppColors.gold : AppColors.textMuted,
                        size: 36,
                        shadows: isEarned
                            ? [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.5),
                                  blurRadius: 8,
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
                    color: AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
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

                const SizedBox(height: 22),

                // Play Button
                if (isUnlocked)
                  TactileButton.cosmic(
                    label: 'PLAY',
                    height: 56,
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

                const SizedBox(height: 8),

                // Close Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
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
          // ──── 1. COSMIC TOP BAR ────
          const CandyTopBar(),

          // ──── 2. CONSTELLATION LEVEL MAP ────
          Expanded(
            child: Stack(
              children: [
                // Deep space gradient
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF0D1225),
                          Color(0xFF0A0E1A),
                          Color(0xFF080B16),
                        ],
                      ),
                    ),
                  ),
                ),

                // Particle field
                const Positioned.fill(
                  child: StarField(starCount: 30),
                ),

                // Scrollable constellation map
                Positioned.fill(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: double.infinity,
                      height: 2000,
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

          // ──── 3. COSMIC BOTTOM NAVIGATION ────
          const GameBottomNav(currentIndex: 0),
        ],
      ),
    );
  }

  List<Offset> _getWaypoints(double screenWidth) {
    // S-curve constellation path waypoints
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

      nodes.add(
        Positioned(
          top: wp.dy - 30,
          left: wp.dx - 30,
          child: _buildStageNode(levelNum, stars, isCurrent, isUnlocked),
        ),
      );
    }

    return nodes;
  }

  Widget _buildStageNode(int levelNum, int stars, bool isCurrent, bool isUnlocked) {
    Color glowColor;
    Color faceTop;
    Color faceBottom;

    if (isCurrent) {
      glowColor = AppColors.cyan;
      faceTop = AppColors.cosmicCyanLight;
      faceBottom = AppColors.cosmicCyanDark;
    } else if (isUnlocked) {
      glowColor = AppColors.primary;
      faceTop = AppColors.nebulaPurpleLight;
      faceBottom = AppColors.nebulaPurpleDark;
    } else {
      glowColor = Colors.transparent;
      faceTop = const Color(0xFF2A3050);
      faceBottom = const Color(0xFF1A2040);
    }

    final nodeWidget = GestureDetector(
      onTap: () => _showLevelDialog(levelNum, stars, isUnlocked),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current Player indicator floating above active level
          if (isCurrent) ...[
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.cyan, AppColors.cyanDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Level Node Orb
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [faceTop, faceBottom],
              ),
              border: Border.all(
                color: isUnlocked
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
              boxShadow: [
                if (isUnlocked)
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.5),
                    blurRadius: isCurrent ? 18 : 10,
                    spreadRadius: isCurrent ? 3 : 1,
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isUnlocked
                  ? Text(
                      '$levelNum',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    )
                  : Icon(
                      Icons.lock_rounded,
                      color: AppColors.textMuted.withValues(alpha: 0.6),
                      size: 22,
                    ),
            ),
          ),

          // Star badges
          if (stars > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Icon(
                  i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                  color: i < stars ? AppColors.gold : AppColors.textMuted.withValues(alpha: 0.3),
                  size: 14,
                );
              }),
            ),
          ],
        ],
      ),
    );

    return nodeWidget;
  }
}

/// Custom painter that draws faint constellation lines between level nodes
class _ConstellationPathPainter extends CustomPainter {
  final List<Offset> waypoints;
  final int activeLevel;

  _ConstellationPathPainter({required this.waypoints, required this.activeLevel});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw lines between consecutive waypoints
    for (int i = 0; i < waypoints.length - 1; i++) {
      final from = waypoints[i];
      final to = waypoints[i + 1];

      final isActive = (i + 1) < activeLevel;
      final isCurrent = (i + 1) == activeLevel;

      final paint = Paint()
        ..strokeWidth = isActive ? 2.0 : 1.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      if (isActive) {
        paint.color = AppColors.primary.withValues(alpha: 0.4);
        paint.strokeWidth = 2.5;
      } else if (isCurrent) {
        paint.color = AppColors.cyan.withValues(alpha: 0.3);
        paint.strokeWidth = 2.0;
      } else {
        paint.color = Colors.white.withValues(alpha: 0.08);
        paint.strokeWidth = 1.0;
      }

      // Draw dashed line effect
      _drawDashedLine(canvas, from, to, paint);
    }

    // Draw small decorative stars scattered around
    final rng = Random(42); // Fixed seed for consistency
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.15);
    for (int i = 0; i < 50; i++) {
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
    final dashLength = 8.0;
    final gapLength = 6.0;
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
