import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';

/// Single flying gem particle with Bezier trajectory
class _FlyingGem {
  final Offset start;
  final Offset control;
  final Offset end;
  final double delay;
  final double duration;
  final double scale;
  final Color color;
  final String iconEmoji;

  _FlyingGem({
    required this.start,
    required this.control,
    required this.end,
    required this.delay,
    required this.duration,
    required this.scale,
    required this.color,
    required this.iconEmoji,
  });

  Offset getPosition(double t) {
    // Quadratic Bezier: B(t) = (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
    final u = 1.0 - t;
    final tt = t * t;
    final uu = u * u;
    final ut2 = 2 * u * t;

    return Offset(
      uu * start.dx + ut2 * control.dx + tt * end.dx,
      uu * start.dy + ut2 * control.dy + tt * end.dy,
    );
  }
}

/// Flying Reward Animation Controller & Overlay
/// Physically connects in-game finger actions to the top status HUD by animating
/// 3D gems / XP spores along parabolic arcs from touch location to HUD.
class FlyingRewardOverlay extends StatefulWidget {
  final Offset startPosition;
  final Offset targetPosition;
  final int count;
  final String emoji;
  final Color color;
  final VoidCallback onComplete;

  const FlyingRewardOverlay({
    super.key,
    required this.startPosition,
    required this.targetPosition,
    this.count = 8,
    this.emoji = '💎',
    this.color = AppColors.gemCyan,
    required this.onComplete,
  });

  /// Static helper to trigger flying rewards across any BuildContext overlay
  static OverlayEntry? show({
    required BuildContext context,
    required Offset startPosition,
    required Offset targetPosition,
    int count = 8,
    String emoji = '💎',
    Color color = AppColors.gemCyan,
    VoidCallback? onComplete,
  }) {
    final overlayState = Overlay.of(context);
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => FlyingRewardOverlay(
        startPosition: startPosition,
        targetPosition: targetPosition,
        count: count,
        emoji: emoji,
        color: color,
        onComplete: () {
          entry?.remove();
          onComplete?.call();
        },
      ),
    );

    overlayState.insert(entry);
    return entry;
  }

  @override
  State<FlyingRewardOverlay> createState() => _FlyingRewardOverlayState();
}

class _FlyingRewardOverlayState extends State<FlyingRewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_FlyingGem> _gems = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _generateGems();

    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });

    // Sound effects staggered with gem arrivals
    Future.delayed(const Duration(milliseconds: 400), () {
      AudioService().playGemPickup();
    });
  }

  void _generateGems() {
    for (int i = 0; i < widget.count; i++) {
      // Randomized initial explosion offset
      final blastAngle = _rng.nextDouble() * 2 * pi;
      final blastRadius = 30 + _rng.nextDouble() * 50;
      final blastPoint = widget.startPosition +
          Offset(cos(blastAngle) * blastRadius, sin(blastAngle) * blastRadius);

      // Arc control point pulls outward for a dramatic fountain arc
      final midX = (blastPoint.dx + widget.targetPosition.dx) / 2;
      final midY = min(blastPoint.dy, widget.targetPosition.dy) - (60 + _rng.nextDouble() * 80);
      final controlPoint = Offset(midX + (_rng.nextDouble() - 0.5) * 80, midY);

      _gems.add(
        _FlyingGem(
          start: blastPoint,
          control: controlPoint,
          end: widget.targetPosition,
          delay: i * 0.04, // staggered flight
          duration: 0.65 + _rng.nextDouble() * 0.15,
          scale: 0.8 + _rng.nextDouble() * 0.4,
          color: widget.color,
          iconEmoji: widget.emoji,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final overallProgress = _controller.value;

          return Stack(
            children: _gems.map((gem) {
              if (overallProgress < gem.delay) return const SizedBox();

              final gemProgress = ((overallProgress - gem.delay) / gem.duration).clamp(0.0, 1.0);
              if (gemProgress >= 1.0) return const SizedBox();

              // Smooth accelerating cubic curve for realistic gravity & magnetic suction
              final curvedT = Curves.easeInOutCubic.transform(gemProgress);
              final pos = gem.getPosition(curvedT);

              // Scale dynamic: grows on burst, compresses on impact into target
              final scale = gemProgress < 0.2
                  ? (gemProgress / 0.2) * gem.scale
                  : (1.0 - gemProgress * 0.3) * gem.scale;

              return Positioned(
                left: pos.dx - 14,
                top: pos.dy - 14,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: gem.color.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        gem.iconEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
