import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../buttons/tactile_button.dart';
import 'juicy_modal_wrapper.dart';

/// Daily Cosmic Quests / Missions Modal
/// Provides clear daily objectives to motivate players to play multiple rounds and spend more time.
class DailyQuestsModal extends ConsumerWidget {
  const DailyQuestsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    final quests = [
      {
        'id': 'quest_shifts_3',
        'title': 'Cosmic Observer',
        'desc': 'Complete 3 shifts in Play Mode',
        'icon': Icons.remove_red_eye_rounded,
        'current': player.todayShiftsPlayed,
        'target': 3,
        'gems': 50,
        'xp': 25,
      },
      {
        'id': 'quest_combo_5',
        'title': 'Starlight Focus',
        'desc': 'Achieve a 5x Combo in any mode',
        'icon': Icons.bolt_rounded,
        'current': player.todayBestCombo,
        'target': 5,
        'gems': 75,
        'xp': 40,
      },
      {
        'id': 'quest_level_world',
        'title': 'Dimensional Traveler',
        'desc': 'Reach Level ${player.level + 1} or complete a shift',
        'icon': Icons.auto_awesome_rounded,
        'current': player.todayShiftsPlayed > 0 ? 1 : 0,
        'target': 1,
        'gems': 100,
        'xp': 60,
      },
    ];

    return JuicyCosmicModal(
      primaryGlowColor: AppColors.gemPurple,
      secondaryGlowColor: AppColors.cyan,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gemPurple.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY MISSIONS',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Resets every midnight',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                TactileButton.circle(
                  size: 32,
                  faceColorTop: const Color(0xFF252E4C),
                  faceColorBottom: const Color(0xFF13182B),
                  rimColor: const Color(0xFF080C18),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quest List
            ...quests.map((q) {
              final questId = q['id'] as String;
              final title = q['title'] as String;
              final desc = q['desc'] as String;
              final icon = q['icon'] as IconData;
              final current = (q['current'] as int).clamp(0, q['target'] as int);
              final target = q['target'] as int;
              final gems = q['gems'] as int;
              final xp = q['xp'] as int;

              final isClaimed = player.dailyQuestsClaimed.contains(questId);
              final isCompleted = current >= target;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF182038),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isCompleted && !isClaimed
                        ? AppColors.cyan
                        : const Color(0xFF283454),
                    width: isCompleted && !isClaimed ? 1.6 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10162A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppColors.cyan, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // Title & progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            desc,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: current / target,
                              backgroundColor: const Color(0xFF0F1528),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted ? const Color(0xFF00E676) : AppColors.cyan,
                              ),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Action / Status
                    if (isClaimed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D251D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          'CLAIMED',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF00E676),
                          ),
                        ),
                      )
                    else if (isCompleted)
                      GestureDetector(
                        onTap: () {
                          notifier.claimDailyQuest(questId, gems, xp);
                          HapticFeedback.mediumImpact();
                          triggerHaptic(ref, HapticService.gemPickup);
                          AudioService().playGemPickup();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF007A99)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyan.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+$gems',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.diamond_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10162A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$current/$target',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
            );
          }),
        ],
      ),
    );
  }
}
