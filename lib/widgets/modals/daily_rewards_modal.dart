import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../buttons/tactile_button.dart';
import '../particles/particles.dart';
import 'juicy_modal_wrapper.dart';

/// 7-Day Cosmic Daily Reward Streak Calendar Modal
/// High retention feature designed to bring users back every day with escalating rewards.
class DailyRewardsModal extends ConsumerStatefulWidget {
  const DailyRewardsModal({super.key});

  @override
  ConsumerState<DailyRewardsModal> createState() => _DailyRewardsModalState();
}

class _DailyRewardsModalState extends ConsumerState<DailyRewardsModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnimation;
  bool _justClaimed = false;
  Map<String, int>? _claimedReward;

  static const List<Map<String, dynamic>> _rewardTiers = [
    {'day': 1, 'gems': 50, 'xp': 25, 'title': 'Stardust'},
    {'day': 2, 'gems': 75, 'xp': 40, 'title': 'Nova Shard'},
    {'day': 3, 'gems': 100, 'xp': 60, 'title': 'Astral Gem'},
    {'day': 4, 'gems': 150, 'xp': 80, 'title': 'Cosmic Orb'},
    {'day': 5, 'gems': 200, 'xp': 100, 'title': 'Solar Shard'},
    {'day': 6, 'gems': 250, 'xp': 120, 'title': 'Void Prism'},
    {'day': 7, 'gems': 500, 'xp': 250, 'title': 'Cosmic Chest!'},
  ];

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _claim() {
    final notifier = ref.read(gameStateProvider.notifier);
    final result = notifier.claimDailyReward();

    setState(() {
      _justClaimed = true;
      _claimedReward = result;
    });

    _celebrationController.forward(from: 0.0);
    HapticFeedback.heavyImpact();
    triggerHaptic(ref, HapticService.levelUp);
    AudioService().playLevelUp();
    AudioService().playGemPickup();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);
    final isAvailable = player.isDailyRewardAvailable;
    final currentDay = player.dailyRewardDay;

    return JuicyCosmicModal(
      primaryGlowColor: AppColors.cyan,
      secondaryGlowColor: AppColors.gemPurple,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
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
                              colors: [Color(0xFF00E5FF), Color(0xFF007A99)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyan.withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY REWARDS',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              '7-Day Cosmic Streak',
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

                const SizedBox(height: 18),

                // 7-Day Grid / Row Presentation
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _rewardTiers.map((tier) {
                        final dayNum = tier['day'] as int;
                        final gems = tier['gems'] as int;
                        final isGrandDay = dayNum == 7;

                        // State of this day
                        final isCurrent = dayNum == currentDay;
                        final isPast = dayNum < currentDay;

                        return _buildRewardCard(
                          day: dayNum,
                          gems: gems,
                          isCurrent: isCurrent,
                          isPast: isPast,
                          isGrand: isGrandDay,
                          canClaim: isCurrent && isAvailable && !_justClaimed,
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Action Area: Claim Button or Status
                if (_justClaimed)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            '+${_claimedReward?['gems'] ?? 50} GEMS CLAIMED!',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (isAvailable)
                  TactileButton.cosmic(
                    label: 'CLAIM TODAY\'S GIFT',
                    fontSize: 16,
                    height: 52,
                    width: double.infinity,
                    icon: Icons.card_giftcard_rounded,
                    onTap: _claim,
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2844),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2E3858)),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF00E676),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Claimed for today! Next gift in a new day.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

          // Particle burst overlay when claiming
          if (_justClaimed)
            const Positioned.fill(
              child: IgnorePointer(
                child: FloatingParticles(count: 25, color: AppColors.cyan),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRewardCard({
    required int day,
    required int gems,
    required bool isCurrent,
    required bool isPast,
    required bool isGrand,
    required bool canClaim,
  }) {
    Color borderColor = const Color(0xFF222B48);
    Color topColor = const Color(0xFF1B233D);
    Color bottomColor = const Color(0xFF121729);

    if (canClaim) {
      borderColor = AppColors.cyan;
      topColor = const Color(0xFF183B5E);
      bottomColor = const Color(0xFF0C243B);
    } else if (isPast) {
      borderColor = const Color(0xFF00E676).withValues(alpha: 0.5);
      topColor = const Color(0xFF152A28);
      bottomColor = const Color(0xFF0D1B1A);
    } else if (isGrand) {
      borderColor = AppColors.gold;
      topColor = const Color(0xFF3B3015);
      bottomColor = const Color(0xFF241C0A);
    }

    return Container(
      width: isGrand ? 190 : 72,
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ),
        border: Border.all(
          color: borderColor,
          width: canClaim ? 2.0 : 1.2,
        ),
        boxShadow: canClaim
            ? [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Day label
          Text(
            'DAY $day',
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: canClaim ? AppColors.cyan : (isGrand ? AppColors.gold : AppColors.textSecondary),
              letterSpacing: 0.6,
            ),
          ),

          // Icon
          Icon(
            isPast
                ? Icons.check_circle_rounded
                : (isGrand ? Icons.workspace_premium_rounded : Icons.diamond_rounded),
            color: isPast
                ? const Color(0xFF00E676)
                : (isGrand ? AppColors.gold : (canClaim ? AppColors.gemCyan : const Color(0xFF6B7A9E))),
            size: isGrand ? 28 : 22,
          ),

          // Gems value
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+$gems',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.diamond_rounded,
                size: 11,
                color: AppColors.gemCyan,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
