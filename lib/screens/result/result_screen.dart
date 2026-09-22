import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/particles/particles.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../core/constants/app_assets.dart';

/// Result screen — shows performance, XP, gems with satisfying animations
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

  late Animation<double> _titleScale;
  late Animation<double> _statsOpacity;
  late Animation<double> _gemBounce;
  late Animation<double> _xpBarAnim;

  bool _showSparkBurst = false;

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

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _titleScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0, 0.4, curve: Curves.elasticOut),
      ),
    );
    _statsOpacity = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );

    _gemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _gemBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gemController, curve: Curves.elasticOut),
    );

    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _xpBarAnim = CurvedAnimation(parent: _xpController, curve: Curves.easeOutCubic);

    _startRevealSequence();
  }

  void _startRevealSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _revealController.forward();

    if (_titleText == 'PERFECT') {
      setState(() => _showSparkBurst = true);
      triggerHaptic(ref, HapticService.perfectAnswer);
    } else {
      triggerHaptic(ref, HapticService.correctAnswer);
    }

    await Future.delayed(const Duration(milliseconds: 600));
    _gemController.forward();
    triggerHaptic(ref, HapticService.gemPickup);

    await Future.delayed(const Duration(milliseconds: 300));
    _xpController.forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    _gemController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarField(starCount: 40),
          if (_titleText == 'PERFECT')
            const FloatingParticles(count: 20, color: AppColors.cyan),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // ── Title ──
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
                            letterSpacing: 6,
                            shadows: [
                              Shadow(
                                color: _titleColor.withValues(alpha: 0.5),
                                blurRadius: 25,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // ── Stats Cards ──
                  AnimatedBuilder(
                    animation: _statsOpacity,
                    builder: (context, child) {
                      return Opacity(opacity: _statsOpacity.value, child: child);
                    },
                    child: Column(
                      children: [
                        // Accuracy & Score row
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('ACCURACY', '${((_correct / _total) * 100).round()}%', AppColors.success)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('SCORE', '$_score', AppColors.gold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Combo & Correct row
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('CORRECT', '$_correct / $_total', AppColors.cyan)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('BEST COMBO', 'x$_combo', AppColors.amber)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Nova Mascot Reaction ──
                  AnimatedBuilder(
                    animation: _gemBounce,
                    builder: (context, _) {
                      return Transform.scale(
                        scale: _gemBounce.value,
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_titleText == 'PERFECT' || _titleText == 'GREAT'
                                        ? AppColors.cyan
                                        : AppColors.primary)
                                    .withValues(alpha: 0.5),
                                blurRadius: 24,
                                spreadRadius: 4,
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

                  const SizedBox(height: 16),

                  // ── Gems Earned ──
                  AnimatedBuilder(
                    animation: _gemBounce,
                    builder: (context, _) {
                      return Transform.scale(
                        scale: _gemBounce.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                              // 3D Shift Gem
                              Image.asset(
                                AppAssets.shiftGem,
                                width: 34,
                                height: 34,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                '+$_gems',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
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

                  const SizedBox(height: 20),

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
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
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

                  const Spacer(),

                  // ── Buttons ──
                  // Next Challenge
                  TactileButton.cosmic(
                    label: 'NEXT CHALLENGE',
                    width: double.infinity,
                    height: 58,
                    fontSize: 18,
                    onTap: () => context.pushReplacement('/play'),
                  ),
                  const SizedBox(height: 14),
                  // Return Home
                  TactileButton.dark(
                    label: 'RETURN HOME',
                    width: double.infinity,
                    height: 50,
                    fontSize: 15,
                    onTap: () => context.go('/home'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
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
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
