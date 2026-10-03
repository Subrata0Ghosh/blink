import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/player_state.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../buttons/tactile_button.dart';

/// Modal for Lives / Energy Management & Instant Refills (Candy Crush Style)
class LivesRefillModal extends ConsumerStatefulWidget {
  const LivesRefillModal({super.key});

  @override
  ConsumerState<LivesRefillModal> createState() => _LivesRefillModalState();
}

class _LivesRefillModalState extends ConsumerState<LivesRefillModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartPulseController;
  late Animation<double> _heartPulseAnimation;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _heartPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _heartPulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _heartPulseController, curve: Curves.easeInOut),
    );

    // Sync timer every second for countdown accuracy
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        ref.read(gameStateProvider.notifier).syncLives();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _heartPulseController.dispose();
    super.dispose();
  }

  Future<void> _refillWithGems() async {
    final player = ref.read(gameStateProvider);
    if (player.gems < 50) {
      AudioService().playWrong();
      triggerHaptic(ref, HapticService.wrongAnswer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough gems! Need 50 💎 to refill.',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final success = await ref.read(gameStateProvider.notifier).refillLivesWithGems();
    if (success) {
      AudioService().playPowerUp();
      triggerHaptic(ref, HapticService.mediumTap);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('❤️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'Energy fully restored! 5 Hearts ready!',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E2640),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);
    final currentLives = player.currentLives;
    final isFull = currentLives >= PlayerState.maxLives;
    final timeRemaining = player.timeUntilNextLife;

    String countdownStr = 'FULL';
    if (!isFull && timeRemaining != null) {
      final m = timeRemaining.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = timeRemaining.inSeconds.remainder(60).toString().padLeft(2, '0');
      countdownStr = '$m:$s';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF221630), Color(0xFF130E20)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFFF2A6D).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2A6D).withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row
            Row(
              children: [
                TactileButton.close(
                  size: 34,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'COSMIC ENERGY',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💎', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${player.gems}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gemCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pulsing Heart Graphic
            ScaleTransition(
              scale: _heartPulseAnimation,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFF3366), Color(0xFF880E4F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3366).withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('❤️', style: TextStyle(fontSize: 44)),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Heart Count & Timer
            Text(
              '$currentLives / ${PlayerState.maxLives} HEARTS',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFull ? Icons.check_circle_rounded : Icons.timer_outlined,
                  size: 14,
                  color: isFull ? const Color(0xFF00E676) : AppColors.gold,
                ),
                const SizedBox(width: 4),
                Text(
                  isFull ? 'Hearts are full!' : 'Next heart in $countdownStr',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isFull ? const Color(0xFF00E676) : AppColors.gold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 5 Heart Capsules Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(PlayerState.maxLives, (index) {
                final filled = index < currentLives;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 40,
                  height: 46,
                  decoration: BoxDecoration(
                    color: filled
                        ? const Color(0xFFFF3366).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: filled
                          ? const Color(0xFFFF3366).withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      filled ? '❤️' : '🤍',
                      style: TextStyle(
                        fontSize: 18,
                        color: filled ? null : Colors.white24,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // Refill Button
            if (!isFull) ...[
              TactileButton(
                label: 'REFILL ALL (50 💎)',
                fontSize: 15,
                height: 52,
                icon: Icons.bolt_rounded,
                faceColorTop: const Color(0xFFFF2A6D),
                faceColorBottom: const Color(0xFFD81B60),
                rimColor: const Color(0xFF880E4F),
                onTap: _refillWithGems,
              ),
              const SizedBox(height: 10),
            ],

            // Free Zen Practice Button
            GestureDetector(
              onTap: () {
                triggerHaptic(ref, HapticService.lightTap);
                ref.read(gameStateProvider.notifier).setCalmMode(true);
                Navigator.of(context).pop();
                context.push('/play');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.spa_rounded, color: Color(0xFF90E0EF), size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'PLAY ZEN MODE (FREE)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF90E0EF),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
