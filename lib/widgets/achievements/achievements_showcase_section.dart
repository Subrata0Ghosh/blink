import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../models/player_state.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../animations/achievement_popup.dart';

/// Shows collectible achievement badges with unlocked / locked visual states
class AchievementsShowcaseSection extends ConsumerWidget {
  const AchievementsShowcaseSection({super.key});

  static bool isUnlocked(Achievement achievement, PlayerState player, SharedPreferences? prefs) {
    if (prefs?.getBool('achievement_${achievement.id}') == true) return true;
    switch (achievement.id) {
      case 'level_5':
        return player.level >= 5;
      case 'level_10':
        return player.level >= 10;
      case 'ten_games':
        return player.totalChallenges >= 10;
      case 'combo_3':
        return player.bestCombo >= 3;
      case 'combo_5':
        return player.bestCombo >= 5;
      case 'combo_10':
        return player.bestCombo >= 10;
      case 'speed_demon':
        return player.bestReactionTimeMs > 0 && player.bestReactionTimeMs < 1000;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameStateProvider);
    SharedPreferences? prefs;
    try {
      prefs = ref.watch(sharedPreferencesProvider);
    } catch (_) {}

    final all = Achievements.all;
    final unlockedCount = all.where((a) => isUnlocked(a, player, prefs)).length;
    final progress = all.isNotEmpty ? unlockedCount / all.length : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'ACHIEVEMENTS & TROPHIES',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$unlockedCount / ${all.length}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.gold),
          ),
        ),

        const SizedBox(height: 14),

        // Badge Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: all.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final achievement = all[index];
            final unlocked = isUnlocked(achievement, player, prefs);
            return _buildBadgeCard(context, ref, achievement, unlocked);
          },
        ),
      ],
    );
  }

  Widget _buildBadgeCard(
    BuildContext context,
    WidgetRef ref,
    Achievement achievement,
    bool unlocked,
  ) {
    return GestureDetector(
      onTap: () {
        triggerHaptic(ref, HapticService.lightTap);
        if (unlocked) {
          AudioService().playGemPickup();
        } else {
          AudioService().playUiClick();
        }
        _showBadgeDetails(context, achievement, unlocked);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: unlocked
              ? AppColors.surface.withValues(alpha: 0.95)
              : AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? AppColors.gold.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.08),
            width: unlocked ? 1.5 : 1.0,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon medallion
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: unlocked
                        ? const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.03),
                            ],
                          ),
                    border: Border.all(
                      color: unlocked
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      achievement.icon,
                      style: TextStyle(
                        fontSize: 22,
                        color: unlocked ? null : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                if (!unlocked)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // Title
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),

            const SizedBox(height: 2),

            // Badge status / reward
            if (unlocked)
              Text(
                'UNLOCKED',
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                  letterSpacing: 0.5,
                ),
              )
            else
              Text(
                '+${achievement.gemReward} 💎',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gemCyan,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, Achievement achievement, bool unlocked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: unlocked ? AppColors.gold.withValues(alpha: 0.4) : AppColors.glassBorder,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: unlocked
                      ? const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        )
                      : null,
                  color: unlocked ? null : AppColors.surfaceLight,
                ),
                child: Center(
                  child: Text(
                    achievement.icon,
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                achievement.title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                achievement.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: unlocked
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.gemPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: unlocked ? AppColors.success : AppColors.gemCyan,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      unlocked ? Icons.check_circle_rounded : Icons.diamond_rounded,
                      color: unlocked ? AppColors.success : AppColors.gemCyan,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      unlocked
                          ? 'Achievement Completed (+${achievement.gemReward} 💎)'
                          : 'Reward: +${achievement.gemReward} Gems',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: unlocked ? AppColors.success : AppColors.gemCyan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
