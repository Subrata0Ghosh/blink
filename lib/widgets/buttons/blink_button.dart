import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Tactile Premium Button for BLINK
/// Features:
/// - Layered 3D depth with bevel highlight and cast shadow
/// - Inner gradient with ambient cosmic glow
/// - Idle breathing pulse
/// - Press physics (scale down to 0.95, shadow compression, spring-back release)
class BlinkButton extends StatefulWidget {
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
    this.width = 210,
    this.height = 62,
    this.primaryColor = AppColors.primary,
    this.secondaryColor = AppColors.primaryDark,
    this.icon,
  });

  @override
  State<BlinkButton> createState() => _BlinkButtonState();
}

class _BlinkButtonState extends State<BlinkButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _pressController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _pressController.reverse();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressController, _pulseController]),
        builder: (context, child) {
          final scale = _scaleAnim.value;
          final pulse = _pulseAnim.value;
          final shadowOffset = _isPressed ? 2.0 : 6.0;
          final glowBlur = (_isPressed ? 14.0 : 26.0) * pulse;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.primaryColor,
                    widget.secondaryColor,
                  ],
                ),
                boxShadow: [
                  // Outer atmospheric glow
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: (0.45 * pulse).clamp(0.0, 1.0)),
                    blurRadius: glowBlur,
                    spreadRadius: 2,
                    offset: Offset(0, shadowOffset),
                  ),
                  // Bottom physical depth shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 10,
                    offset: Offset(0, shadowOffset + 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: _isPressed ? 0.25 : 0.45),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Top specular highlight band
                  Positioned(
                    top: 1,
                    left: 20,
                    right: 20,
                    height: widget.height * 0.38,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(widget.height / 2)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: GoogleFonts.outfit(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
