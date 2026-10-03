import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../characters/observer_avatar_badge.dart';
import '../modals/daily_rewards_modal.dart';
import '../modals/lives_refill_modal.dart';

/// 3D Tactile Top Bar for BLINK
/// Features:
/// - 3D docked base with extruded dark rim and subtle drop shadow
/// - 3D tactile circular Mail button with glossy dome and push-down effect
/// - 3D tactile Streak / Flame pill tracking daily logins and opening rewards
/// - 3D elevated Center Avatar medallion with double bevel rim and level star
/// - 3D tactile Gems pill with interactive 3D '+' button
/// - 3D tactile circular Settings button matching Image 1 & 2
class CandyTopBar extends ConsumerWidget {
  final VoidCallback? onSettingsTap;
  final VoidCallback? onMailTap;
  final VoidCallback? onStreakTap;
  final VoidCallback? onLivesTap; // Backwards compatibility alias
  final VoidCallback? onGemsTap;

  const CandyTopBar({
    super.key,
    this.onSettingsTap,
    this.onMailTap,
    this.onStreakTap,
    this.onLivesTap,
    this.onGemsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameStateProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFF1E2844),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isVeryCompact = constraints.maxWidth < 360;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // ──── 1. LEFT SIDE: 3D LIVES [❤️ 5] & 3D STREAK [🔥] ────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 3D Lives / Hearts Pill
                        _TactilePill(
                          onTap: onLivesTap ??
                              () {
                                triggerHaptic(ref, HapticService.lightTap);
                                showDialog(
                                  context: context,
                                  builder: (context) => const LivesRefillModal(),
                                );
                              },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF3366), Color(0xFFC2185B)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF3366).withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text('❤️', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${player.currentLives}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 5),

                        // 3D Streak Flame Pill
                        _TactilePill(
                          onTap: onStreakTap ??
                              () {
                                triggerHaptic(ref, HapticService.lightTap);
                                showDialog(
                                  context: context,
                                  builder: (context) => const DailyRewardsModal(),
                                );
                              },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6D00).withValues(alpha: 0.6),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                              if (!isVeryCompact) ...[
                                const SizedBox(width: 5),
                                Text(
                                  player.currentStreak > 0 ? '${player.currentStreak}d' : 'START',
                                  style: GoogleFonts.outfit(
                                    fontSize: player.currentStreak > 0 ? 12.5 : 11,
                                    fontWeight: FontWeight.w800,
                                    color: player.currentStreak > 0 ? AppColors.textPrimary : const Color(0xFFFFB74D),
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ──── 2. DEAD CENTER: 3D PROFILE AVATAR BEZEL ────
                  Align(
                    alignment: Alignment.center,
                    child: _TactileAvatarBezel(
                      level: player.level,
                      avatarId: player.selectedAvatarId,
                      frameId: player.selectedFrameId,
                      onTap: () {
                        triggerHaptic(ref, HapticService.mediumTap);
                        context.go('/profile');
                      },
                    ),
                  ),

              // ──── 3. RIGHT SIDE: 3D GEMS PILL [💎 568 (+)] ────
              Align(
                alignment: Alignment.centerRight,
                child: _TactilePill(
                  onTap: onGemsTap ??
                      () {
                        triggerHaptic(ref, HapticService.lightTap);
                        context.push('/collect');
                      },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gem icon
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gemCyan.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.diamond_rounded,
                            color: AppColors.gemCyan,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${player.gems}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 3D Mini Plus button
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.stellarGreenLight, AppColors.stellarGreenDark],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.stellarGreenRim.withValues(alpha: 0.8),
                              offset: const Offset(0, 1.5),
                              blurRadius: 0,
                            ),
                            BoxShadow(
                              color: AppColors.stellarGreen.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  ),
);
  }
}

/// 3D Tactile Pill with extruded rim, top specular highlight, and tap depression physics
class _TactilePill extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TactilePill({
    required this.child,
    required this.onTap,
  });

  @override
  State<_TactilePill> createState() => _TactilePillState();
}

class _TactilePillState extends State<_TactilePill> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _animController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) {
    _animController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    const rimHeight = 3.5;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final t = _animController.value;
          final pushDown = t * (rimHeight - 0.5);

          return Transform.translate(
            offset: Offset(0, pushDown),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF263050),
                    Color(0xFF141A2E),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF090D18),
                    offset: Offset(0, rimHeight - pushDown),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 4.0 - (t * 2.0),
                    offset: Offset(0, 3.0 - (t * 1.5)),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Specular highlight crescent
                  Positioned(
                    top: 0,
                    left: 4,
                    right: 4,
                    height: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                          bottom: Radius.elliptical(30, 6),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Inner Content
                  widget.child,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 3D Tactile Avatar Medallion with extruded rims and physical tap depression
class _TactileAvatarBezel extends StatefulWidget {
  final int level;
  final String avatarId;
  final String frameId;
  final VoidCallback onTap;

  const _TactileAvatarBezel({
    required this.level,
    this.avatarId = 'nova_happy',
    this.frameId = 'frame_cyan',
    required this.onTap,
  });

  @override
  State<_TactileAvatarBezel> createState() => _TactileAvatarBezelState();
}

class _TactileAvatarBezelState extends State<_TactileAvatarBezel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _animController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) {
    _animController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    const size = 38.0;
    const rimHeight = 3.0;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final t = _animController.value;
          final pushDown = t * (rimHeight - 0.5);

          return SizedBox(
            width: size,
            height: size + rimHeight + 2,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // 1. Bottom 3D Rim
                Positioned(
                  top: rimHeight,
                  width: size,
                  height: size,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cosmicCyanRim,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withValues(alpha: 0.4),
                          blurRadius: 6.0 - (t * 3.0),
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Top Face with Glossy Bezel
                Positioned(
                  top: pushDown,
                  width: size,
                  height: size,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.cosmicCyanLight, AppColors.cosmicCyanDark],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 1.2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: ClipOval(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ObserverAvatarBadge(
                              avatarId: widget.avatarId,
                              frameId: widget.frameId,
                              size: size - 3,
                              isCircle: true,
                              showShadow: false,
                            ),
                            // Top highlight arc
                            Positioned(
                              top: 1,
                              left: 5,
                              right: 5,
                              height: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.elliptical(10, 5)),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.55),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Level Star Tag
                Positioned(
                  bottom: -1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.nebulaPurpleLight, AppColors.nebulaPurpleDark],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.nebulaPurpleRim,
                          offset: const Offset(0, 1),
                          blurRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 3,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Text(
                      '★${widget.level}',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.7),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
