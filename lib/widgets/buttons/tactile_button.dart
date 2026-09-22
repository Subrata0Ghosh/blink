import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';

/// Premium Tactile 3D Button for BLINK
/// Features:
/// - Distinct 3D darker bottom rim (extruded bevel depth)
/// - Saturated glossy face gradient
/// - Top specular reflection / white glass sheen
/// - Chubby text with deep drop shadow
/// - Physical press physics (translates down into rim, compresses shadow)
/// - Tactile haptic feedback
class TactileButton extends StatefulWidget {
  final String? label;
  final Widget? child;
  final VoidCallback onTap;
  final double? width;
  final double height;
  final Color faceColorTop;
  final Color faceColorBottom;
  final Color rimColor;
  final Color textColor;
  final IconData? icon;
  final double borderRadius;
  final double fontSize;
  final double rimHeight;
  final bool isRound;

  const TactileButton({
    super.key,
    this.label,
    this.child,
    required this.onTap,
    this.width,
    this.height = 56,
    required this.faceColorTop,
    required this.faceColorBottom,
    required this.rimColor,
    this.textColor = Colors.white,
    this.icon,
    this.borderRadius = 30,
    this.fontSize = 20,
    this.rimHeight = 6,
    this.isRound = false,
  });

  /// Cosmic Cyan — Primary action (Play, Confirm)
  factory TactileButton.cosmic({
    Key? key,
    required String label,
    required VoidCallback onTap,
    double? width,
    double height = 62,
    IconData? icon,
    double fontSize = 22,
  }) {
    return TactileButton(
      key: key,
      label: label,
      onTap: onTap,
      width: width,
      height: height,
      faceColorTop: AppColors.cosmicCyanLight,
      faceColorBottom: AppColors.cosmicCyanDark,
      rimColor: AppColors.cosmicCyanRim,
      icon: icon,
      fontSize: fontSize,
      borderRadius: height / 2,
    );
  }

  /// Nebula Purple — Secondary action (Map, Navigate)
  factory TactileButton.nebula({
    Key? key,
    required String label,
    required VoidCallback onTap,
    double? width,
    double height = 52,
    IconData? icon,
    double fontSize = 18,
  }) {
    return TactileButton(
      key: key,
      label: label,
      onTap: onTap,
      width: width,
      height: height,
      faceColorTop: AppColors.nebulaPurpleLight,
      faceColorBottom: AppColors.nebulaPurpleDark,
      rimColor: AppColors.nebulaPurpleRim,
      icon: icon,
      fontSize: fontSize,
      borderRadius: height / 2,
    );
  }

  /// Solar Gold — Rewards, Premium
  factory TactileButton.solar({
    Key? key,
    required String label,
    required VoidCallback onTap,
    double? width,
    double height = 52,
    IconData? icon,
    double fontSize = 18,
  }) {
    return TactileButton(
      key: key,
      label: label,
      onTap: onTap,
      width: width,
      height: height,
      faceColorTop: AppColors.solarGoldLight,
      faceColorBottom: AppColors.solarGoldDark,
      rimColor: AppColors.solarGoldRim,
      textColor: const Color(0xFF3D2800),
      icon: icon,
      fontSize: fontSize,
      borderRadius: height / 2,
    );
  }

  /// Stellar Green — Success, Correct
  factory TactileButton.stellar({
    Key? key,
    required String label,
    required VoidCallback onTap,
    double? width,
    double height = 52,
    IconData? icon,
    double fontSize = 18,
  }) {
    return TactileButton(
      key: key,
      label: label,
      onTap: onTap,
      width: width,
      height: height,
      faceColorTop: AppColors.stellarGreenLight,
      faceColorBottom: AppColors.stellarGreenDark,
      rimColor: AppColors.stellarGreenRim,
      icon: icon,
      fontSize: fontSize,
      borderRadius: height / 2,
    );
  }

  /// Nova Orange — Warm accent, Events
  factory TactileButton.nova({
    Key? key,
    required String label,
    required VoidCallback onTap,
    double? width,
    double height = 52,
    IconData? icon,
    double fontSize = 18,
  }) {
    return TactileButton(
      key: key,
      label: label,
      onTap: onTap,
      width: width,
      height: height,
      faceColorTop: AppColors.novaOrangeLight,
      faceColorBottom: AppColors.novaOrangeDark,
      rimColor: AppColors.novaOrangeRim,
      icon: icon,
      fontSize: fontSize,
      borderRadius: height / 2,
    );
  }

  /// Danger Red — Error, Destructive
  factory TactileButton.danger({
    Key? key,
    required String label,
    required VoidCallback onTap,
    double? width,
    double height = 52,
    IconData? icon,
    double fontSize = 18,
  }) {
    return TactileButton(
      key: key,
      label: label,
      onTap: onTap,
      width: width,
      height: height,
      faceColorTop: AppColors.dangerRedLight,
      faceColorBottom: AppColors.dangerRedDark,
      rimColor: AppColors.dangerRedRim,
      icon: icon,
      fontSize: fontSize,
      borderRadius: height / 2,
    );
  }

  /// Dark slate / metallic 3D button (for secondary/neutral actions)
  factory TactileButton.dark({
    Key? key,
    required String label,
    required VoidCallback onTap,
    double? width,
    double height = 50,
    IconData? icon,
    double fontSize = 16,
  }) {
    return TactileButton(
      key: key,
      label: label,
      onTap: onTap,
      width: width,
      height: height,
      faceColorTop: const Color(0xFF2C3554),
      faceColorBottom: const Color(0xFF171E33),
      rimColor: const Color(0xFF0C101E),
      textColor: AppColors.textPrimary,
      icon: icon,
      fontSize: fontSize,
      borderRadius: height / 2,
    );
  }

  /// Circular 3D button for icons (Settings, Close, etc.)
  factory TactileButton.circle({
    Key? key,
    required Widget child,
    required VoidCallback onTap,
    double size = 48,
    Color faceColorTop = AppColors.cosmicCyanLight,
    Color faceColorBottom = AppColors.cosmicCyanDark,
    Color rimColor = AppColors.cosmicCyanRim,
  }) {
    return TactileButton(
      key: key,
      onTap: onTap,
      width: size,
      height: size,
      faceColorTop: faceColorTop,
      faceColorBottom: faceColorBottom,
      rimColor: rimColor,
      borderRadius: size / 2,
      rimHeight: 4,
      isRound: true,
      child: child,
    );
  }

  /// Circular 3D Close / Cross Button (matching Image 2)
  factory TactileButton.close({
    Key? key,
    required VoidCallback onTap,
    double size = 42,
    Color? iconColor,
  }) {
    return TactileButton.circle(
      key: key,
      size: size,
      onTap: onTap,
      faceColorTop: const Color(0xFF2A3452),
      faceColorBottom: const Color(0xFF141A2D),
      rimColor: const Color(0xFF090D18),
      child: Icon(
        Icons.close_rounded,
        color: iconColor ?? Colors.white.withValues(alpha: 0.9),
        size: size * 0.52,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            offset: const Offset(0, 1.5),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pressOffsetAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _pressOffsetAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _controller.forward();
    HapticFeedback.lightImpact();
    AudioService().playUiClick();
  }

  void _handleTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = widget.isRound ? widget.height : widget.width;
    final totalHeight = widget.height + widget.rimHeight;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pressOffsetAnim,
        builder: (context, child) {
          final t = _pressOffsetAnim.value;
          final pushDown = t * (widget.rimHeight - 1);
          final shadowBlur = (6.0 - (t * 3.0)).clamp(1.0, 10.0);
          final shadowOffset = (4.0 - (t * 2.5)).clamp(0.5, 6.0);

          return SizedBox(
            width: effectiveWidth,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ──── 1. BOTTOM 3D RIM (Extruded Base) ────
                Positioned(
                  top: widget.rimHeight,
                  left: 0,
                  right: 0,
                  height: widget.height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.rimColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.38),
                          blurRadius: shadowBlur,
                          offset: Offset(0, shadowOffset),
                        ),
                      ],
                    ),
                  ),
                ),

                // ──── 2. TOP GLOSSY FACE (Moves down on press) ────
                Positioned(
                  top: pushDown,
                  left: 0,
                  right: 0,
                  height: widget.height,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.faceColorTop,
                          widget.faceColorBottom,
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Top Specular Highlight Crescent (Glossy sheen)
                          Positioned(
                            top: 1.5,
                            left: widget.isRound ? widget.height * 0.16 : 8,
                            right: widget.isRound ? widget.height * 0.16 : 8,
                            height: widget.height * (widget.isRound ? 0.42 : 0.45),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: widget.isRound
                                    ? BorderRadius.all(Radius.elliptical(widget.height * 0.35, widget.height * 0.18))
                                    : BorderRadius.vertical(
                                        top: Radius.circular(widget.borderRadius * 0.8),
                                        bottom: const Radius.elliptical(60, 12),
                                      ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: widget.isRound ? 0.65 : 0.55),
                                    Colors.white.withValues(alpha: 0.05),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Inner Content (Label / Icon / Custom child)
                          Center(
                            child: widget.child ??
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (widget.icon != null) ...[
                                      Icon(
                                        widget.icon,
                                        color: widget.textColor,
                                        size: widget.fontSize * 1.15,
                                        shadows: [
                                          Shadow(
                                            color: widget.rimColor.withValues(alpha: 0.8),
                                            offset: const Offset(0, 2),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (widget.label != null)
                                      Text(
                                        widget.label!,
                                        style: GoogleFonts.outfit(
                                          fontSize: widget.fontSize,
                                          fontWeight: FontWeight.w800,
                                          color: widget.textColor,
                                          letterSpacing: 1.2,
                                          shadows: [
                                            Shadow(
                                              color: widget.rimColor.withValues(alpha: 0.95),
                                              offset: const Offset(0, 2.2),
                                              blurRadius: 3,
                                            ),
                                            Shadow(
                                              color: Colors.black.withValues(alpha: 0.35),
                                              offset: const Offset(0, 3.5),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
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
        },
      ),
    );
  }
}
