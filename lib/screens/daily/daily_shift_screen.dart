import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../gameplay/challenge_engine/challenge_engine.dart';
import '../../gameplay/rendering/arena_surface.dart';
import '../../gameplay/rendering/radial_energy_timer.dart';
import '../../gameplay/rendering/tactile_object.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../widgets/particles/particles.dart';

/// Daily Shift Mode — Section 39
/// Special daily portal opening presentation with double rewards and streak progression.
class DailyShiftScreen extends ConsumerStatefulWidget {
  const DailyShiftScreen({super.key});

  @override
  ConsumerState<DailyShiftScreen> createState() => _DailyShiftScreenState();
}

class _DailyShiftScreenState extends ConsumerState<DailyShiftScreen>
    with TickerProviderStateMixin {
  late AnimationController _portalController;
  late Animation<double> _portalScale;
  late Animation<double> _portalRotation;

  bool _portalComplete = false;
  final ChallengeEngine _engine = ChallengeEngine();
  Challenge? _challenge;
  bool _isObserving = true;
  double _timeLeft = 4.0;
  int? _selectedAnswer;
  bool _showVictory = false;

  Timer? _portalTimer;
  Timer? _observationTimer;
  Timer? _victoryTimer;

  @override
  void initState() {
    super.initState();

    _portalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _portalScale = Tween<double>(begin: 0.1, end: 1.6).animate(
      CurvedAnimation(parent: _portalController, curve: Curves.easeInCubic),
    );
    _portalRotation = Tween<double>(begin: 0, end: pi * 3).animate(
      CurvedAnimation(parent: _portalController, curve: Curves.easeInOut),
    );

    _challenge = _engine.generateChallenge(mode: ChallengeMode.change, difficulty: 25);

    _startPortal();
  }

  void _startPortal() {
    _portalController.forward();
    triggerHaptic(ref, HapticService.mediumTap);

    _portalTimer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) {
        setState(() => _portalComplete = true);
        _runObservationTimer();
      }
    });
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
      ref.read(gameStateProvider.notifier).updateStreak();
      ref.read(gameStateProvider.notifier).processChallengeResult(
        correct: true,
        reactionTimeMs: 1200,
        currentCombo: 3,
        challengeType: 'daily_shift',
      );

      _victoryTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showVictory = true);
      });
    } else {
      triggerHaptic(ref, HapticService.wrongAnswer);
    }
  }

  @override
  void dispose() {
    _portalTimer?.cancel();
    _observationTimer?.cancel();
    _victoryTimer?.cancel();
    _portalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarField(starCount: 60),

          // Portal Opening Animation
          if (!_portalComplete)
            Center(
              child: AnimatedBuilder(
                animation: _portalController,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _portalScale.value,
                    child: Transform.rotate(
                      angle: _portalRotation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              AppColors.cyan,
                              AppColors.primary,
                              AppColors.gemPurple,
                              AppColors.cyan,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withValues(alpha: 0.8),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Challenge Content after portal traversal
          if (_portalComplete && !_showVictory)
            SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.today_rounded, color: AppColors.cyan, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'DAILY SHIFT • 2X REWARDS',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.cyan,
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

                  // Observe Timer / Reality Shifted tag
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isObserving ? 'OBSERVE THE COSMOS' : 'REALITY SHIFTED • WHAT CHANGED?',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isObserving ? AppColors.cyan : AppColors.gold,
                          ),
                        ),
                        if (_isObserving)
                          RadialEnergyTimer(
                            progress: (_timeLeft / 4.0).clamp(0.0, 1.0),
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
                          final scene = _isObserving
                              ? _challenge!.originalScene
                              : (_challenge!.modifiedScene ?? _challenge!.originalScene);

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

                  // Answer Buttons (visible when observation finishes)
                  if (!_isObserving)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        children: _challenge!.answers.asMap().entries.map((entry) {
                          final isSelected = _selectedAnswer == entry.key;
                          final isCorrect = entry.key == _challenge!.correctAnswerIndex;
                          final showRes = _selectedAnswer != null;

                          Color borderCol = AppColors.glassBorder;
                          Color bgCol = AppColors.surface;
                          if (showRes) {
                            if (isCorrect) {
                              borderCol = AppColors.success;
                              bgCol = AppColors.success.withValues(alpha: 0.15);
                            } else if (isSelected && !isCorrect) {
                              borderCol = AppColors.error;
                              bgCol = AppColors.error.withValues(alpha: 0.15);
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () => _selectAnswer(entry.key),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: bgCol,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderCol, width: isSelected ? 2.0 : 1.0),
                                ),
                                child: Text(
                                  entry.value,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

          // Victory Reward Celebration Modal
          if (_showVictory)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Shift Chest asset
                      Image.asset(AppAssets.shiftChest, width: 140, height: 140),
                      const SizedBox(height: 20),
                      Text(
                        'DAILY SHIFT COMPLETE!',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cyan,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+50 XP • +25 SHIFT GEMS • STREAK EXTENDED',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () => context.pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cyan,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(
                            'CLAIM REWARDS',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
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
