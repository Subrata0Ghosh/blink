import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/relic_model.dart';
import '../../services/game_state_service.dart';
import '../buttons/tactile_button.dart';
import 'juicy_modal_wrapper.dart';

/// Modal for exploring the Constellation Codex & Ancient Cosmic Relics
class RelicsModal extends ConsumerWidget {
  const RelicsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameStateProvider);
    final relics = CosmicRelic.allRelics;

    return JuicyCosmicModal(
      primaryGlowColor: const Color(0xFFFFD700),
      secondaryGlowColor: AppColors.cyan,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.black87,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONSTELLATION CODEX',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Ancient Relics of the Watchers',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

          // Scrollable Relics List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: relics.length,
              itemBuilder: (context, index) {
                final relic = relics[index];
                // Check if unlocked (either level condition or streak condition)
                final isUnlocked = (player.level >= relic.unlockLevel) ||
                    (relic.id == 'nebula_heart' && player.dailyRewardDay >= 3);

                return _buildRelicCard(context, ref, relic, isUnlocked);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelicCard(
    BuildContext context,
    WidgetRef ref,
    CosmicRelic relic,
    bool isUnlocked,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFF151D36) : const Color(0xFF0C101E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked
              ? relic.auraColor.withValues(alpha: 0.65)
              : const Color(0xFF1E2844),
          width: isUnlocked ? 1.6 : 1.0,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: relic.auraColor.withValues(alpha: 0.20),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Relic Icon in glowing circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked ? const Color(0xFF0A0F22) : const Color(0xFF080B16),
              border: Border.all(
                color: isUnlocked ? relic.auraColor : const Color(0xFF283454),
                width: 1.5,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: relic.auraColor.withValues(alpha: 0.45),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              relic.icon,
              color: isUnlocked ? relic.auraColor : const Color(0xFF4A5578),
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        relic.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isUnlocked ? Colors.white : const Color(0xFF7885A8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: relic.auraColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: relic.auraColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: relic.auraColor,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161F34),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF283655)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_rounded, size: 11, color: Color(0xFF8896BA)),
                            const SizedBox(width: 3),
                            Text(
                              relic.unlockRequirement,
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8896BA),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  relic.lore,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: isUnlocked ? AppColors.textSecondary : const Color(0xFF4A5578),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: isUnlocked ? relic.auraColor : const Color(0xFF5A668C),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        relic.perkDescription,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked ? relic.auraColor : const Color(0xFF5A668C),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
