import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tactile 3D Jelly Slider for BLINK
/// Inspired by casual hit tactile games:
/// - Sunken capsule track with inner depth and vibrant gradient fill
/// - Glossy 3D spherical gem thumb with specular shine and drop shadow
/// - Smooth elastic bounce on touch & drag
class TactileJellySlider extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final Color activeColorStart;
  final Color activeColorEnd;
  final Color thumbColor;
  final double height;
  final double trackHeight;

  const TactileJellySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.activeColorStart = const Color(0xFF38E5FE),
    this.activeColorEnd = const Color(0xFF0091FF),
    this.thumbColor = const Color(0xFF00B0FF),
    this.height = 42,
    this.trackHeight = 14,
  });

  @override
  State<TactileJellySlider> createState() => _TactileJellySliderState();
}

class _TactileJellySliderState extends State<TactileJellySlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _updatePosition(double localDx, double width) {
    const double thumbRadius = 16.0;
    final double trackWidth = max(1.0, width - thumbRadius * 2);
    final double clampedDx = (localDx - thumbRadius).clamp(0.0, trackWidth);
    final double newVal = (clampedDx / trackWidth).clamp(0.0, 1.0);
    if ((newVal - widget.value).abs() > 0.005) {
      widget.onChanged(newVal);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double thumbSize = 32.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final trackWidth = totalWidth - thumbSize;
        final thumbOffset = (widget.value.clamp(0.0, 1.0) * trackWidth);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            _bounceController.forward();
            HapticFeedback.selectionClick();
            _updatePosition(details.localPosition.dx, totalWidth);
          },
          onHorizontalDragUpdate: (details) {
            _updatePosition(details.localPosition.dx, totalWidth);
          },
          onHorizontalDragEnd: (details) {
            _bounceController.reverse();
            widget.onChangeEnd?.call(widget.value);
          },
          onTapDown: (details) {
            _bounceController.forward();
            HapticFeedback.lightImpact();
            _updatePosition(details.localPosition.dx, totalWidth);
          },
          onTapUp: (details) {
            _bounceController.reverse();
            widget.onChangeEnd?.call(widget.value);
          },
          onTapCancel: () {
            _bounceController.reverse();
          },
          child: SizedBox(
            height: widget.height,
            width: totalWidth,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 1. Sunken Base Track
                Container(
                  height: widget.trackHeight,
                  margin: const EdgeInsets.symmetric(horizontal: thumbSize / 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B30),
                    borderRadius: BorderRadius.circular(widget.trackHeight / 2),
                    border: Border.all(color: const Color(0xFF2E385D), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        offset: Offset(0, 2),
                        blurRadius: 3,
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                ),

                // 2. Active Filled Track Gradient
                Positioned(
                  left: thumbSize / 2,
                  child: Container(
                    height: widget.trackHeight,
                    width: max(0.0, thumbOffset),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(widget.trackHeight / 2),
                        right: Radius.circular(
                          thumbOffset > trackWidth - 4 ? widget.trackHeight / 2 : 2,
                        ),
                      ),
                      gradient: LinearGradient(
                        colors: [widget.activeColorStart, widget.activeColorEnd],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.activeColorStart.withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Glossy 3D Jelly Gem Thumb
                Positioned(
                  left: thumbOffset,
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.35, -0.4),
                          radius: 0.85,
                          colors: [
                            Colors.white,
                            widget.thumbColor,
                            Color.lerp(widget.thumbColor, Colors.black, 0.45)!,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.65),
                            offset: const Offset(0, 4),
                            blurRadius: 6,
                          ),
                          BoxShadow(
                            color: widget.thumbColor.withValues(alpha: 0.55),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Top specular gloss spot
                          Positioned(
                            top: 4,
                            left: 7,
                            child: Container(
                              width: 10,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(5),
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
      },
    );
  }
}
