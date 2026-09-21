import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Dimensional Arena Surface for BLINK
/// Replaces the flat dark rectangle with a living 2.5D dimensional world surface:
/// - Depth radial gradient with central atmospheric luminosity
/// - Subtle perspective-shifted curvature and edge rim lighting
/// - Atmospheric floating micro-particles
/// - Edge vignette to focus gaze inward
/// - Living camera breathing animation
class ArenaSurface extends StatefulWidget {
  final Widget child;
  final bool enableBreathing;
  final double breathingScale;

  const ArenaSurface({
    super.key,
    required this.child,
    this.enableBreathing = true,
    this.breathingScale = 1.025,
  });

  @override
  State<ArenaSurface> createState() => _ArenaSurfaceState();
}

class _ArenaSurfaceState extends State<ArenaSurface>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnim;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    if (widget.enableBreathing) {
      _breathingAnim = Tween<double>(begin: 1.0, end: widget.breathingScale).animate(
        CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
      );
      _breathingController.repeat(reverse: true);
    } else {
      _breathingAnim = const AlwaysStoppedAnimation(1.0);
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enableBreathing ? _breathingAnim.value : 1.0,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            // Deep ambient arena drop shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 36,
              spreadRadius: 4,
              offset: const Offset(0, 12),
            ),
            // Outer cyan/violet cosmic rim glow
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 40,
              spreadRadius: -4,
            ),
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.12),
              blurRadius: 20,
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Deep Arena Plane with Radial Perspective Gradient
              CustomPaint(
                painter: _ArenaDepthPainter(),
                size: Size.infinite,
              ),

              // 2. Atmospheric Floating Micro-Particles
              const _ArenaParticles(particleCount: 16),

              // 3. Interactive Objects Content Layer
              widget.child,

              // 4. Subtle Vignette & Perspective Rim Light Overlay
              IgnorePointer(
                child: CustomPaint(
                  painter: _ArenaRimPainter(),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArenaDepthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width * 0.5, size.height * 0.42);

    // Cosmic base fill
    final baseGradient = RadialGradient(
      center: const Alignment(0.0, -0.15),
      radius: 0.85,
      colors: [
        const Color(0xFF1E284E), // luminous deep indigo center
        const Color(0xFF141A34), // mid cosmic tone
        const Color(0xFF0C1022), // deep dark border
        const Color(0xFF070914), // edge abyss
      ],
      stops: const [0.0, 0.45, 0.8, 1.0],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = baseGradient);

    // Subtle perspective ground grid / horizon glow
    final horizonPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.6),
        radius: 0.7,
        colors: [
          AppColors.primary.withValues(alpha: 0.14),
          AppColors.cyan.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, horizonPaint);

    // Soft elliptical arena platform boundary
    final arenaOvalRect = Rect.fromCenter(
      center: center + const Offset(0, 20),
      width: size.width * 0.94,
      height: size.height * 0.86,
    );
    final ovalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = RadialGradient(
        colors: [
          AppColors.cyan.withValues(alpha: 0.25),
          AppColors.primary.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(arenaOvalRect);
    canvas.drawOval(arenaOvalRect, ovalPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArenaRimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(32));

    // Outer Rim Specular Highlight (top edge catches light)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          AppColors.cyan.withValues(alpha: 0.25),
          AppColors.primary.withValues(alpha: 0.12),
          Colors.black.withValues(alpha: 0.5),
        ],
        stops: const [0.0, 0.2, 0.6, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, rimPaint);

    // Inner edge vignette to draw focus inward
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.35),
        ],
        stops: const [0.65, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArenaParticles extends StatefulWidget {
  final int particleCount;
  const _ArenaParticles({this.particleCount = 16});

  @override
  State<_ArenaParticles> createState() => _ArenaParticlesState();
}

class _ArenaParticlesState extends State<_ArenaParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ArenaMote> _motes;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _motes = List.generate(widget.particleCount, (_) => _ArenaMote(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
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
          painter: _ArenaMotesPainter(_motes, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ArenaMote {
  final double x;
  final double baseY;
  final double size;
  final double speed;
  final double phase;
  final Color color;

  _ArenaMote(Random rng)
      : x = 0.08 + rng.nextDouble() * 0.84,
        baseY = 0.08 + rng.nextDouble() * 0.84,
        size = 1.0 + rng.nextDouble() * 2.2,
        speed = 0.4 + rng.nextDouble() * 0.8,
        phase = rng.nextDouble() * 2 * pi,
        color = [
          AppColors.cyan,
          AppColors.primaryLight,
          AppColors.mint,
          Colors.white,
        ][rng.nextInt(4)];
}

class _ArenaMotesPainter extends CustomPainter {
  final List<_ArenaMote> motes;
  final double time;

  _ArenaMotesPainter(this.motes, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final mote in motes) {
      final y = mote.baseY + sin(time * 2 * pi * mote.speed + mote.phase) * 0.04;
      final opacity = 0.2 + 0.5 * ((sin(time * 2 * pi * mote.speed + mote.phase) + 1) / 2);
      final pos = Offset(mote.x * size.width, y * size.height);

      final paint = Paint()
        ..color = mote.color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, mote.size * 0.8);
      canvas.drawCircle(pos, mote.size, paint);
      canvas.drawCircle(pos, mote.size * 0.5, Paint()..color = Colors.white.withValues(alpha: opacity));
    }
  }

  @override
  bool shouldRepaint(covariant _ArenaMotesPainter oldDelegate) => true;
}
