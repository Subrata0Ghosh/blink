import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Full-screen white flash that pulses on correct/PERFECT answers
class ScreenFlash extends StatefulWidget {
  final Color color;
  final Duration duration;
  final VoidCallback? onComplete;

  const ScreenFlash({
    super.key,
    this.color = Colors.white,
    this.duration = const Duration(milliseconds: 250),
    this.onComplete,
  });

  @override
  State<ScreenFlash> createState() => _ScreenFlashState();
}

class _ScreenFlashState extends State<ScreenFlash> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward().then((_) => widget.onComplete?.call());
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
        // Sharp flash in first 30%, then fade out
        final progress = _controller.value;
        double opacity;
        if (progress < 0.15) {
          opacity = (progress / 0.15).clamp(0.0, 1.0) * 0.55;
        } else {
          opacity = ((1.0 - ((progress - 0.15) / 0.85)) * 0.55).clamp(0.0, 1.0);
        }
        return IgnorePointer(
          child: Container(color: widget.color.withValues(alpha: opacity)),
        );
      },
    );
  }
}

/// Red vignette pulse overlay for wrong answers
class RedVignette extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;

  const RedVignette({
    super.key,
    this.duration = const Duration(milliseconds: 500),
    this.onComplete,
  });

  @override
  State<RedVignette> createState() => _RedVignetteState();
}

class _RedVignetteState extends State<RedVignette> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward().then((_) => widget.onComplete?.call());
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
        final t = _controller.value;
        final opacity = t < 0.3
            ? (t / 0.3).clamp(0.0, 1.0)
            : ((1.0 - ((t - 0.3) / 0.7)).clamp(0.0, 1.0));
        return IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  AppColors.dangerRed.withValues(alpha: opacity * 0.45),
                  AppColors.dangerRedDark.withValues(alpha: opacity * 0.65),
                ],
                stops: const [0.0, 0.4, 0.75, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Confetti cascade with colorful particles raining down
class ConfettiCascade extends StatefulWidget {
  final int particleCount;
  final Duration duration;
  final VoidCallback? onComplete;

  const ConfettiCascade({
    super.key,
    this.particleCount = 60,
    this.duration = const Duration(milliseconds: 2000),
    this.onComplete,
  });

  @override
  State<ConfettiCascade> createState() => _ConfettiCascadeState();
}

class _ConfettiCascadeState extends State<ConfettiCascade> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(widget.particleCount, (_) => _ConfettiParticle(rng));
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward().then((_) => widget.onComplete?.call());
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
        return IgnorePointer(
          child: CustomPaint(
            painter: _ConfettiPainter(_particles, _controller.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _ConfettiParticle {
  final double x;          // 0-1 horizontal position
  final double startDelay;  // 0-0.3 stagger delay
  final double speed;       // fall speed multiplier
  final double wobbleFreq;  // horizontal wobble
  final double wobbleAmp;   // wobble amplitude
  final double rotation;
  final double rotationSpeed;
  final double size;
  final Color color;

  _ConfettiParticle(Random rng)
      : x = rng.nextDouble(),
        startDelay = rng.nextDouble() * 0.25,
        speed = 0.5 + rng.nextDouble() * 0.8,
        wobbleFreq = 1.5 + rng.nextDouble() * 3.0,
        wobbleAmp = 0.01 + rng.nextDouble() * 0.035,
        rotation = rng.nextDouble() * 2 * pi,
        rotationSpeed = 2.0 + rng.nextDouble() * 6.0,
        size = 3.0 + rng.nextDouble() * 5.0,
        color = [
          AppColors.cyan,
          AppColors.gold,
          AppColors.success,
          AppColors.primaryLight,
          AppColors.mint,
          AppColors.gemRainbow,
          AppColors.novaOrangeLight,
          const Color(0xFFFF6B9D),
        ][rng.nextInt(8)];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double time;

  _ConfettiPainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final effectiveTime = ((time - p.startDelay) / (1.0 - p.startDelay)).clamp(0.0, 1.0);
      if (effectiveTime <= 0) continue;

      final y = -0.05 + effectiveTime * 1.15 * p.speed;
      if (y > 1.1) continue;

      final wobbleX = sin(effectiveTime * p.wobbleFreq * 2 * pi) * p.wobbleAmp;
      final x = p.x + wobbleX;
      final opacity = effectiveTime < 0.8 ? 1.0 : ((1.0 - effectiveTime) / 0.2).clamp(0.0, 1.0);
      final rot = p.rotation + effectiveTime * p.rotationSpeed;

      final center = Offset(x * size.width, y * size.height);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rot);

      final paint = Paint()..color = p.color.withValues(alpha: opacity * 0.9);

      // Draw as small rectangles for confetti look
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size * 0.5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(p.size * 0.15)),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.time != time;
}

/// Animated combo multiplier popup — "x3 COMBO!" scales up and fades
class ComboPopup extends StatefulWidget {
  final int combo;
  final VoidCallback? onComplete;

  const ComboPopup({super.key, required this.combo, this.onComplete});

  @override
  State<ComboPopup> createState() => _ComboPopupState();
}

class _ComboPopupState extends State<ComboPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.3).chain(CurveTween(curve: Curves.easeOutBack)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_controller);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: const Offset(0, -0.3),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward().then((_) => widget.onComplete?.call());
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
        return IgnorePointer(
          child: SlideTransition(
            position: _slide,
            child: Opacity(
              opacity: _opacity.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6000).withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🔥',
                        style: GoogleFonts.outfit(fontSize: 22),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'x${widget.combo} COMBO!',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            const Shadow(
                              color: Color(0xFF8B2500),
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Animated number counter that counts up from 0 to target
class AnimatedCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1200),
    this.style,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
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
        final curved = Curves.easeOutCubic.transform(_controller.value);
        final current = (widget.value * curved).round();
        return Text(
          '${widget.prefix}$current${widget.suffix}',
          style: widget.style ?? GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        );
      },
    );
  }
}

/// Green edge glow overlay for correct answers
class CorrectEdgeGlow extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;

  const CorrectEdgeGlow({
    super.key,
    this.duration = const Duration(milliseconds: 800),
    this.onComplete,
  });

  @override
  State<CorrectEdgeGlow> createState() => _CorrectEdgeGlowState();
}

class _CorrectEdgeGlowState extends State<CorrectEdgeGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward().then((_) => widget.onComplete?.call());
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
        final t = _controller.value;
        final opacity = t < 0.25
            ? (t / 0.25).clamp(0.0, 1.0)
            : ((1.0 - ((t - 0.25) / 0.75)).clamp(0.0, 1.0));
        return IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.3,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  AppColors.success.withValues(alpha: opacity * 0.2),
                  AppColors.success.withValues(alpha: opacity * 0.4),
                ],
                stops: const [0.0, 0.5, 0.8, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "NEW BEST!" celebration banner with golden glow
class NewBestBanner extends StatefulWidget {
  final VoidCallback? onComplete;

  const NewBestBanner({super.key, this.onComplete});

  @override
  State<NewBestBanner> createState() => _NewBestBannerState();
}

class _NewBestBannerState extends State<NewBestBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete?.call());
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
        return IgnorePointer(
          child: Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: _scale.value.clamp(0.0, 2.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFA500).withValues(alpha: 0.5),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      'NEW BEST!',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF3D2200),
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            offset: const Offset(0, -1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('⭐', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Interactive Gem Rain Shower — streams faceted gems down with sparkles
class GemRainShower extends StatefulWidget {
  final int gemCount;
  final Duration duration;
  final VoidCallback? onComplete;

  const GemRainShower({
    super.key,
    this.gemCount = 35,
    this.duration = const Duration(milliseconds: 2500),
    this.onComplete,
  });

  @override
  State<GemRainShower> createState() => _GemRainShowerState();
}

class _GemRainShowerState extends State<GemRainShower> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_GemDrop> _gems;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _gems = List.generate(widget.gemCount, (_) => _GemDrop(rng));
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward().then((_) => widget.onComplete?.call());
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
        return IgnorePointer(
          child: CustomPaint(
            painter: _GemRainPainter(_gems, _controller.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _GemDrop {
  final double x;
  final double startDelay;
  final double speed;
  final double wobble;
  final double size;
  final double rotation;
  final Color color;
  final int shapeType; // 0: diamond, 1: shard

  _GemDrop(Random rng)
      : x = rng.nextDouble(),
        startDelay = rng.nextDouble() * 0.35,
        speed = 0.7 + rng.nextDouble() * 0.6,
        wobble = 0.02 + rng.nextDouble() * 0.04,
        size = 14.0 + rng.nextDouble() * 12.0,
        rotation = rng.nextDouble() * 2 * pi,
        shapeType = rng.nextInt(2),
        color = [
          AppColors.gemCyan,
          AppColors.gold,
          AppColors.gemPurple,
          AppColors.gemRainbow,
          const Color(0xFF00E676),
        ][rng.nextInt(5)];
}

class _GemRainPainter extends CustomPainter {
  final List<_GemDrop> gems;
  final double time;

  _GemRainPainter(this.gems, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final gem in gems) {
      final effectiveTime = ((time - gem.startDelay) / (1.0 - gem.startDelay)).clamp(0.0, 1.0);
      if (effectiveTime <= 0) continue;

      final y = -0.08 + effectiveTime * 1.2 * gem.speed;
      if (y > 1.1) continue;

      final wobbleX = sin(effectiveTime * 4 * pi) * gem.wobble;
      final x = (gem.x + wobbleX).clamp(0.0, 1.0);
      final opacity = effectiveTime < 0.8 ? 1.0 : ((1.0 - effectiveTime) / 0.2).clamp(0.0, 1.0);

      final center = Offset(x * size.width, y * size.height);
      final rot = gem.rotation + effectiveTime * 3.5;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rot);

      // Draw diamond / shard
      final path = Path();
      final half = gem.size / 2;
      path.moveTo(0, -half * 1.2);
      path.lineTo(half, 0);
      path.lineTo(0, half * 1.2);
      path.lineTo(-half, 0);
      path.close();

      // Outer glow
      final glowPaint = Paint()
        ..color = gem.color.withValues(alpha: opacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, glowPaint);

      // Gem body
      final bodyPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: opacity * 0.9),
            gem.color.withValues(alpha: opacity * 0.85),
            gem.color.withValues(alpha: opacity * 0.6),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: half));
      canvas.drawPath(path, bodyPaint);

      // Specular highlight facet
      final facetPath = Path()
        ..moveTo(0, -half * 1.2)
        ..lineTo(half * 0.5, 0)
        ..lineTo(0, 0)
        ..close();
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.65);
      canvas.drawPath(facetPath, highlightPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _GemRainPainter old) => old.time != time;
}

