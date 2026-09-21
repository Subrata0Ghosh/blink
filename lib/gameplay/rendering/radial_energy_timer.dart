import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Animated Radial Energy Timer for the Observe Phase
/// Displays a glowing circular energy ring that ticks down smoothly,
/// shifting to an intense pulsating amber/crimson when time is below 25%.
class RadialEnergyTimer extends StatelessWidget {
  final double progress; // 1.0 -> 0.0
  final double timeLeft;
  final double size;

  const RadialEnergyTimer({
    super.key,
    required this.progress,
    required this.timeLeft,
    this.size = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = progress < 0.25;
    final primaryColor = isLow ? AppColors.error : AppColors.cyan;
    final secondaryColor = isLow ? AppColors.amber : AppColors.primaryLight;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow Pulse when time is running low
          if (isLow)
            Container(
              width: size * 0.9,
              height: size * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.5),
                    blurRadius: 18,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),

          // Custom circular energy arc painter
          CustomPaint(
            painter: _RadialTimerPainter(
              progress: progress.clamp(0.0, 1.0),
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
            ),
            size: Size(size, size),
          ),

          // Center Time Text / Seconds
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeLeft > 0 ? timeLeft.toStringAsFixed(1) : '0.0',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isLow ? AppColors.error : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadialTimerPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _RadialTimerPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    // Track Background
    final trackPaint = Paint()
      ..color = AppColors.surfaceLight.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    final sweepAngle = 2 * pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Glowing Arc
    final glowPaint = Paint()
      ..shader = SweepGradient(
        colors: [secondaryColor, primaryColor],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, glowPaint);

    // Crisp Foreground Arc
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [secondaryColor, primaryColor],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, arcPaint);

    // Tip Energy Bead
    final tipAngle = -pi / 2 + sweepAngle;
    final tipPos = center + Offset(radius * cos(tipAngle), radius * sin(tipAngle));
    canvas.drawCircle(tipPos, 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RadialTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor;
  }
}
