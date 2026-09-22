import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../gameplay/challenge_engine/challenge_engine.dart';
import '../../gameplay/challenge_engine/game_objects.dart';
import '../../gameplay/rendering/arena_surface.dart';
import '../../gameplay/rendering/tactile_object.dart';
import '../../gameplay/rendering/radial_energy_timer.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/buttons/tactile_option_button.dart';
import '../../widgets/particles/particles.dart';
import '../../services/audio_service.dart';
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
      AudioService().playUiConfirm();

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
        AudioService().playPerfect();
      } else {
        AudioService().playCorrect();
      }
      if (_combo > 1) {
        AudioService().playCombo();
      }

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
      AudioService().playWrong();
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
          // Deep cosmic space gradient backdrop
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.3,
                  colors: [
                    Color(0xFF161B38), // Subtle nebula center
                    Color(0xFF0F1328), // Mid depth
                    AppColors.background, // Deep space black
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: StarField(starCount: 30),
          ),

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

          // Celebration Banner Overlay (PERFECT! / COSMIC SHIFT!)
          if (_showPerfect || (_lastAnswerCorrect == true && _phase == _GamePhase.answer))
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1.1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(color: AppColors.glassBorder, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        _showPerfect ? 'COSMIC SHIFT!' : 'PERFECT!',
                        style: GoogleFonts.outfit(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cyan,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: AppColors.cyan.withValues(alpha: 0.6),
                              offset: const Offset(0, 0),
                              blurRadius: 12,
                            ),
                            const Shadow(
                              color: Color(0xFF001830),
                              offset: Offset(0, 3),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                onEnd: () {
                  Future.delayed(const Duration(milliseconds: 700), () {
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
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Close Button
          TactileButton.close(
            size: 40,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/world');
              }
            },
          ),

          const SizedBox(width: 12),

          // Round Indicator
          GestureDetector(
            onTap: _handleRoundTapForDebug,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _showDebug ? 'DEBUG ROUND $_round / 5' : 'ROUND $_round / 5',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.0,
                  ),
                ),
                if (_combo > 1)
                  Text(
                    'Combo x$_combo 🔥',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(),

          // Star progress meter (3 stars)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final earned = i < (_round > 1 ? min(3, (_correctCount * 3 / 5).ceil()) : 0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  earned ? Icons.star_rounded : Icons.star_border_rounded,
                  color: earned ? AppColors.gold : AppColors.textMuted.withValues(alpha: 0.5),
                  size: 24,
                  shadows: earned
                      ? [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),

          const SizedBox(width: 8),

          // Companion Nova avatar (Transparent, reactive on tap)
          GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    AppAssets.novaIdle,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.visibility_rounded,
                      color: AppColors.cyan,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            // Timer Bar in Cosmic Glass Capsule
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                ),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isLow ? AppColors.dangerRed : AppColors.cosmicCyan,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Question Box in Cosmic Glass Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.12),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _challenge!.question,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                  height: 1.25,
                ),
              ),
            ),

            const Spacer(),

            // Tactile 3D Candy Answer Buttons (matching Image 2)
            ..._challenge!.answers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TactileOptionButton(
                  index: entry.key,
                  text: entry.value,
                  isSelected: _selectedAnswer == entry.key,
                  isCorrect: entry.key == _challenge!.correctAnswerIndex,
                  showResult: _selectedAnswer != null,
                  height: 54,
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
