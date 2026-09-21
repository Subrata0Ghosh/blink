import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'tactile_button.dart';

/// Primary action button for BLINK — Cosmic Cyan 3D tactile button
/// Powered by [TactileButton] with bevel depth, gloss highlight, and spring press physics
class BlinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData? icon;

  const BlinkButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 230,
    this.height = 62,
    this.primaryColor = AppColors.cosmicCyanLight,
    this.secondaryColor = AppColors.cosmicCyanDark,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TactileButton(
      label: label,
      onTap: onTap,
      width: width,
      height: height,
      icon: icon,
      fontSize: 22,
      faceColorTop: primaryColor,
      faceColorBottom: secondaryColor,
      rimColor: AppColors.cosmicCyanRim,
    );
  }
}
