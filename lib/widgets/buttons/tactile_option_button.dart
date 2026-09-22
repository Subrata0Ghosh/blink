import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Tactile 3D Option Button for BLINK (matching user reference Image 2)
/// Features:
/// - 4 Cosmic gradient themes: Cyan (A), Purple (B), Green (C), Orange (D)
/// - Full pill-capsule shape with extruded 3D bottom bevel rim
/// - Top specular curved glass sheen highlight
/// - Circular white letter disc (A, B, C, D) with matching theme color text
/// - Bold white option text with drop shadow
/// - Physical push-down press animation with haptic feedback
/// - Visual state feedback for correct/incorrect answers
class TactileOptionButton extends StatefulWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool showResult;
  final bool isCorrect;
  final VoidCallback onTap;
  final double height;

  const TactileOptionButton({
    super.key,
    required this.index,
    required this.text,
    this.isSelected = false,
    this.showResult = false,
    this.isCorrect = false,
    required this.onTap,
    this.height = 54,
  });

  @override
  State<TactileOptionButton> createState() => _TactileOptionButtonState();
}

class _TactileOptionButtonState extends State<TactileOptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pressAnim;

  // The 4 Image 2 Themes: A (Cyan), B (Purple), C (Green), D (Orange)
  static const List<_OptionTheme> _themes = [
    // A — Cyan / Sky Blue
    _OptionTheme(
      faceTop: Color(0xFF4EE2EC),
      faceBottom: Color(0xFF009FC7),
      rim: Color(0xFF006C88),
      letterColor: Color(0xFF007D99),
    ),
    // B — Nebula Purple
    _OptionTheme(
      faceTop: Color(0xFFBD82FB),
      faceBottom: Color(0xFF803AE9),
      rim: Color(0xFF5519A8),
      letterColor: Color(0xFF6E28C8),
    ),
    // C — Emerald Green
    _OptionTheme(
      faceTop: Color(0xFF6EE7A8),
      faceBottom: Color(0xFF16A34A),
      rim: Color(0xFF0F682E),
      letterColor: Color(0xFF15803D),
    ),
    // D — Nova Orange
    _OptionTheme(
      faceTop: Color(0xFFFB9A58),
      faceBottom: Color(0xFFE55D1C),
      rim: Color(0xFF9E380B),
      letterColor: Color(0xFFC2410C),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _pressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themes[widget.index % _themes.length];

    Color faceTop = theme.faceTop;
    Color faceBottom = theme.faceBottom;
    Color rim = theme.rim;
    Color letterColor = theme.letterColor;

    if (widget.showResult) {
      if (widget.isCorrect) {
        faceTop = const Color(0xFF67F573);
        faceBottom = const Color(0xFF169E24);
        rim = const Color(0xFF0F6817);
        letterColor = const Color(0xFF0F6817);
      } else if (widget.isSelected && !widget.isCorrect) {
        faceTop = const Color(0xFFFF6E6E);
        faceBottom = const Color(0xFFD42222);
        rim = const Color(0xFF8A0B0B);
        letterColor = const Color(0xFF8A0B0B);
      }
    }

    final height = widget.height;
    const rimHeight = 5.0;
    final borderRadius = height / 2;
    final letter = String.fromCharCode(65 + widget.index);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (context, _) {
          final t = _pressAnim.value;
          final pushDown = t * (rimHeight - 1);
          final shadowBlur = (6.0 - (t * 3.0)).clamp(1.0, 8.0);
          final shadowOffset = (3.5 - (t * 2.0)).clamp(0.5, 5.0);

          return SizedBox(
            width: double.infinity,
            height: height + rimHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ──── 1. BOTTOM 3D RIM (Extruded Base) ────
                Positioned(
                  top: rimHeight,
                  left: 0,
                  right: 0,
                  height: height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: rim,
                      borderRadius: BorderRadius.circular(borderRadius),
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
                  height: height,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: LinearGradient(
                        colors: [faceTop, faceBottom],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(borderRadius),
                      child: Stack(
                        children: [
                          // 1. Top Specular Highlight Crescent (wide gloss sheen across top)
                          Positioned(
                            top: 1,
                            left: 10,
                            right: 10,
                            height: height * 0.46,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(borderRadius * 0.85),
                                  bottom: const Radius.elliptical(90, 16),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.65),
                                    Colors.white.withValues(alpha: 0.05),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // 2. Right-side Gloss Lens Bubble (matching reference Image 2)
                          Positioned(
                            top: 4,
                            right: 18,
                            width: 100,
                            height: height * 0.44,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.45),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // 3. Inner Content: Circular Badge + Option Text + Result Feedback
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                children: [
                                  // White circular badge with letter (A, B, C, D)
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.22),
                                          blurRadius: 3.5,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        letter,
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: letterColor,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  // Option Text
                                  Expanded(
                                    child: Text(
                                      widget.text,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.4,
                                        shadows: [
                                          Shadow(
                                            color: rim.withValues(alpha: 0.95),
                                            offset: const Offset(0, 2),
                                            blurRadius: 2.5,
                                          ),
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.35),
                                            offset: const Offset(0, 3),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Result Feedback Badges
                                  if (widget.showResult) ...[
                                    const SizedBox(width: 8),
                                    if (widget.isCorrect)
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.check_rounded,
                                            color: Color(0xFF16A34A),
                                            size: 20,
                                          ),
                                        ),
                                      )
                                    else if (widget.isSelected)
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: Color(0xFFD42222),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
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

class _OptionTheme {
  final Color faceTop;
  final Color faceBottom;
  final Color rim;
  final Color letterColor;

  const _OptionTheme({
    required this.faceTop,
    required this.faceBottom,
    required this.rim,
    required this.letterColor,
  });
}
