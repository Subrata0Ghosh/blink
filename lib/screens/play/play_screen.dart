import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../gameplay/challenge_engine/challenge_engine.dart';
import '../../gameplay/challenge_engine/game_objects.dart';
import '../../gameplay/rendering/arena_surface.dart';
import '../../gameplay/rendering/tactile_object.dart';
import '../../gameplay/rendering/radial_energy_timer.dart';
import '../../widgets/particles/particles.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';

/// Play screen — The Core Gameplay Loop of BLINK
/// Powered by:
/// - Tactile 2.5D Animated Game Objects (Star, Moon, Gem, Orb, Cube, etc.)
/// - Dimensional Arena Surface with depth gradient, perspective rim, and atmospheric motes
/// - Staggered materialization spawn sequences
/// - Signature World Shift transition with camera push & circular energy wave
/// - Physics-based answer buttons with satisfying tactile feedback
class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> with TickerProviderStateMixin {
  final ChallengeEngine _engine = ChallengeEngine();
  Challenge? _challenge;
  int _round = 1;
  int _combo = 0;
  int _score = 0;
  int _totalXp = 0;
  int _totalGems = 0;
  int _correctCount = 0;

  // Phase management
  _GamePhase _phase = _GamePhase.intro;
  Timer? _timer;
  double _timeLeft = 0;
  DateTime? _answerStartTime;

  // Animation Controllers
  late AnimationController _countdownController;
  late AnimationController _sceneController;
  late AnimationController _feedbackController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _shiftController;
  late Animation<double> _shiftScaleAnimation;
  late Animation<double> _shiftWaveAnimation;

  int _countdownValue = 3;
  bool _showPerfect = false;
  bool _showEnergyRing = false;
  int? _selectedAnswer;
  bool? _lastAnswerCorrect;

  // 2.5D Spawning & World Shift flags
  bool _isSpawning = false;
  bool _isWorldShifting = false;

  // Hidden developer debug mode (activated by tapping ROUND 5 times)
  int _debugTapCount = 0;
  bool _showDebug = false;

  @override
  void initState() {
    super.initState();

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _sceneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // World Shift signature camera push & energy wave
    _shiftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _shiftScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.07).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.07, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 55),
    ]).animate(_shiftController);

    _shiftWaveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shiftController, curve: Curves.easeOutQuad),
    );

    _startRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownController.dispose();
    _sceneController.dispose();
    _feedbackController.dispose();
    _shakeController.dispose();
    _shiftController.dispose();
    super.dispose();
  }

  void _startRound() {
    final player = ref.read(gameStateProvider);
    final mode = _engine.getRandomUnlockedMode(player.level);
    final difficulty = player.level + (_round - 1) * 2;

    setState(() {
      _challenge = _engine.generateChallenge(mode: mode, difficulty: difficulty);
      _phase = _GamePhase.intro;
      _selectedAnswer = null;
      _lastAnswerCorrect = null;
      _showPerfect = false;
      _showEnergyRing = false;
      _countdownValue = 3;
      _isSpawning = false;
      _isWorldShifting = false;
    });

    _runIntroSequence();
  }

  void _runIntroSequence() async {
    // Mode title & instruction introduction
    await Future.delayed(const Duration(milliseconds: 800));

    // Countdown 3-2-1
    if (!mounted) return;
    setState(() => _phase = _GamePhase.countdown);
    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _countdownValue = i);
      _countdownController.forward(from: 0);
      triggerHaptic(ref, HapticService.lightTap);
      await Future.delayed(const Duration(milliseconds: 650));
    }

    // Materialize into Observe Phase
    if (!mounted) return;
    setState(() {
      _phase = _GamePhase.observe;
      _isSpawning = true;
    });
    _sceneController.forward(from: 0);
    _timeLeft = _challenge!.observeTime;

    // Timer for observation
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeLeft -= 0.05;
        if (_timeLeft <= 0) {
          timer.cancel();
          _onObserveComplete();
        }
      });
    });
  }

  void _onObserveComplete() async {
    if (_challenge!.modifiedScene != null) {
      // Trigger Signature World Shift transition
      setState(() => _isWorldShifting = true);
      _shiftController.forward(from: 0.0);
      triggerHaptic(ref, HapticService.mediumTap);

      // Brief shift pause
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;

      setState(() {
        _phase = _GamePhase.modified;
        _isSpawning = false;
      });

      // Allow player to notice modification
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) {
        setState(() => _isWorldShifting = false);
        _showAnswerPhase();
      }
    } else {
      _showAnswerPhase();
    }
  }

  void _showAnswerPhase() {
    setState(() {
      _phase = _GamePhase.answer;
      _timeLeft = _challenge!.answerTime;
      _answerStartTime = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeLeft -= 0.05;
        if (_timeLeft <= 0) {
          timer.cancel();
          _onAnswerTimeout();
        }
      });
    });
  }

  void _onAnswerSelected(int index) {
    if (_selectedAnswer != null) return;
    _timer?.cancel();

    final reactionTime = DateTime.now().difference(_answerStartTime!).inMilliseconds;
    final correct = index == _challenge!.correctAnswerIndex;

    setState(() {
      _selectedAnswer = index;
      _lastAnswerCorrect = correct;
    });

    if (correct) {
      _combo++;
      _correctCount++;
      final result = ref.read(gameStateProvider.notifier).processChallengeResult(
        correct: true,
        reactionTimeMs: reactionTime,
        currentCombo: _combo,
        challengeType: _challenge!.mode.name,
      );
      _totalXp += result.xpEarned;
      _totalGems += result.gemsEarned;
      _score += 100 + (_combo * 15);

      triggerHaptic(ref, HapticService.correctAnswer);

      if (result.isPerfect) {
        setState(() {
          _showPerfect = true;
          _showEnergyRing = true;
        });
        triggerHaptic(ref, HapticService.perfectAnswer);
      }

      _feedbackController.forward(from: 0);

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) {
          if (_round >= 5) {
            _goToResult();
          } else {
            _round++;
            _startRound();
          }
        }
      });
    } else {
      _combo = 0;
      ref.read(gameStateProvider.notifier).processChallengeResult(
        correct: false,
        reactionTimeMs: reactionTime,
        currentCombo: 0,
        challengeType: _challenge!.mode.name,
      );
      triggerHaptic(ref, HapticService.wrongAnswer);
      _shakeController.forward(from: 0);

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          if (_round >= 5) {
            _goToResult();
          } else {
            _round++;
            _startRound();
          }
        }
      });
    }
  }

  void _onAnswerTimeout() {
    _onAnswerSelected(-1); // Treat timeout as wrong
  }

  void _goToResult() {
    context.pushReplacement('/result', extra: {
      'score': _score,
      'xp': _totalXp,
      'gems': _totalGems,
      'correct': _correctCount,
      'total': _round,
      'combo': _combo,
    });
  }

  void _handleRoundTapForDebug() {
    _debugTapCount++;
    if (_debugTapCount >= 5) {
      setState(() => _showDebug = !_showDebug);
      _debugTapCount = 0;
      triggerHaptic(ref, HapticService.mediumTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Cosmic Starfield background
          const StarField(starCount: 45),
          const FloatingParticles(count: 10, color: AppColors.primaryLight),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),

          // World Shift Energy Wave Overlay
          if (_isWorldShifting)
            AnimatedBuilder(
              animation: _shiftWaveAnimation,
              builder: (context, _) {
                final progress = _shiftWaveAnimation.value;
                return IgnorePointer(
                  child: CustomPaint(
                    painter: _WorldShiftWavePainter(progress),
                    size: Size.infinite,
                  ),
                );
              },
            ),

          // Perfect Energy Ring Overlay
          if (_showEnergyRing)
            Positioned.fill(
              child: EnergyRing(
                color: AppColors.cyan,
                onComplete: () => setState(() => _showEnergyRing = false),
              ),
            ),

          // Perfect Celebration Text Overlay
          if (_showPerfect)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1.15),
                duration: const Duration(milliseconds: 550),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Text(
                      'PERFECT',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.cyan,
                        letterSpacing: 6,
                        shadows: [
                          Shadow(
                            color: AppColors.cyan.withValues(alpha: 0.8),
                            blurRadius: 32,
                          ),
                          Shadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 60,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onEnd: () {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) setState(() => _showPerfect = false);
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
            ),
          ),
          const Spacer(),

          // Round indicator (tappable 5 times to toggle hidden debug mode)
          GestureDetector(
            onTap: _handleRoundTapForDebug,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _showDebug ? AppColors.primary.withValues(alpha: 0.25) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _showDebug ? 'DEBUG ROUND $_round / 5' : 'ROUND $_round / 5',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _showDebug ? AppColors.cyan : AppColors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Combo indicator
          if (_combo > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.25),
                    AppColors.amber.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                'x$_combo',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                ),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_phase) {
      case _GamePhase.intro:
        return _buildIntroPhase();
      case _GamePhase.countdown:
        return _buildCountdownPhase();
      case _GamePhase.observe:
        return _buildObservePhase(false);
      case _GamePhase.modified:
        return _buildObservePhase(true);
      case _GamePhase.answer:
        return _buildAnswerPhase();
    }
  }

  Widget _buildIntroPhase() {
    if (_challenge == null) return const SizedBox();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              _challenge!.modeName.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.cyan,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _challenge!.instruction,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownPhase() {
    return Center(
      child: AnimatedBuilder(
        animation: _countdownController,
        builder: (context, _) {
          final scale = 1.0 + (1.0 - _countdownController.value) * 0.45;
          final opacity = (1.0 - _countdownController.value * 0.3).clamp(0.0, 1.0);
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Text(
                '$_countdownValue',
                style: GoogleFonts.outfit(
                  fontSize: 76,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyan,
                  shadows: [
                    Shadow(
                      color: AppColors.cyan.withValues(alpha: 0.6),
                      blurRadius: 28,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildObservePhase(bool showModified) {
    if (_challenge == null) return const SizedBox();
    final scene = showModified
        ? (_challenge!.modifiedScene ?? _challenge!.originalScene)
        : _challenge!.originalScene;

    final maxTime = _challenge!.observeTime;
    final progress = maxTime > 0 ? (_timeLeft / maxTime).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        // ──── HUD / TIMER ────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mode State Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: showModified
                      ? AppColors.gold.withValues(alpha: 0.15)
                      : AppColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: showModified
                        ? AppColors.gold.withValues(alpha: 0.4)
                        : AppColors.cyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      showModified ? Icons.auto_awesome_rounded : Icons.visibility_rounded,
                      size: 14,
                      color: showModified ? AppColors.gold : AppColors.cyan,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      showModified ? 'REALITY SHIFTED' : 'OBSERVE',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: showModified ? AppColors.gold : AppColors.cyan,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Radial Energy Timer (during observe phase)
              if (!showModified)
                RadialEnergyTimer(
                  progress: progress,
                  timeLeft: _timeLeft,
                  size: 48,
                )
              else
                Text(
                  'What changed?',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
            ],
          ),
        ),

        // ──── 2.5D ARENA SCENE ────
        Expanded(
          child: AnimatedBuilder(
            animation: Listenable.merge([_sceneController, _shiftScaleAnimation]),
            builder: (context, child) {
              final sceneScale = 0.92 + (_sceneController.value * 0.08);
              final cameraZoom = _isWorldShifting ? _shiftScaleAnimation.value : 1.0;

              return Opacity(
                opacity: _sceneController.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: sceneScale * cameraZoom,
                  child: child,
                ),
              );
            },
            child: ArenaSurface(
              enableBreathing: !showModified,
              child: _buildArenaScene(scene),
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildArenaScene(List<GameObject> objects) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final arenaW = constraints.maxWidth;
        final arenaH = constraints.maxHeight;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            ...objects.asMap().entries.map((entry) {
              final index = entry.key;
              final obj = entry.value;

              // Normalized coordinate to pixel conversion
              // Keep within generous arena bounds
              final posX = obj.position.dx * (arenaW - 70) + 10;
              final posY = obj.position.dy * (arenaH - 78) + 12;

              return AnimatedPositioned(
                key: ValueKey(obj.id),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutBack,
                left: posX,
                top: posY,
                child: TactileObject(
                  gameObject: obj,
                  baseSize: 56.0,
                  spawnIndex: index,
                  isSpawning: _isSpawning,
                  showDebugLabel: _showDebug,
                  onTap: () {
                    // Tactile tap feedback on arena object
                  },
                ),
              );
            }),

            // Debug overlay
            if (_showDebug)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Diff: ${_challenge?.difficulty} | Mode: ${_challenge?.mode.name}\nAns: ${_challenge?.correctAnswer}',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAnswerPhase() {
    if (_challenge == null) return const SizedBox();

    final maxTime = _challenge!.answerTime;
    final progress = maxTime > 0 ? (_timeLeft / maxTime).clamp(0.0, 1.0) : 0.0;
    final isLow = progress < 0.25;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = sin(_shakeAnimation.value * pi * 6) * 8 * (1 - _shakeAnimation.value);
        return Transform.translate(
          offset: Offset(_lastAnswerCorrect == false ? shakeOffset : 0, 0),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // Timer Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isLow ? AppColors.error : AppColors.cyan,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Question Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Text(
                _challenge!.question,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
            ),

            const Spacer(),

            // Tactile Answer Buttons
            ..._challenge!.answers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TactileAnswerButton(
                  index: entry.key,
                  text: entry.value,
                  isSelected: _selectedAnswer == entry.key,
                  isCorrect: entry.key == _challenge!.correctAnswerIndex,
                  showResult: _selectedAnswer != null,
                  onTap: () => _onAnswerSelected(entry.key),
                ),
              );
            }),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// Tactile, juicy answer button with spring-press physics and crisp result states
class _TactileAnswerButton extends StatefulWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;

  const _TactileAnswerButton({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.onTap,
  });

  @override
  State<_TactileAnswerButton> createState() => _TactileAnswerButtonState();
}

class _TactileAnswerButtonState extends State<_TactileAnswerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.surfaceLight;
    Color borderColor = AppColors.glassBorder;
    Color textColor = AppColors.textPrimary;
    List<BoxShadow>? shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ];

    if (widget.showResult) {
      if (widget.isCorrect) {
        bgColor = AppColors.success.withValues(alpha: 0.18);
        borderColor = AppColors.success;
        textColor = AppColors.success;
        shadows = [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ];
      } else if (widget.isSelected && !widget.isCorrect) {
        bgColor = AppColors.error.withValues(alpha: 0.18);
        borderColor = AppColors.error;
        textColor = AppColors.error;
        shadows = [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ];
      }
    }

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 2.0 : 1.2,
            ),
            boxShadow: shadows,
          ),
          child: Row(
            children: [
              // Answer Index badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + widget.index),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Answer text
              Expanded(
                child: Text(
                  widget.text,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),

              // Result icon
              if (widget.showResult && widget.isCorrect)
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
              if (widget.showResult && widget.isSelected && !widget.isCorrect)
                const Icon(Icons.cancel_rounded, color: AppColors.error, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter for the Signature World Shift Energy Wave
class _WorldShiftWavePainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0
  _WorldShiftWavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide * 0.75;
    final radius = maxRadius * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    // Expanding Cyan / Violet Energy Wavefront
    final wavePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          AppColors.cyan.withValues(alpha: 0.5 * opacity),
          AppColors.primary.withValues(alpha: 0.7 * opacity),
          Colors.white.withValues(alpha: 0.8 * opacity),
          Colors.transparent,
        ],
        stops: const [0.75, 0.88, 0.95, 0.98, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center, radius, wavePaint);

    // Screen flash at peak
    if (progress < 0.3) {
      final flashOpacity = (1.0 - (progress / 0.3)) * 0.15;
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: flashOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorldShiftWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

enum _GamePhase {
  intro,
  countdown,
  observe,
  modified,
  answer,
}
