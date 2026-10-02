import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Achievement definition
class Achievement {
  final String id;
  final String icon;
  final String title;
  final String subtitle;
  final int gemReward;

  const Achievement({
    required this.id,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.gemReward = 10,
  });
}

/// Predefined achievements
class Achievements {
  static const firstPerfect = Achievement(
    id: 'first_perfect',
    icon: '⭐',
    title: 'First Perfect!',
    subtitle: 'Scored a perfect round',
    gemReward: 25,
  );

  static const combo3 = Achievement(
    id: 'combo_3',
    icon: '🔥',
    title: 'Hot Streak!',
    subtitle: '3-combo streak',
    gemReward: 15,
  );

  static const combo5 = Achievement(
    id: 'combo_5',
    icon: '💥',
    title: 'Unstoppable!',
    subtitle: '5-combo streak',
    gemReward: 30,
  );

  static const combo10 = Achievement(
    id: 'combo_10',
    icon: '🌟',
    title: 'LEGENDARY!',
    subtitle: '10-combo streak',
    gemReward: 50,
  );

  static const sharpEyes = Achievement(
    id: 'sharp_eyes',
    icon: '👁️',
    title: 'Sharp Eyes!',
    subtitle: '5 perfects in a row',
    gemReward: 40,
  );

  static const speedDemon = Achievement(
    id: 'speed_demon',
    icon: '⚡',
    title: 'Speed Demon!',
    subtitle: 'Answered under 1 second',
    gemReward: 20,
  );

  static const tenGames = Achievement(
    id: 'ten_games',
    icon: '🎮',
    title: 'Dedicated Player!',
    subtitle: 'Played 10 games',
    gemReward: 30,
  );

  static const level5 = Achievement(
    id: 'level_5',
    icon: '🚀',
    title: 'Rising Star!',
    subtitle: 'Reached Level 5',
    gemReward: 50,
  );

  static const level10 = Achievement(
    id: 'level_10',
    icon: '🌌',
    title: 'Cosmic Explorer!',
    subtitle: 'Reached Level 10',
    gemReward: 100,
  );

  static const all = [
    firstPerfect,
    combo3,
    combo5,
    combo10,
    sharpEyes,
    speedDemon,
    tenGames,
    level5,
    level10,
  ];
}

/// Animated achievement popup that slides in from the top
class AchievementPopup extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onComplete;

  const AchievementPopup({
    super.key,
    required this.achievement,
    this.onComplete,
  });

  @override
  State<AchievementPopup> createState() => _AchievementPopupState();
}

class _AchievementPopupState extends State<AchievementPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideY;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _slideY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: -1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 20,
      ),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.7, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.8),
        weight: 20,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete?.call());
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
      builder: (context, _) {
        return Positioned(
          top: 80 + (_slideY.value * 120),
          left: 24,
          right: 24,
          child: IgnorePointer(
            child: Opacity(
              opacity: _opacity.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: _scale.value.clamp(0.0, 2.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.surface.withValues(alpha: 0.95),
                        AppColors.backgroundLight.withValues(alpha: 0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Achievement icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.achievement.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Title + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🏆 ACHIEVEMENT UNLOCKED',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.achievement.title,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (widget.achievement.subtitle.isNotEmpty)
                              Text(
                                widget.achievement.subtitle,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Gem reward
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.gemPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gemCyan.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '+${widget.achievement.gemReward} 💎',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gemCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
