import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../services/app_review_share_service.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../buttons/tactile_button.dart';

/// 3D Tactile Rate Us modal with glowing interactive stars and +50 gems reward
class RateAppModal extends ConsumerStatefulWidget {
  final VoidCallback? onRewardClaimed;

  const RateAppModal({super.key, this.onRewardClaimed});

  @override
  ConsumerState<RateAppModal> createState() => _RateAppModalState();
}

class _RateAppModalState extends ConsumerState<RateAppModal> with SingleTickerProviderStateMixin {
  int _selectedStars = 5;
  final Set<String> _selectedTags = {'Fun Gameplay', 'Glow Visuals'};
  bool _submitted = false;

  final List<String> _tags = [
    'Fun Gameplay',
    'Glow Visuals',
    'Tactile Sounds',
    'Brain Booster',
    'Offline Duel',
    'Relaxing Zen',
  ];

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    AudioService().playUiConfirm();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    switch (_selectedStars) {
      case 5:
        return 'Astronomical! 🌟';
      case 4:
        return 'Cosmic! ✨';
      case 3:
        return 'Good Observation! 🚀';
      case 2:
        return 'Needs Tuning 🔭';
      default:
        return 'Tell Us More 💭';
    }
  }

  Future<void> _submitRating() async {
    triggerHaptic(ref, HapticService.gemPickup);
    AudioService().playLevelUp();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppReviewShareService.keyHasRated, true);
    await prefs.setInt(AppReviewShareService.keyRatingValue, _selectedStars);

    // Give 50 Gems reward to player
    ref.read(gameStateProvider.notifier).addGems(50);

    setState(() => _submitted = true);

    // If 4 or 5 stars, redirect to Google Play
    if (_selectedStars >= 4) {
      await Future.delayed(const Duration(milliseconds: 800));
      await AppReviewShareService.openStorePage();
    }

    widget.onRewardClaimed?.call();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          decoration: BoxDecoration(
            color: const Color(0xFF13182B),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.25),
                blurRadius: 28,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Close and Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(AppAssets.shiftGem, width: 18, height: 18),
                        const SizedBox(width: 6),
                        Text(
                          '+50 GEMS BONUS',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cyan,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TactileButton.circle(
                    size: 34,
                    faceColorTop: const Color(0xFF2E3B5E),
                    faceColorBottom: const Color(0xFF1B233A),
                    rimColor: const Color(0xFF0F1524),
                    onTap: () {
                      AudioService().playUiBack();
                      Navigator.of(context).pop();
                    },
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                'Enjoying BLINK?',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your rating fuels Nova and unlocks fresh cosmic challenges!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // 5 Interactive Glowing 3D Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  final isSelected = starNum <= _selectedStars;
                  return GestureDetector(
                    onTap: () {
                      triggerHaptic(ref, HapticService.lightTap);
                      AudioService().playGemPickup();
                      setState(() => _selectedStars = starNum);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Transform.scale(
                        scale: isSelected ? 1.15 : 1.0,
                        child: Icon(
                          isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 38,
                          color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF45557E),
                          shadows: isSelected
                              ? [
                                  const Shadow(
                                    color: Color(0xFFFFB700),
                                    blurRadius: 16,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 12),

              // Dynamic Reaction Text
              Text(
                _ratingLabel,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFFD700),
                ),
              ),

              const SizedBox(height: 18),

              // Feedback tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _tags.map((tag) {
                  final active = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      triggerHaptic(ref, HapticService.lightTap);
                      setState(() {
                        if (active) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.cyan.withValues(alpha: 0.25)
                            : const Color(0xFF1E2844),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: active
                              ? AppColors.cyan
                              : const Color(0xFF33436B),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              // Submit & Claim Reward Button
              TactileButton.cosmic(
                label: _submitted ? 'CLAIMED +50 GEMS! ✨' : 'SUBMIT & GET +50 GEMS',
                height: 52,
                fontSize: 15,
                width: double.infinity,
                onTap: _submitted ? () {} : () { _submitRating(); },
              ),

              const SizedBox(height: 10),

              // Maybe later button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    'Maybe Later',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
