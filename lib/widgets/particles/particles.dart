import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Animated star field background — creates the cosmic feel
class StarField extends StatefulWidget {
  final int starCount;
  final Widget? child;

  const StarField({super.key, this.starCount = 80, this.child});

  @override
  State<StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<StarField> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _stars = List.generate(widget.starCount, (_) => _Star(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _StarFieldPainter(_stars, _controller.value),
              size: Size.infinite,
            );
          },
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double twinkleSpeed;
  final double twinkleOffset;
  final Color color;

  _Star(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        size = 0.5 + rng.nextDouble() * 2.0,
        twinkleSpeed = 0.5 + rng.nextDouble() * 2.0,
        twinkleOffset = rng.nextDouble() * 2 * pi,
        color = [
          AppColors.textPrimary,
          AppColors.cyan,
          AppColors.primaryLight,
          AppColors.mint,
          AppColors.gold,
        ][rng.nextInt(5)];
}

class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double time;

  _StarFieldPainter(this.stars, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final opacity = 0.3 + 0.7 * ((sin(time * star.twinkleSpeed * 2 * pi + star.twinkleOffset) + 1) / 2);
      final paint = Paint()
        ..color = star.color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.size * 0.5);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter old) => true;
}

/// Spark burst effect — used for correct answers, gem pickups
class SparkBurst extends StatefulWidget {
  final Color color;
  final double size;
  final VoidCallback? onComplete;

  const SparkBurst({
    super.key,
    this.color = AppColors.cyan,
    this.size = 100,
    this.onComplete,
  });

  @override
  State<SparkBurst> createState() => _SparkBurstState();
}

class _SparkBurstState extends State<SparkBurst> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _sparks = List.generate(12, (_) => _Spark(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward().then((_) => widget.onComplete?.call());
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
        return CustomPaint(
          painter: _SparkBurstPainter(
            _sparks,
            _controller.value,
            widget.color,
            widget.size,
          ),
          size: Size(widget.size * 2, widget.size * 2),
        );
      },
    );
  }
}

class _Spark {
  final double angle;
  final double speed;
  final double size;

  _Spark(Random rng)
      : angle = rng.nextDouble() * 2 * pi,
        speed = 0.5 + rng.nextDouble() * 0.5,
        size = 2 + rng.nextDouble() * 3;
}

class _SparkBurstPainter extends CustomPainter {
  final List<_Spark> sparks;
  final double progress;
  final Color color;
  final double maxRadius;

  _SparkBurstPainter(this.sparks, this.progress, this.color, this.maxRadius);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final spark in sparks) {
      final radius = maxRadius * progress * spark.speed;
      final sparkPos = center + Offset(cos(spark.angle) * radius, sin(spark.angle) * radius);
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, spark.size);
      canvas.drawCircle(sparkPos, spark.size * (1.0 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkBurstPainter old) => old.progress != progress;
}

/// Glow pulse effect — used for buttons, gems, and interactive elements
class GlowPulse extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxBlur;
  final Duration duration;

  const GlowPulse({
    super.key,
    required this.child,
    this.glowColor = AppColors.primary,
    this.maxBlur = 20.0,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
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
        final blur = widget.maxBlur * _controller.value;
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.3 + 0.3 * _controller.value),
                blurRadius: blur,
                spreadRadius: blur * 0.3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Energy ring expanding effect — for PERFECT answers
class EnergyRing extends StatefulWidget {
  final Color color;
  final VoidCallback? onComplete;

  const EnergyRing({super.key, this.color = AppColors.cyan, this.onComplete});

  @override
  State<EnergyRing> createState() => _EnergyRingState();
}

class _EnergyRingState extends State<EnergyRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward().then((_) => widget.onComplete?.call());
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
        return CustomPaint(
          painter: _EnergyRingPainter(_controller.value, widget.color),
          size: Size.infinite,
        );
      },
    );
  }
}

class _EnergyRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _EnergyRingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide * 0.6;
    final radius = maxRadius * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final strokeWidth = 3.0 * (1.0 - progress * 0.7);

    final paint = Paint()
      ..color = color.withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * (1.0 - progress));

    canvas.drawCircle(center, radius, paint);

    // Inner glow ring
    final innerPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 3
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawCircle(center, radius * 0.95, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _EnergyRingPainter old) => old.progress != progress;
}

/// Floating particles — ambient background effect
class FloatingParticles extends StatefulWidget {
  final int count;
  final Color color;

  const FloatingParticles({super.key, this.count = 15, this.color = AppColors.primary});

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FloatingDot> _dots;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _dots = List.generate(widget.count, (_) => _FloatingDot(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
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
        return CustomPaint(
          painter: _FloatingParticlesPainter(_dots, _controller.value, widget.color),
          size: Size.infinite,
        );
      },
    );
  }
}

class _FloatingDot {
  final double x;
  final double baseY;
  final double size;
  final double speed;
  final double phase;

  _FloatingDot(Random rng)
      : x = rng.nextDouble(),
        baseY = rng.nextDouble(),
        size = 1.0 + rng.nextDouble() * 3.0,
        speed = 0.3 + rng.nextDouble() * 0.7,
        phase = rng.nextDouble() * 2 * pi;
}

class _FloatingParticlesPainter extends CustomPainter {
  final List<_FloatingDot> dots;
  final double time;
  final Color color;

  _FloatingParticlesPainter(this.dots, this.time, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    for (final dot in dots) {
      final y = dot.baseY + sin(time * dot.speed * 2 * pi + dot.phase) * 0.03;
      final opacity = 0.2 + 0.4 * ((sin(time * 2 * pi * dot.speed + dot.phase) + 1) / 2);
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, dot.size);
      canvas.drawCircle(
        Offset(dot.x * size.width, y * size.height),
        dot.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingParticlesPainter old) => true;
}
