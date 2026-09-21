import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/player_state.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';

/// Cosmic Glassmorphic Top Bar for BLINK
/// Features:
/// - Dark frosted glass header with subtle glow border
/// - Heart Lives counter with cosmic glow
/// - Center Player Avatar with cyan ring bezel
/// - Gem counter pill with glowing accent
/// - Settings button with glassmorphic style
class CandyTopBar extends ConsumerWidget {
  final VoidCallback? onSettingsTap;
  final VoidCallback? onMailTap;
  final VoidCallback? onLivesTap;
  final VoidCallback? onGemsTap;

  const CandyTopBar({
    super.key,
    this.onSettingsTap,
    this.onMailTap,
    this.onLivesTap,
    this.onGemsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameStateProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(
            color: AppColors.glassBorder,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ──── 1. MAIL / NOTIFICATIONS ────
              _buildGlassCircle(
                context,
                ref,
                Icons.mail_rounded,
                AppColors.cyan,
                onTap: onMailTap ??
                    () {
                      triggerHaptic(ref, HapticService.lightTap);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'No new transmissions from the Cosmos!',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppColors.surfaceLight,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
              ),

              const SizedBox(width: 4),

              // ──── 2. LIVES / HEARTS PILL ────
              _buildLivesPill(context, ref),

              const SizedBox(width: 4),

              // ──── 3. CENTER AVATAR BEZEL ────
              _buildAvatarBezel(context, ref, player),

              const SizedBox(width: 4),

              // ──── 4. GEMS PILL ────
              _buildGemsPill(context, ref, player),

              const SizedBox(width: 4),

              // ──── 5. SETTINGS ────
              _buildGlassCircle(
                context,
                ref,
                Icons.settings_rounded,
                AppColors.textSecondary,
                onTap: onSettingsTap ??
                    () {
                      triggerHaptic(ref, HapticService.mediumTap);
                      context.go('/profile');
                    },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCircle(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    Color iconColor, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassWhite,
          border: Border.all(color: AppColors.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildLivesPill(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onLivesTap ??
          () {
            triggerHaptic(ref, HapticService.lightTap);
          },
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing heart
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5580), Color(0xFFD42060)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5580).withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Full',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarBezel(BuildContext context, WidgetRef ref, PlayerState player) {
    return GestureDetector(
      onTap: () {
        triggerHaptic(ref, HapticService.lightTap);
        context.go('/profile');
      },
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Outer Cyan Glow Bezel
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.cyan, AppColors.cyanDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: ClipOval(
                child: Container(
                  color: AppColors.surface,
                  child: Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.cyan,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Level Star Tag at bottom
          Positioned(
            bottom: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                '★${player.level}',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGemsPill(BuildContext context, WidgetRef ref, PlayerState player) {
    return GestureDetector(
      onTap: onGemsTap ??
          () {
            triggerHaptic(ref, HapticService.lightTap);
            context.go('/collect');
          },
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gem icon with glow
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gemPurple.withValues(alpha: 0.2),
              ),
              child: const Center(
                child: Icon(
                  Icons.diamond_rounded,
                  color: AppColors.gemCyan,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${player.gems > 0 ? player.gems : 250}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            // Green "+" button
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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.stellarGreen.withValues(alpha: 0.4),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
