import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../gameplay/challenge_engine/challenge_engine.dart';
import '../../gameplay/rendering/arena_surface.dart';
import '../../gameplay/rendering/radial_energy_timer.dart';
import '../../gameplay/rendering/tactile_object.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/buttons/tactile_option_button.dart';
import '../../widgets/particles/particles.dart';

/// Mystery Mode Screen — Section 40
/// Cryptic cosmic shift with dark purple runes, hidden rules, and rare relic rewards.
class MysteryScreen extends ConsumerStatefulWidget {
  const MysteryScreen({super.key});

  @override
  ConsumerState<MysteryScreen> createState() => _MysteryScreenState();
}

class _MysteryScreenState extends ConsumerState<MysteryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fogController;
  final ChallengeEngine _engine = ChallengeEngine();
  Challenge? _challenge;
  bool _isObserving = true;
  double _timeLeft = 5.0;
  int? _selectedAnswer;
  bool _showVictory = false;

  Timer? _observationTimer;
  Timer? _victoryTimer;

  @override
  void initState() {
    super.initState();
    _fogController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _challenge = _engine.generateChallenge(
      mode: ChallengeMode.hiddenRule,
      difficulty: 30,
    );

    _runObservationTimer();
  }

  void _runObservationTimer() {
    _observationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft > 0 && _isObserving) {
        setState(() => _timeLeft -= 0.1);
      } else {
        timer.cancel();
        if (_isObserving) {
          setState(() => _isObserving = false);
        }
      }
    });
  }

  void _selectAnswer(int index) {
    if (_selectedAnswer != null) return;

    final correct = index == _challenge!.correctAnswerIndex;
    setState(() {
      _selectedAnswer = index;
    });

    if (correct) {
      triggerHaptic(ref, HapticService.perfectAnswer);
      ref.read(gameStateProvider.notifier).processChallengeResult(
        correct: true,
        reactionTimeMs: 1400,
        currentCombo: 2,
        challengeType: 'mystery_mode',
      );

      _victoryTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showVictory = true);
      });
    } else {
      triggerHaptic(ref, HapticService.wrongAnswer);
    }
  }

  void _handleClose() {
    triggerHaptic(ref, HapticService.lightTap);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/world');
    }
  }

  @override
  void dispose() {
    _observationTimer?.cancel();
    _victoryTimer?.cancel();
    _fogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090615),
      body: Stack(
        children: [
          // Mystic Starfield
          const StarField(starCount: 65),

          // Mystic Purple Atmospheric Glow
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fogController,
              builder: (context, _) {
                final angle = _fogController.value * 2 * pi;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(sin(angle) * 0.3, cos(angle) * 0.3),
                      radius: 1.2,
                      colors: [
                        AppColors.gemPurple.withValues(alpha: 0.22),
                        const Color(0xFF0D0820).withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ──── TOP BAR ────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      TactileButton.close(
                        size: 42,
                        onTap: _handleClose,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.gemPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.gemPurple.withValues(alpha: 0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gemPurple.withValues(alpha: 0.25),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.help_outline_rounded, color: AppColors.gemPurple, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'MYSTERY SHIFT • HIDDEN RULE',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFD68BFF),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Timer / Guidance row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isObserving ? 'DECIPHER THE PHENOMENON' : 'WHAT IS THE HIDDEN LAW?',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _isObserving ? const Color(0xFFD68BFF) : AppColors.gold,
                        ),
                      ),
                      if (_isObserving)
                        RadialEnergyTimer(
                          progress: (_timeLeft / 5.0).clamp(0.0, 1.0),
                          timeLeft: _timeLeft,
                          size: 42,
                        ),
                    ],
                  ),
                ),

                // Arena Scene
                Expanded(
                  child: ArenaSurface(
                    enableBreathing: _isObserving,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final scene = _challenge!.originalScene;

                        return Stack(
                          children: scene.asMap().entries.map((entry) {
                            final obj = entry.value;
                            final posX = obj.position.dx * (constraints.maxWidth - 70) + 10;
                            final posY = obj.position.dy * (constraints.maxHeight - 78) + 12;

                            return AnimatedPositioned(
                              key: ValueKey(obj.id),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutBack,
                              left: posX,
                              top: posY,
                              child: TactileObject(
                                gameObject: obj,
                                baseSize: 58,
                                spawnIndex: entry.key,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),

                // Question & Answers
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    children: [
                      Text(
                        _challenge!.question,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._challenge!.answers.asMap().entries.map((entry) {
                        final isSelected = _selectedAnswer == entry.key;
                        final isCorrect = entry.key == _challenge!.correctAnswerIndex;
                        final showRes = _selectedAnswer != null;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TactileOptionButton(
                            index: entry.key,
                            text: entry.value,
                            isSelected: isSelected,
                            isCorrect: isCorrect,
                            showResult: showRes,
                            height: 52,
                            onTap: () => _selectAnswer(entry.key),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Victory Celebration Modal
          if (_showVictory)
            Container(
              color: Colors.black.withValues(alpha: 0.88),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gemPurple.withValues(alpha: 0.25),
                          border: Border.all(color: AppColors.gemPurple, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gemPurple.withValues(alpha: 0.6),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFD68BFF),
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'MYSTERY SOLVED!',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFD68BFF),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+40 XP • +30 SHIFT GEMS • RARE DISCOVERY',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TactileButton.nebula(
                        label: 'CLAIM REWARD',
                        width: 220,
                        height: 54,
                        fontSize: 16,
                        onTap: _handleClose,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
