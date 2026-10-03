import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../models/solar_realm_model.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/characters/observer_avatar_badge.dart';
import '../../widgets/modals/relics_modal.dart';
import '../../widgets/navigation/candy_top_bar.dart';
import '../../widgets/navigation/game_bottom_nav.dart';
import '../../widgets/particles/particles.dart';
import '../../widgets/world/biome_bridge_painter.dart';
import '../../widgets/world/floating_island_painter.dart';
import '../../widgets/world/solar_orrery_view.dart';
import '../../widgets/world/story_chronicle_banner.dart';

/// Cosmic Floating Islands Level Progression Map for BLINK
/// Features:
/// - Solar System Orrery View with smooth macro-to-micro Zoom In / Zoom Out
/// - Narrative Story Chronicles with Nova's planetary transmission and alien companion lore
/// - 5 Biomes with distinct island roles: Citadel Castles, Living Alien Sanctuaries, Crystal Spires, and Gateways
/// - 5 Biome Bridge types: Vines, Prismatic Rainbow, Molten Basalt Plasma, Celestial Clouds, and Cyber Data Grids
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
  bool _isOrreryView = false;

  @override
  void initState() {
    super.initState();
    AudioService().startAmbientMusic();
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
        final levelIndex = (player.unlockedWorldLevel - 1).clamp(0, 19);
        final waypoints = _getWaypoints(MediaQuery.of(context).size.width);
        final levelY = waypoints[levelIndex].dy;
        final viewportHeight = _scrollController.position.viewportDimension;
        final targetScroll = (levelY - viewportHeight / 2).clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.jumpTo(targetScroll);
      }
    });
  }

  void _toggleOrreryView() {
    triggerHaptic(ref, HapticService.mediumTap);
    AudioService().playUiConfirm();
    setState(() {
      _isOrreryView = !_isOrreryView;
    });
  }

  void _onSelectRealmFromOrrery(SolarRealm realm) {
    setState(() {
      _isOrreryView = false;
    });
    _scrollToRealm(realm);
  }

  void _scrollToRealm(SolarRealm realm) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final baseYs = [2850.0, 2250.0, 1650.0, 1050.0, 450.0];
      final realmY = baseYs[realm.index.clamp(0, 4)];
      final viewportHeight = _scrollController.position.viewportDimension;
      final targetScroll = (realmY - viewportHeight / 2).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
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
                          context.push('/play?level=$levelNum');
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
    final currentLevel = player.unlockedWorldLevel.clamp(1, 20);
    final currentRealm = SolarRealm.getRealmForLevel(currentLevel);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ──── 1. 3D COSMIC TOP BAR ────
          const CandyTopBar(),

          // ──── 2. STORY CHRONICLE / MISSION BANNER ────
          StoryChronicleBanner(
            currentRealm: currentRealm,
            activeLevel: currentLevel,
            isOrreryOpen: _isOrreryView,
            onToggleOrrery: _toggleOrreryView,
          ),

          // ──── 3. MAIN ARENA (Animated switch between Archipelago & Orrery) ────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _isOrreryView
                  ? SolarOrreryView(
                      key: const ValueKey('solar_orrery_view'),
                      activeLevel: currentLevel,
                      levelStars: player.levelStars,
                      onSelectRealm: _onSelectRealmFromOrrery,
                      onZoomInToCurrent: () => _onSelectRealmFromOrrery(currentRealm),
                    )
                  : Stack(
                      key: const ValueKey('archipelago_view'),
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
                              height: 3300,
                              child: Stack(
                                children: [
                                  // 1. Procedural Animated Biome Bridges
                                  Positioned.fill(
                                    child: AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, _) {
                                        return CustomPaint(
                                          painter: BiomeBridgePainter(
                                            waypoints: _getWaypoints(MediaQuery.of(context).size.width),
                                            activeLevel: currentLevel,
                                            pulseValue: _pulseController.value,
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // 2. 3D Floating Island Nodes
                                  ..._buildLevelNodes(
                                    currentLevel,
                                    MediaQuery.of(context).size.width,
                                    player.selectedAvatarId,
                                    player.selectedFrameId,
                                    player.levelStars,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 3D Tactile Mystery Portal Button
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: TactileButton.portal(
                            label: 'MYSTERY PORTAL',
                            width: 155,
                            height: 44,
                            fontSize: 12,
                            onTap: () {
                              triggerHaptic(ref, HapticService.mediumTap);
                              context.push('/mystery');
                            },
                          ),
                        ),

                        // 3D Tactile Constellation Codex / Relics Button
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: TactileButton.solar(
                            label: 'RELICS',
                            icon: Icons.auto_awesome_rounded,
                            width: 110,
                            height: 44,
                            fontSize: 12,
                            onTap: () {
                              triggerHaptic(ref, HapticService.mediumTap);
                              AudioService().playUiConfirm();
                              showDialog(
                                context: context,
                                builder: (_) => const RelicsModal(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // ──── 4. 3D COSMIC BOTTOM NAVIGATION ────
          const GameBottomNav(currentIndex: 0),
        ],
      ),
    );
  }

  List<Offset> _getWaypoints(double screenWidth) {
    // 5 Biome Constellation Archipelagos (Levels 1 to 20)
    // Generous ~600px vertical step per realm with ZERO overlapping
    final baseYs = [2850.0, 2250.0, 1650.0, 1050.0, 450.0];
    final waypoints = <Offset>[];

    for (int b = 0; b < baseYs.length; b++) {
      final cy = baseYs[b];
      final isEven = b % 2 == 0;
      final westX = screenWidth * (isEven ? 0.22 : 0.78);
      final eastX = screenWidth * (isEven ? 0.78 : 0.22);

      waypoints.addAll([
        Offset(screenWidth * 0.50, cy + 130), // Base Entrance (Level 4b + 1)
        Offset(westX, cy),                    // Flank Satellite 1 (Level 4b + 2)
        Offset(eastX, cy),                    // Flank Satellite 2 (Level 4b + 3)
        Offset(screenWidth * 0.50, cy - 130), // Gateway Citadel (Level 4b + 4)
      ]);
    }
    return waypoints;
  }

  List<Widget> _buildLevelNodes(
    int activeLevel,
    double screenWidth,
    String avatarId,
    String frameId,
    Map<int, int> levelStars,
  ) {
    final List<Widget> nodes = [];
    final waypoints = _getWaypoints(screenWidth);

    // Sort by Y ascending (top to bottom on screen), so background islands (smaller Y)
    // are added FIRST, and foreground islands (larger Y) are added LAST!
    // In Flutter Stack, later children render ON TOP of earlier children.
    final indexedWaypoints = List.generate(waypoints.length, (i) => MapEntry(i, waypoints[i]))
      ..sort((a, b) {
        final cmp = a.value.dy.compareTo(b.value.dy);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });

    for (final entry in indexedWaypoints) {
      final i = entry.key;
      final wp = entry.value;
      final levelNum = i + 1;
      final isCurrent = levelNum == activeLevel;
      final isUnlocked = levelNum <= activeLevel;
      final stars = levelStars[levelNum] ?? (isUnlocked ? (levelNum < activeLevel ? 3 : 1) : 0);
      final biome = _getBiomeForLevel(levelNum);
      final isMilestone = levelNum % 4 == 0;
      final role = SolarRealm.getIslandRole(levelNum);
      final realm = SolarRealm.getRealmForLevel(levelNum);

      final islandWidth = isMilestone ? 172.0 : 152.0;
      final islandHeight = isMilestone ? 164.0 : 144.0;
      final isRightSideOfScreen = wp.dx > (screenWidth * 0.50);

      nodes.add(
        Positioned(
          key: ValueKey('island_pos_$levelNum'),
          top: wp.dy - (islandHeight * 0.28),
          left: wp.dx - (islandWidth * 0.5),
          child: FloatingIslandWidget(
            key: ValueKey('floating_island_$levelNum'),
            biome: biome,
            width: islandWidth,
            height: islandHeight,
            isCurrent: isCurrent,
            isMilestone: isMilestone,
            role: role,
            alien: role == IslandRole.alienSanctuary ? realm.alien : null,
            alienOnLeft: isRightSideOfScreen,
            child: _TactileLevelNode(
              levelNum: levelNum,
              stars: stars,
              isCurrent: isCurrent,
              isUnlocked: isUnlocked,
              avatarId: avatarId,
              frameId: frameId,
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
  final String avatarId;
  final String frameId;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  const _TactileLevelNode({
    required this.levelNum,
    required this.stars,
    required this.isCurrent,
    required this.isUnlocked,
    this.avatarId = 'nova_happy',
    this.frameId = 'frame_cyan',
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
    if (widget.isUnlocked) {
      AudioService().playUiConfirm();
    } else {
      AudioService().playUiBack();
    }
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
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Current Player floating crown indicator (hovers directly over the button without pushing it down)
          if (widget.isCurrent)
            Positioned(
              top: -26,
              child: AnimatedBuilder(
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
                      color: Colors.white.withValues(alpha: 0.95),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.8),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: ObserverAvatarBadge(
                      avatarId: widget.avatarId,
                      frameId: widget.frameId,
                      size: 25,
                      isCircle: true,
                      showShadow: false,
                    ),
                  ),
                ),
              ),
            ),

          // 2. 3D Tactile Button Node & Star Crest
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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

