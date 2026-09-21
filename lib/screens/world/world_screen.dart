import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../widgets/navigation/game_bottom_nav.dart';
import '../../widgets/particles/particles.dart';

/// Interactive World Screen — Explorable 3D celestial sanctuary map
/// Features:
/// - Smooth pan and zoom canvas (InteractiveViewer)
/// - Living central island sanctuary
/// - Satellite structures unlocking as player level grows (Observatory, Crystal Spire, Void Portal)
/// - Interactive tap on structures to inspect lore & collect crystal bonuses
class WorldScreen extends ConsumerStatefulWidget {
  const WorldScreen({super.key});

  @override
  ConsumerState<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends ConsumerState<WorldScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleController;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Center map initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      final x = -(1200 - size.width) / 2;
      final y = -(1200 - size.height) / 2;
      _transformController.value = Matrix4.translationValues(x, y, 0.0);
    });
  }

  @override
  void dispose() {
    _idleController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _inspectStructure(_CelestialStructure structure) {
    triggerHaptic(ref, HapticService.mediumTap);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: structure.color.withValues(alpha: 0.18),
                        border: Border.all(color: structure.color.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: structure.color.withValues(alpha: 0.3),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Icon(structure.icon, color: structure.color, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            structure.name,
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            structure.isUnlocked ? 'UNLOCKED • LEVEL ${structure.requiredWorldLevel}' : 'LOCKED • REACH WORLD LEVEL ${structure.requiredWorldLevel}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: structure.isUnlocked ? AppColors.cyan : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  structure.description,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'CLOSE',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
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

    final structures = [
      _CelestialStructure(
        name: 'The Core Sanctuary',
        description: 'The anchoring heart of the Shift World. Channels cosmic starlight into pure observation energy.',
        icon: Icons.temple_buddhist_rounded,
        position: const Offset(600, 600),
        color: AppColors.cyan,
        requiredWorldLevel: 1,
        isUnlocked: player.worldLevel >= 1,
      ),
      _CelestialStructure(
        name: 'Starlight Observatory',
        description: 'Peer into distant shifting dimensions. Accelerates observation reflex time.',
        icon: Icons.lens_blur_rounded,
        position: const Offset(430, 480),
        color: AppColors.primaryLight,
        requiredWorldLevel: 2,
        isUnlocked: player.worldLevel >= 2,
      ),
      _CelestialStructure(
        name: 'Crystal Spire',
        description: 'Faceted crystal reservoir. Amplifies combo rewards and generates shift gems.',
        icon: Icons.diamond_rounded,
        position: const Offset(780, 520),
        color: AppColors.gemPurple,
        requiredWorldLevel: 3,
        isUnlocked: player.worldLevel >= 3,
      ),
      _CelestialStructure(
        name: 'Void Portal Gate',
        description: 'A stable conduit between realities. Unlocks rare dimensional shifts.',
        icon: Icons.all_inclusive_rounded,
        position: const Offset(500, 770),
        color: AppColors.mint,
        requiredWorldLevel: 4,
        isUnlocked: player.worldLevel >= 4,
      ),
      _CelestialStructure(
        name: 'Celestial Monolith',
        description: 'Ancient titan relic from before the first blink. Grants ultimate cosmic vision.',
        icon: Icons.blur_on_rounded,
        position: const Offset(740, 750),
        color: AppColors.gold,
        requiredWorldLevel: 5,
        isUnlocked: player.worldLevel >= 5,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Pannable/Zoomable 3D Map Canvas
          InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.55,
            maxScale: 2.2,
            boundaryMargin: const EdgeInsets.all(400),
            child: SizedBox(
              width: 1200,
              height: 1200,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Deep cosmic space background with starfield
                  const Positioned.fill(child: StarField(starCount: 120)),

                  // Nebula aura background
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WorldMapGridPainter(),
                    ),
                  ),

                  // Constellation connecting lines between unlocked structures
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ConstellationLinesPainter(structures),
                    ),
                  ),

                  // Center Floating Island Sanctuary
                  Positioned(
                    left: 450,
                    top: 450,
                    child: AnimatedBuilder(
                      animation: _idleController,
                      builder: (context, child) {
                        final floatY = sin(_idleController.value * 2 * pi) * 6.0;
                        return Transform.translate(
                          offset: Offset(0, floatY),
                          child: child,
                        );
                      },
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return RadialGradient(
                            radius: 0.7,
                            colors: const [Colors.white, Colors.white, Colors.transparent],
                            stops: const [0.0, 0.65, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: Image.asset(
                          AppAssets.floatingIsland,
                          width: 300,
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  // Structure Node Markers
                  ...structures.map((s) {
                    return Positioned(
                      left: s.position.dx - 36,
                      top: s.position.dy - 36,
                      child: _buildStructureNode(s),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Top Header Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.public_rounded, color: AppColors.cyan, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'WORLD MAP • TIER ${player.worldLevel}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cyan,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Gem pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Image.asset(AppAssets.shiftGem, width: 18, height: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${player.gems}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation Instructions Overlay (auto disappears / subtle bottom indicator)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Text(
                  'DRAG TO PAN • PINCH TO ZOOM',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const GameBottomNav(currentIndex: 2),
    );
  }

  Widget _buildStructureNode(_CelestialStructure structure) {
    return GestureDetector(
      onTap: () => _inspectStructure(structure),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: structure.isUnlocked
                  ? structure.color.withValues(alpha: 0.25)
                  : AppColors.surface,
              border: Border.all(
                color: structure.isUnlocked ? structure.color : AppColors.glassBorder,
                width: 2.0,
              ),
              boxShadow: structure.isUnlocked
                  ? [
                      BoxShadow(
                        color: structure.color.withValues(alpha: 0.5),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              structure.isUnlocked ? structure.icon : Icons.lock_outline_rounded,
              color: structure.isUnlocked ? structure.color : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: structure.isUnlocked
                    ? structure.color.withValues(alpha: 0.4)
                    : AppColors.glassBorder,
              ),
            ),
            child: Text(
              structure.name,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: structure.isUnlocked ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CelestialStructure {
  final String name;
  final String description;
  final IconData icon;
  final Offset position;
  final Color color;
  final int requiredWorldLevel;
  final bool isUnlocked;

  _CelestialStructure({
    required this.name,
    required this.description,
    required this.icon,
    required this.position,
    required this.color,
    required this.requiredWorldLevel,
    required this.isUnlocked,
  });
}

class _WorldMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Orbital celestial rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.cyan.withValues(alpha: 0.10);

    for (double r = 180; r <= 500; r += 100) {
      canvas.drawCircle(center, r, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConstellationLinesPainter extends CustomPainter {
  final List<_CelestialStructure> structures;
  _ConstellationLinesPainter(this.structures);

  @override
  void paint(Canvas canvas, Size size) {
    final center = structures.first.position;

    for (int i = 1; i < structures.length; i++) {
      final s = structures[i];
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = s.isUnlocked
            ? s.color.withValues(alpha: 0.35)
            : AppColors.glassBorder.withValues(alpha: 0.2);

      canvas.drawLine(center, s.position, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationLinesPainter oldDelegate) => true;
}
