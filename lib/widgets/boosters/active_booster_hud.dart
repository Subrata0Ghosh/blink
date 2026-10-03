import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/booster_model.dart';

/// In-game HUD showing active boosters during gameplay
/// Displays small animated icons for each active booster at the top of the screen
class ActiveBoosterHud extends StatelessWidget {
  final ActiveBoosters activeBoosters;
  final bool secondChanceUsed;
  final bool streakShieldUsed;
  final bool hintUsed;
  final VoidCallback? onHintTap;

  const ActiveBoosterHud({
    super.key,
    required this.activeBoosters,
    this.secondChanceUsed = false,
    this.streakShieldUsed = false,
    this.hintUsed = false,
    this.onHintTap,
  });

  @override
  Widget build(BuildContext context) {
    if (activeBoosters.selected.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: activeBoosters.selected.map((type) {
          final booster = Booster.fromType(type);
          final isUsed = _isUsed(type);
          final isTappable = type == BoosterType.revealHint && !hintUsed;

          return GestureDetector(
            onTap: isTappable ? onHintTap : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isUsed ? 0.35 : 1.0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isUsed
                      ? AppColors.glassWhite
                      : booster.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUsed
                        ? AppColors.glassBorder
                        : booster.color.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: isUsed
                      ? null
                      : [
                          BoxShadow(
                            color: booster.glowColor,
                            blurRadius: 8,
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      booster.icon,
                      style: TextStyle(
                        fontSize: 14,
                        decoration: isUsed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUsed ? 'USED' : _shortLabel(type),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isUsed ? AppColors.textMuted : booster.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isUsed(BoosterType type) {
    switch (type) {
      case BoosterType.secondChance:
        return secondChanceUsed;
      case BoosterType.streakShield:
        return streakShieldUsed;
      case BoosterType.revealHint:
        return hintUsed;
      default:
        return false; // timeFreeze & scoreMultiplier are always-on passives
    }
  }

  String _shortLabel(BoosterType type) {
    switch (type) {
      case BoosterType.timeFreeze:
        return '+3s';
      case BoosterType.secondChance:
        return 'RETRY';
      case BoosterType.revealHint:
        return 'HINT';
      case BoosterType.scoreMultiplier:
        return '2x';
      case BoosterType.streakShield:
        return 'SHIELD';
    }
  }
}

/// Floating booster activation animation — shown when a booster triggers
class BoosterActivationEffect extends StatefulWidget {
  final Booster booster;
  final VoidCallback? onComplete;

  const BoosterActivationEffect({
    super.key,
    required this.booster,
    this.onComplete,
  });

  @override
  State<BoosterActivationEffect> createState() => _BoosterActivationEffectState();
}

class _BoosterActivationEffectState extends State<BoosterActivationEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: widget.booster.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.booster.color.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.booster.glowColor,
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.booster.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    widget.booster.name.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: widget.booster.color,
                      letterSpacing: 1.5,
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
