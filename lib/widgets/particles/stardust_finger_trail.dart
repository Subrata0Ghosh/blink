import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A glowing stardust particle trailing behind the player's finger
class _StardustParticle {
  Offset position;
  Offset velocity;
  double radius;
  double opacity;
  final Color color;
  final double maxLife;
  double life;

  _StardustParticle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
    required this.maxLife,
  })  : opacity = 1.0,
        life = maxLife;

  bool update(double dt) {
    life -= dt;
    if (life <= 0) return false;
    position += velocity * dt;
    opacity = (life / maxLife).clamp(0.0, 1.0);
    radius = max(0.5, radius * 0.96);
    return true;
  }
}

/// A cosmic ripple shockwave ring expanding from a finger tap
class _TouchRipple {
  final Offset origin;
  double radius;
  final double maxRadius;
  double opacity;
  final Color color;

  _TouchRipple({
    required this.origin,
    required this.color,
  })  : radius = 4.0,
        maxRadius = 52.0,
        opacity = 0.8;

  bool update(double dt) {
    radius += 180.0 * dt;
    opacity = (1.0 - (radius / maxRadius)).clamp(0.0, 1.0);
    return radius < maxRadius;
  }
}

/// Interactive Stardust Finger Trail & Touch Ripple Overlay
/// Wraps any screen or widget and paints ethereal cosmic trails and ripple rings
/// directly under the player's fingertips without intercepting underlying touch events.
class StardustFingerTrail extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Color? primaryColor;
  final Color? secondaryColor;

  const StardustFingerTrail({
    super.key,
    required this.child,
    this.enabled = true,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<StardustFingerTrail> createState() => _StardustFingerTrailState();
}

class _StardustFingerTrailState extends State<StardustFingerTrail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final List<_StardustParticle> _particles = [];
  final List<_TouchRipple> _ripples = [];
  final Random _rng = Random();

  DateTime _lastFrameTime = DateTime.now();
  Offset? _lastPointerPosition;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _ticker.addListener(_onTick);
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    super.dispose();
  }

  void _onTick() {
    final now = DateTime.now();
    final dt = (now.difference(_lastFrameTime).inMicroseconds / 1000000.0).clamp(0.001, 0.05);
    _lastFrameTime = now;

    if (_particles.isEmpty && _ripples.isEmpty) return;

    setState(() {
      _particles.removeWhere((p) => !p.update(dt));
      _ripples.removeWhere((r) => !r.update(dt));
    });
  }

  void _spawnParticles(Offset pos, {bool isTap = false}) {
    if (!widget.enabled) return;

    final primary = widget.primaryColor ?? AppColors.cyan;
    final secondary = widget.secondaryColor ?? AppColors.primary;
    final count = isTap ? 10 : 3;

    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = isTap ? (40 + _rng.nextDouble() * 120) : (15 + _rng.nextDouble() * 45);
      final velocity = Offset(cos(angle) * speed, sin(angle) * speed);
      final color = _rng.nextBool()
          ? primary
          : (_rng.nextBool() ? secondary : const Color(0xFFFFD700));

      _particles.add(
        _StardustParticle(
          position: pos,
          velocity: velocity,
          radius: isTap ? (3.5 + _rng.nextDouble() * 3.5) : (2.5 + _rng.nextDouble() * 2.5),
          color: color,
          maxLife: isTap ? (0.45 + _rng.nextDouble() * 0.3) : (0.35 + _rng.nextDouble() * 0.2),
        ),
      );
    }

    if (isTap) {
      _ripples.add(
        _TouchRipple(
          origin: pos,
          color: primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _lastPointerPosition = e.localPosition;
        _spawnParticles(e.localPosition, isTap: true);
      },
      onPointerMove: (e) {
        final pos = e.localPosition;
        if (_lastPointerPosition != null) {
          final dist = (pos - _lastPointerPosition!).distance;
          if (dist > 6.0) {
            _spawnParticles(pos, isTap: false);
            _lastPointerPosition = pos;
          }
        } else {
          _lastPointerPosition = pos;
        }
      },
      onPointerUp: (_) => _lastPointerPosition = null,
      onPointerCancel: (_) => _lastPointerPosition = null,
      child: CustomPaint(
        foregroundPainter: _StardustTrailPainter(
          particles: _particles,
          ripples: _ripples,
        ),
        child: widget.child,
      ),
    );
  }
}

class _StardustTrailPainter extends CustomPainter {
  final List<_StardustParticle> particles;
  final List<_TouchRipple> ripples;

  _StardustTrailPainter({required this.particles, required this.ripples});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Paint Ripples
    for (final ripple in ripples) {
      final ripplePaint = Paint()
        ..color = ripple.color.withValues(alpha: ripple.opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(ripple.origin, ripple.radius, ripplePaint);
    }

    // 2. Paint Stardust Particles
    for (final p in particles) {
      // Glow blur
      final glowPaint = Paint()
        ..color = p.color.withValues(alpha: p.opacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(p.position, p.radius * 1.5, glowPaint);

      // Core particle
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.radius, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StardustTrailPainter oldDelegate) => true;
}
