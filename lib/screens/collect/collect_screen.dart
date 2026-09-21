import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../gameplay/challenge_engine/game_objects.dart';
import '../../gameplay/rendering/gem_2d5_painter.dart';
import '../../gameplay/rendering/moon_2d5_painter.dart';
import '../../gameplay/rendering/object_2d5_painter.dart';
import '../../gameplay/rendering/star_2d5_painter.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../widgets/navigation/game_bottom_nav.dart';
import '../../widgets/particles/particles.dart';

/// 3D-feel Collectible Gallery for BLINK
/// Section 38:
/// - Items rotate in 3D, glow, have shadows, and react to taps
/// - Filter by rarity: ALL, COMMON, RARE, EPIC, LEGENDARY, MYSTERY
/// - Full 3D inspection modal with interactive tumble physics
class CollectScreen extends ConsumerStatefulWidget {
  const CollectScreen({super.key});

  @override
  ConsumerState<CollectScreen> createState() => _CollectScreenState();
}

class _CollectScreenState extends ConsumerState<CollectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  int _selectedRarityIndex = 0; // 0 = ALL, 1 = COMMON, 2 = RARE, 3 = EPIC, 4 = LEGENDARY, 5 = MYSTERY

  final List<String> _rarities = ['ALL', 'COMMON', 'RARE', 'EPIC', 'LEGENDARY', 'MYSTERY'];

  final List<_CollectibleItem> _allItems = [
    _CollectibleItem(
      id: 'shift_gem',
      name: 'Shift Gem',
      type: GameObjectType.gem,
      color: AppColors.cyan,
      rarity: 'COMMON',
      description: 'The primary mineral of the Shift Universe. Refracts dimensional light when reality blinks.',
    ),
    _CollectibleItem(
      id: 'cosmic_star',
      name: 'Cosmic Star',
      type: GameObjectType.star,
      color: AppColors.gold,
      rarity: 'COMMON',
      description: 'Five-faceted astral beacon. Radiates celestial warmth and guides wandering observers.',
    ),
    _CollectibleItem(
      id: 'lunar_crescent',
      name: 'Lunar Crescent',
      type: GameObjectType.moon,
      color: AppColors.primaryLight,
      rarity: 'RARE',
      description: 'Forged from moonlit crater dust. Its rim glows brighter when observation time diminishes.',
    ),
    _CollectibleItem(
      id: 'void_orb',
      name: 'Void Orb',
      type: GameObjectType.orb,
      color: AppColors.gemPurple,
      rarity: 'RARE',
      description: 'A smooth sphere of compressed gravity. Absorbs optical illusions.',
    ),
    _CollectibleItem(
      id: 'solar_bolt',
      name: 'Solar Bolt',
      type: GameObjectType.bolt,
      color: AppColors.amber,
      rarity: 'EPIC',
      description: 'Pulsating lightning shard. Grants heightened reaction reflexes during rapid changes.',
    ),
    _CollectibleItem(
      id: 'prism_cube',
      name: 'Prism Cube',
      type: GameObjectType.cube,
      color: AppColors.mint,
      rarity: 'EPIC',
      description: 'Isometric crystal block. Stores memories of previous realities before they shift.',
    ),
    _CollectibleItem(
      id: 'chronos_ring',
      name: 'Chronos Ring',
      type: GameObjectType.ring,
      color: AppColors.gold,
      rarity: 'LEGENDARY',
      description: 'Continuous temporal torus. Dilates the final seconds of the observation window.',
    ),
    _CollectibleItem(
      id: 'astral_leaf',
      name: 'Astral Leaf',
      type: GameObjectType.leaf,
      color: Color(0xFF69F0AE),
      rarity: 'LEGENDARY',
      description: 'Living foliage from the world tree of the Core Sanctuary. Breathes in harmony with Nova.',
    ),
    _CollectibleItem(
      id: 'shadow_pyramid',
      name: 'Shadow Pyramid',
      type: GameObjectType.triangle,
      color: Color(0xFFFF6EE6),
      rarity: 'MYSTERY',
      description: 'A cryptic three-faced relic discovered inside Mystery Mode. Changes form when looked away from.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'COMMON':
        return AppColors.rarityCommon;
      case 'RARE':
        return AppColors.rarityRare;
      case 'EPIC':
        return AppColors.rarityEpic;
      case 'LEGENDARY':
        return AppColors.rarityLegendary;
      case 'MYSTERY':
        return AppColors.rarityMystery;
      default:
        return AppColors.textPrimary;
    }
  }

  void _openInspectModal(_CollectibleItem item) {
    triggerHaptic(ref, HapticService.mediumTap);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _Inspect3dModal(
        item: item,
        rarityColor: _getRarityColor(item.rarity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);

    final filteredItems = _selectedRarityIndex == 0
        ? _allItems
        : _allItems.where((item) => item.rarity == _rarities[_selectedRarityIndex]).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarField(starCount: 50),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ──── TOP HEADER ────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.grid_view_rounded, color: AppColors.cyan, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'COLLECTIBLES',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.cyan,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Gem counter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
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

                const SizedBox(height: 16),

                // ──── RARITY TABS ────
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _rarities.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedRarityIndex == index;
                      final rarity = _rarities[index];
                      final color = _getRarityColor(rarity);

                      return GestureDetector(
                        onTap: () {
                          triggerHaptic(ref, HapticService.lightTap);
                          setState(() => _selectedRarityIndex = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surfaceLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? color : AppColors.glassBorder,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            rarity,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? color : AppColors.textMuted,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ──── ITEMS GRID ────
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final rarityColor = _getRarityColor(item.rarity);

                      return _buildItemCard(item, rarityColor);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const GameBottomNav(currentIndex: 2),
    );
  }

  Widget _buildItemCard(_CollectibleItem item, Color rarityColor) {
    return GestureDetector(
      onTap: () => _openInspectModal(item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: rarityColor.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 2.5D Animated Object Preview
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, _) {
                final t = _rotationController.value;
                final floatY = sin(t * 2 * pi) * 4.0;
                final tiltY = cos(t * 2 * pi) * 0.12;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(tiltY),
                  child: Transform.translate(
                    offset: Offset(0, floatY),
                    child: SizedBox(
                      width: 68,
                      height: 68,
                      child: CustomPaint(
                        painter: _getItemPainter(item, t),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Item Name
            Text(
              item.name,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Rarity Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: rarityColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                item.rarity,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: rarityColor,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomPainter _getItemPainter(_CollectibleItem item, double progress) {
    switch (item.type) {
      case GameObjectType.gem:
        return Gem2d5Painter(baseColor: item.color, animationProgress: progress);
      case GameObjectType.star:
        return Star2d5Painter(baseColor: item.color, animationProgress: progress);
      case GameObjectType.moon:
        return Moon2d5Painter(baseColor: item.color, animationProgress: progress);
      default:
        return Object2d5Painter(type: item.type, baseColor: item.color, animationProgress: progress);
    }
  }
}

class _CollectibleItem {
  final String id;
  final String name;
  final GameObjectType type;
  final Color color;
  final String rarity;
  final String description;

  _CollectibleItem({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.rarity,
    required this.description,
  });
}

/// 3D Inspection Modal with Interactive Tumble Physics
class _Inspect3dModal extends StatefulWidget {
  final _CollectibleItem item;
  final Color rarityColor;

  const _Inspect3dModal({
    required this.item,
    required this.rarityColor,
  });

  @override
  State<_Inspect3dModal> createState() => _Inspect3dModalState();
}

class _Inspect3dModalState extends State<_Inspect3dModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _rotX = 0.0;
  double _rotY = 0.0;
  bool _showSparkles = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: widget.rarityColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: widget.rarityColor.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Rarity Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: widget.rarityColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.rarityColor.withValues(alpha: 0.6)),
              ),
              child: Text(
                widget.item.rarity,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: widget.rarityColor,
                  letterSpacing: 2,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              widget.item.name,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const Spacer(),

            // Interactive 3D Turntable Area
            GestureDetector(
              onPanUpdate: (d) {
                setState(() {
                  _rotY += d.delta.dx * 0.02;
                  _rotX -= d.delta.dy * 0.02;
                });
              },
              onTap: () {
                setState(() => _showSparkles = true);
              },
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  final t = _animController.value;
                  final autoRotY = _rotY + (t * 2 * pi);

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial pedestal glow
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.item.color.withValues(alpha: 0.4),
                              blurRadius: 36,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),

                      // 3D Matrix Transform
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002)
                          ..rotateX(_rotX)
                          ..rotateY(autoRotY),
                        child: SizedBox(
                          width: 110,
                          height: 110,
                          child: CustomPaint(
                            painter: _get3dPainter(t),
                          ),
                        ),
                      ),

                      if (_showSparkles)
                        SparkBurst(
                          color: widget.item.color,
                          size: 90,
                          onComplete: () => setState(() => _showSparkles = false),
                        ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 10),
            Text(
              'DRAG TO ROTATE 3D • TAP TO PULSE',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 2,
              ),
            ),

            const Spacer(),

            // Description
            Text(
              widget.item.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
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
                  'COLLECTED',
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
  }

  CustomPainter _get3dPainter(double t) {
    switch (widget.item.type) {
      case GameObjectType.gem:
        return Gem2d5Painter(baseColor: widget.item.color, animationProgress: t);
      case GameObjectType.star:
        return Star2d5Painter(baseColor: widget.item.color, animationProgress: t);
      case GameObjectType.moon:
        return Moon2d5Painter(baseColor: widget.item.color, animationProgress: t);
      default:
        return Object2d5Painter(type: widget.item.type, baseColor: widget.item.color, animationProgress: t);
    }
  }
}
