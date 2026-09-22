import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/audio_service.dart';

/// Tactile 3D Jelly Switch for BLINK
/// Matches the high-gloss casual game toggle style shown in reference designs:
/// - Inset pill track with subtle engraved status icon (checkmark / cross)
/// - Glossy 3D pearl thumb with physical drop shadow and specular reflection
/// - Physical sliding animation with haptic feedback
class TactileJellySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;
  final Color activeTrackColor;
  final Color inactiveTrackColor;

  const TactileJellySwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 54,
    this.height = 30,
    this.activeTrackColor = const Color(0xFF8CD836), // Juicy fresh lime green
    this.inactiveTrackColor = const Color(0xFF232B45), // Slate muted
  });

  @override
  Widget build(BuildContext context) {
    final thumbSize = height - 4;
    final trackRadius = height / 2;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        AudioService().playUiClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: value ? activeTrackColor : inactiveTrackColor,
          borderRadius: BorderRadius.circular(trackRadius),
          border: Border.all(
            color: value
                ? const Color(0xFFA6EC4C)
                : const Color(0xFF374366),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 2),
              blurRadius: 3,
              spreadRadius: -1,
            ),
            if (value)
              BoxShadow(
                color: activeTrackColor.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Embedded status indicator icon
            Positioned(
              left: value ? 9 : null,
              right: value ? null : 9,
              child: Icon(
                value ? Icons.check_rounded : Icons.close_rounded,
                size: 14,
                color: value
                    ? const Color(0xFF2C660B)
                    : const Color(0xFF5D6C96),
              ),
            ),

            // Sliding 3D Pearl Thumb
            AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.35, -0.4),
                      radius: 0.85,
                      colors: [
                        Colors.white,
                        Color(0xFFF0F4FC),
                        Color(0xFFC8D3E6),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Specular shine on thumb
                      Positioned(
                        top: 3,
                        left: 5,
                        child: Container(
                          width: 7,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
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
      ),
    );
  }
}
