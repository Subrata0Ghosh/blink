import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/particles/particles.dart';
import '../../widgets/animations/feedback_overlays.dart';
import '../../services/app_review_share_service.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../services/audio_service.dart';
import '../../core/constants/app_assets.dart';

/// Result screen — shows performance, XP, gems with satisfying animations
/// Phase 1 Enhanced: Cinematic reveal, staggered stat cards, animated counters,
/// NEW BEST celebration, and play-again retention hook
class ResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> results;

  const ResultScreen({super.key, required this.results});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _gemController;
  late AnimationController _xpController;
  late AnimationController _buttonsController;
  // Staggered stat card controllers
  late AnimationController _card1Controller;
  late AnimationController _card2Controller;
  late AnimationController _card3Controller;
  late AnimationController _card4Controller;

  late Animation<double> _titleScale;
  late Animation<double> _gemBounce;
  late Animation<double> _xpBarAnim;
  late Animation<double> _buttonsSlide;

  bool _showSparkBurst = false;
  bool _showConfetti = false;
  bool _showNewBest = false;
  bool _showScreenFlash = false;
  bool _isNewBest = false;
  bool _showCounters = false;
  bool _showGemRain = false;

  // Play-again countdown
  int _playAgainCountdown = 5;
  Timer? _countdownTimer;

  int get _score => widget.results['score'] ?? 0;
  int get _xp => widget.results['xp'] ?? 0;
  int get _gems => widget.results['gems'] ?? 0;
  int get _correct => widget.results['correct'] ?? 0;
  int get _total => widget.results['total'] ?? 5;
  int get _combo => widget.results['combo'] ?? 0;

  String get _titleText {
    final accuracy = _total > 0 ? _correct / _total : 0;
    if (accuracy >= 1.0) return 'PERFECT';
    if (accuracy >= 0.8) return 'GREAT';
    if (accuracy >= 0.5) return 'GOOD';
    return 'KEEP GOING';
  }

  Color get _titleColor {
    switch (_titleText) {
      case 'PERFECT':
        return AppColors.cyan;
      case 'GREAT':
        return AppColors.success;
      case 'GOOD':
        return AppColors.gold;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  void initState() {
    super.initState();

    // Main reveal — SLOWED DOWN to 2000ms for cinematic feel
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _titleScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0, 0.35, curve: Curves.elasticOut),
      ),
    );

    // Staggered stat card controllers
    _card1Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _card2Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _card3Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _card4Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _gemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _gemBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gemController, curve: Curves.elasticOut),
    );

    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _xpBarAnim = CurvedAnimation(parent: _xpController, curve: Curves.easeOutCubic);

    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buttonsSlide = CurvedAnimation(parent: _buttonsController, curve: Curves.easeOutCubic);

    // Check for new best score after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final isNew = ref.read(gameStateProvider.notifier).updateBestScore(_score);
        setState(() => _isNewBest = isNew);
      }
    });

    _startRevealSequence();
  }

  final List<Timer> _sequenceTimers = [];

  void _delay(int ms, VoidCallback callback) {
    Timer? timer;
    timer = Timer(Duration(milliseconds: ms), () {
      _sequenceTimers.remove(timer);
      if (mounted) callback();
    });
    _sequenceTimers.add(timer);
  }

  void _startRevealSequence() {
    _delay(300, () {
      _revealController.forward();

      if (_titleText == 'PERFECT') {
        setState(() {
          _showSparkBurst = true;
          _showScreenFlash = true;
          _showConfetti = true;
          _showGemRain = true;
        });
        triggerHaptic(ref, HapticService.perfectAnswer);
        AudioService().playPerfect();
      } else if (_titleText == 'GREAT' || _titleText == 'GOOD') {
        triggerHaptic(ref, HapticService.correctAnswer);
        AudioService().playLevelUp();
      } else {
        triggerHaptic(ref, HapticService.correctAnswer);
        AudioService().playUiConfirm();
      }
    });

    // Stagger stat cards
    _delay(1000, () => _card1Controller.forward());
    _delay(1150, () => _card2Controller.forward());
    _delay(1300, () => _card3Controller.forward());
    _delay(1450, () {
      _card4Controller.forward();
      setState(() => _showCounters = true);
    });

    // Gems bounce in
    _delay(1850, () {
      _gemController.forward();
      triggerHaptic(ref, HapticService.gemPickup);
      if (_gems > 0) {
        AudioService().playGemPickup();
      }
    });

    // XP bar fills
    _delay(2250, () => _xpController.forward());

    // NEW BEST celebration
    _delay(2550, () {
      if (_isNewBest) {
        setState(() {
          _showNewBest = true;
          _showConfetti = true;
          _showGemRain = true;
        });
        triggerHaptic(ref, HapticService.perfectAnswer);
        AudioService().playPerfect();
      }
    });

    // Show buttons
    _delay(2950, () {
      _buttonsController.forward();

      // Start play-again countdown
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _playAgainCountdown--;
          if (_playAgainCountdown <= 0) {
            timer.cancel();
            try {
              context.pushReplacement('/play');
            } catch (_) {}
          }
        });
      });
    });
  }

  @override
  void dispose() {
    for (final t in _sequenceTimers) {
      t.cancel();
    }
    _sequenceTimers.clear();
    _countdownTimer?.cancel();
    _revealController.dispose();
    _gemController.dispose();
    _xpController.dispose();
    _buttonsController.dispose();
    _card1Controller.dispose();
    _card2Controller.dispose();
    _card3Controller.dispose();
    _card4Controller.dispose();
    super.dispose();
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() => _playAgainCountdown = -1);
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);
    final nextUnlockLevel = ((player.level ~/ 5) + 1) * 5;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarField(starCount: 40),
          if (_titleText == 'PERFECT')
            const FloatingParticles(count: 20, color: AppColors.cyan),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 18),

                            // ── Title with camera pulse ──
                            AnimatedBuilder(
                              animation: _titleScale,
                              builder: (context, _) {
                                return Transform.scale(
                                  scale: _titleScale.value,
                                  child: Text(
                                    _titleText,
                                    style: GoogleFonts.outfit(
                                      fontSize: 44,
                                      fontWeight: FontWeight.w900,
                                      color: _titleColor,
                                      letterSpacing: 5,
                                      shadows: [
                                        Shadow(
                                          color: _titleColor.withValues(alpha: 0.6),
                                          blurRadius: 30,
                                        ),
                                        Shadow(
                                          color: _titleColor.withValues(alpha: 0.3),
                                          blurRadius: 60,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 18),

                            // ── Staggered Stats Cards ──
                            Row(
                              children: [
                                Expanded(child: _buildStaggeredStatCard(
                                  _card1Controller, 'ACCURACY',
                                  '${((_correct / _total) * 100).round()}%',
                                  AppColors.success, _showCounters,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStaggeredStatCard(
                                  _card2Controller, 'SCORE',
                                  '$_score',
                                  AppColors.gold, _showCounters,
                                  animateValue: _score,
                                )),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildStaggeredStatCard(
                                  _card3Controller, 'CORRECT',
                                  '$_correct / $_total',
                                  AppColors.cyan, _showCounters,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStaggeredStatCard(
                                  _card4Controller, 'BEST COMBO',
                                  'x$_combo',
                                  AppColors.amber, _showCounters,
                                )),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ── Nova Mascot Reaction ──
                            AnimatedBuilder(
                              animation: _gemBounce,
                              builder: (context, _) {
                                return Transform.scale(
                                  scale: _gemBounce.value,
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_titleText == 'PERFECT' || _titleText == 'GREAT'
                                                  ? AppColors.cyan
                                                  : AppColors.primary)
                                              .withValues(alpha: 0.5),
                                          blurRadius: 20,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        _titleText == 'PERFECT' || _titleText == 'GREAT' || _titleText == 'GOOD'
                                            ? AppAssets.novaHappy
                                            : AppAssets.novaIdle,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            // ── Gems Earned with animated counter ──
                            AnimatedBuilder(
                              animation: _gemBounce,
                              builder: (context, _) {
                                return Transform.scale(
                                  scale: _gemBounce.value,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.gemPurple.withValues(alpha: 0.15),
                                          AppColors.gemCyan.withValues(alpha: 0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.gemCyan.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          AppAssets.shiftGem,
                                          width: 30,
                                          height: 30,
                                        ),
                                        const SizedBox(width: 12),
                                        if (_showCounters)
                                          AnimatedCounter(
                                            value: _gems,
                                            duration: const Duration(milliseconds: 800),
                                            prefix: '+',
                                            style: GoogleFonts.outfit(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.gemCyan,
                                            ),
                                          )
                                        else
                                          Text(
                                            '+$_gems',
                                            style: GoogleFonts.outfit(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.gemCyan,
                                            ),
                                          ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'GEMS',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textMuted,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 14),

                            // ── XP Bar ──
                            AnimatedBuilder(
                              animation: _xpBarAnim,
                              builder: (context, _) {
                                return Opacity(
                                  opacity: _xpBarAnim.value,
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '+$_xp XP',
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.cyan,
                                            ),
                                          ),
                                          Text(
                                            'Level ${player.level}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: player.xpToNextLevel > 0
                                              ? (player.xp / player.xpToNextLevel).clamp(0.0, 1.0)
                                              : 0,
                                          minHeight: 8,
                                          backgroundColor: AppColors.surfaceLight,
                                          valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Next unlock teaser
                                          Text(
                                            '🔓 New content at Lv.$nextUnlockLevel',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary.withValues(alpha: 0.8),
                                            ),
                                          ),
                                          Text(
                                            '${player.xp} / ${player.xpToNextLevel}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 14),
                            const Spacer(),

                            // ── Buttons with slide-up entrance ──
                            AnimatedBuilder(
                              animation: _buttonsSlide,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _buttonsSlide.value.clamp(0.0, 1.0),
                                  child: Transform.translate(
                                    offset: Offset(0, 30 * (1 - _buttonsSlide.value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Next Challenge with optional countdown
                                  TactileButton.cosmic(
                                    label: 'NEXT CHALLENGE',
                                    width: double.infinity,
                                    height: 54,
                                    fontSize: 17,
                                    onTap: () {
                                      _cancelCountdown();
                                      context.pushReplacement('/play');
                                    },
                                  ),
                                  if (_playAgainCountdown > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Auto-starting in ${_playAgainCountdown}s...',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.cyan,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  // Share Score
                                  TactileButton(
                                    label: 'SHARE SCORE',
                                    width: double.infinity,
                                    height: 48,
                                    fontSize: 15,
                                    icon: Icons.share_rounded,
                                    faceColorTop: const Color(0xFF00E5FF),
                                    faceColorBottom: const Color(0xFF0097A7),
                                    rimColor: const Color(0xFF006064),
                                    onTap: () {
                                      triggerHaptic(ref, HapticService.mediumTap);
                                      AppReviewShareService.shareScore(
                                        score: _score,
                                        combo: _combo,
                                        accuracy: ((_correct / _total) * 100).round(),
                                        level: player.level,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  // Return Home
                                  TactileButton.dark(
                                    label: 'RETURN HOME',
                                    width: double.infinity,
                                    height: 48,
                                    fontSize: 15,
                                    onTap: () {
                                      _cancelCountdown();
                                      context.go('/home');
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Overlay Effects ──
          // Screen flash
          if (_showScreenFlash)
            Positioned.fill(
              child: ScreenFlash(
                onComplete: () => setState(() => _showScreenFlash = false),
              ),
            ),
          // Confetti
          if (_showConfetti)
            Positioned.fill(
              child: ConfettiCascade(
                particleCount: 80,
                duration: const Duration(milliseconds: 3000),
                onComplete: () => setState(() => _showConfetti = false),
              ),
            ),
          // Spark burst overlay for PERFECT
          if (_showSparkBurst)
            Center(
              child: SparkBurst(
                color: AppColors.cyan,
                size: 150,
                onComplete: () => setState(() => _showSparkBurst = false),
              ),
            ),
          // NEW BEST banner
          if (_showNewBest)
            Center(
              child: NewBestBanner(
                onComplete: () => setState(() => _showNewBest = false),
              ),
            ),

          // 3D Gem Rain Shower for PERFECT or NEW BEST
          if (_showGemRain)
            Positioned.fill(
              child: GemRainShower(
                onComplete: () => setState(() => _showGemRain = false),
              ),
            ),
        ],
      ),
    );
  }

  /// Staggered stat card with slide-up entrance and optional animated counter
  Widget _buildStaggeredStatCard(
    AnimationController controller,
    String label,
    String value,
    Color color,
    bool showCounter, {
    int? animateValue,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = CurvedAnimation(parent: controller, curve: Curves.easeOutBack).value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (animateValue != null && showCounter)
                    AnimatedCounter(
                      value: animateValue,
                      duration: const Duration(milliseconds: 1500),
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    )
                  else
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
