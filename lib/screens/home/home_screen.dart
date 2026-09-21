import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/particles/particles.dart';
import '../../widgets/world/world_3d_diorama.dart';
import '../../widgets/buttons/blink_button.dart';
import '../../widgets/navigation/game_bottom_nav.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../models/player_state.dart';
import '../../core/constants/app_assets.dart';

/// Home screen — Alive, interactive, with 3D perspective world diorama
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Animated cosmic background
          const StarField(starCount: 55),
          const FloatingParticles(count: 12, color: AppColors.primaryLight),

          SafeArea(
            child: Column(
              children: [
                // ──── TOP BAR ────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      // Avatar & Level + Name -> Profile
                      GestureDetector(
                        onTap: () {
                          triggerHaptic(ref, HapticService.lightTap);
                          context.go('/profile');
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlowPulse(
                              glowColor: AppColors.cyan,
                              maxBlur: 14,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.8), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.cyan.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    AppAssets.novaIdle,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.displayName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Level ${player.level}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppColors.cyan,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Gem counter -> Collectibles
                      GestureDetector(
                        onTap: () {
                          triggerHaptic(ref, HapticService.lightTap);
                          context.go('/collect');
                        },
                        child: _buildGemCounter(player.gems),
                      ),
                    ],
                  ),
                ),

                // ──── XP BAR ────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _buildXpBar(player),
                ),

                // ──── INTERACTIVE 3D WORLD DIORAMA ────
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          World3dDiorama(
                            player: player,
                            size: 280,
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              triggerHaptic(ref, HapticService.mediumTap);
                              context.go('/world');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              child: Text(
                                'THE SHIFT WORLD',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cyan,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ──── TACTILE 3D PLAY BUTTON ────
                BlinkButton(
                  label: 'PLAY',
                  icon: Icons.play_arrow_rounded,
                  onTap: () => context.push('/play'),
                ),

                const SizedBox(height: 22),

                // ──── QUICK ACCESS BUTTONS ────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickButton(
                        'DAILY\nSHIFT',
                        Icons.today_rounded,
                        AppColors.cyan,
                        () => context.push('/daily-shift'),
                      ),
                      _buildQuickButton(
                        'MYSTERY',
                        Icons.help_outline_rounded,
                        AppColors.gemPurple,
                        () => context.push('/mystery'),
                      ),
                      _buildQuickButton(
                        'WORLD',
                        Icons.public_rounded,
                        AppColors.mint,
                        () => context.go('/world'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
      // ──── BOTTOM NAVIGATION ────
      bottomNavigationBar: const GameBottomNav(currentIndex: 0),
    );
  }

  Widget _buildGemCounter(int gems) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AppAssets.shiftGem,
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$gems',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpBar(PlayerState player) {
    final progress = player.xpToNextLevel > 0
        ? (player.xp / player.xpToNextLevel).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XP',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${player.xp} / ${player.xpToNextLevel}',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        triggerHaptic(ref, HapticService.mediumTap);
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
