import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/lucky_spin_model.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../animations/feedback_overlays.dart';
import '../buttons/tactile_button.dart';

/// Cosmic Lucky Spin Modal — Daily Fortune Wheel
/// Features:
/// - 8-segment custom-painted celestial wheel with gems and boosters
/// - Deceleration physics with ticker peg ticks & haptics
/// - Free daily spin with 30-gem re-spin option
/// - Rich victory burst with confetti and animated claim banner
class LuckySpinModal extends ConsumerStatefulWidget {
  const LuckySpinModal({super.key});

  @override
  ConsumerState<LuckySpinModal> createState() => _LuckySpinModalState();
}

class _LuckySpinModalState extends ConsumerState<LuckySpinModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  double _currentAngle = 0.0;
  double _targetAngle = 0.0;
  bool _isSpinning = false;
  LuckySpinPrize? _wonPrize;
  bool _showVictory = false;
  int _lastTickSegment = -1;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    );

    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    );

    _spinController.addListener(_onSpinProgress);
    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSpinComplete();
      }
    });
  }

  @override
  void dispose() {
    _spinController.removeListener(_onSpinProgress);
    _spinController.dispose();
    super.dispose();
  }

  void _onSpinProgress() {
    // Current angle in radians
    final angle = _currentAngle + (_targetAngle - _currentAngle) * _spinAnimation.value;
    // Calculate which segment (out of 8) is under the top peg (3pi/2 or 0 depending on offset)
    const segmentAngle = 2 * pi / 8;
    // Normalized angle in [0, 2pi)
    final normAngle = (angle % (2 * pi));
    final currentSegment = (normAngle / segmentAngle).floor() % 8;

    if (currentSegment != _lastTickSegment) {
      _lastTickSegment = currentSegment;
      triggerHaptic(ref, HapticService.lightTap);
      AudioService().playUiClick();
    }
    setState(() {});
  }

  Future<void> _startSpin({required bool useGems}) async {
    if (_isSpinning) return;

    final player = ref.read(gameStateProvider);
    if (useGems && player.gems < 30) {
      triggerHaptic(ref, HapticService.wrongAnswer);
      AudioService().playWrong();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough gems! Need 30 💎',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSpinning = true;
      _wonPrize = null;
      _showVictory = false;
    });

    final prize = await ref.read(gameStateProvider.notifier).spinLuckyWheel(useGems: useGems);
    if (prize == null) {
      setState(() => _isSpinning = false);
      return;
    }

    _wonPrize = prize;

    // Find the prize index
    final prizeIndex = LuckySpinPrize.prizes.indexWhere((p) => p.id == prize.id);
    const segmentAngle = 2 * pi / 8;

    // To have slice [prizeIndex] stop under the top pointer (at 12 o'clock, which is -pi/2),
    // rotation must align:
    // Slice i center starts at: i * segmentAngle + (segmentAngle / 2)
    // When rotated by R, position is (startAngle + R) mod 2pi = 3*pi/2 (top).
    // So R mod 2pi = 3*pi/2 - (startAngle)
    final sliceCenter = prizeIndex * segmentAngle + (segmentAngle / 2);
    final targetModulo = (3 * pi / 2 - sliceCenter) % (2 * pi);

    // Add 5 to 7 full rotations for excitement
    final fullSpins = (6 * 2 * pi);
    _currentAngle = _currentAngle % (2 * pi);
    _targetAngle = _currentAngle + fullSpins + (targetModulo - (_currentAngle % (2 * pi)) + 2 * pi) % (2 * pi);

    triggerHaptic(ref, HapticService.mediumTap);
    AudioService().playUiConfirm();

    _spinController.forward(from: 0.0);
  }

  void _onSpinComplete() {
    _currentAngle = _targetAngle;
    setState(() {
      _isSpinning = false;
      _showVictory = true;
    });

    if (_wonPrize?.id == 'gems_250') {
      AudioService().playPerfect();
      triggerHaptic(ref, HapticService.perfectAnswer);
    } else {
      AudioService().playLevelUp();
      triggerHaptic(ref, HapticService.correctAnswer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);
    final isFreeAvailable = player.isLuckySpinAvailable;
    final currentRotation = _currentAngle + (_targetAngle - _currentAngle) * _spinAnimation.value;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main Card
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF192038), Color(0xFF0F1326)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Close & Gem Balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TactileButton.close(
                      size: 36,
                      onTap: () {
                        if (!_isSpinning) Navigator.of(context).pop();
                      },
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎰', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'COSMIC WHEEL',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.glassWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💎', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '${player.gems}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.gemCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  isFreeAvailable
                      ? 'Spin for a free daily gift! Boosters & gems await!'
                      : 'Extra spin available for 30 gems!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 16),

                // ──── WHEEL DISPLAY WITH TOP POINTER ────
                SizedBox(
                  width: 270,
                  height: 270,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glowing halo
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withValues(alpha: 0.25),
                              blurRadius: 28,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),

                      // Rotating Wheel Painter
                      Transform.rotate(
                        angle: currentRotation,
                        child: CustomPaint(
                          size: const Size(250, 250),
                          painter: _CosmicWheelPainter(prizes: LuckySpinPrize.prizes),
                        ),
                      ),

                      // Center Hub Badge (Shiny Metallic Core)
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF1B2040)],
                            stops: [0.3, 1.0],
                          ),
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '⚡',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                      ),

                      // Top Indicator Ticker Pointer Peg (at 12 o'clock, pointing downward)
                      Positioned(
                        top: 0,
                        child: AnimatedBuilder(
                          animation: _spinController,
                          builder: (context, _) {
                            final pegShake = _isSpinning
                                ? sin(_spinController.value * 80) * 0.12
                                : 0.0;
                            return Transform.rotate(
                              angle: pegShake,
                              child: Container(
                                width: 28,
                                height: 32,
                                decoration: const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFFFD700),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: CustomPaint(
                                  painter: _PointerPegPainter(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ──── SPIN BUTTON / VICTORY CARD ────
                if (_showVictory && _wonPrize != null)
                  _buildVictoryBanner(_wonPrize!)
                else
                  _buildSpinButton(isFreeAvailable),
              ],
            ),
          ),

          // Confetti overlay on victory
          if (_showVictory)
            const Positioned.fill(
              child: IgnorePointer(
                child: ConfettiCascade(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpinButton(bool isFreeAvailable) {
    if (isFreeAvailable) {
      return TactileButton(
        label: 'FREE DAILY SPIN',
        fontSize: 16,
        height: 52,
        icon: Icons.auto_awesome_rounded,
        faceColorTop: const Color(0xFF00E5FF),
        faceColorBottom: const Color(0xFF0088CC),
        rimColor: const Color(0xFF005580),
        onTap: _isSpinning ? () {} : () => _startSpin(useGems: false),
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: TactileButton(
              label: 'SPIN (30 💎)',
              fontSize: 15,
              height: 52,
              icon: Icons.refresh_rounded,
              faceColorTop: const Color(0xFFFF9E00),
              faceColorBottom: const Color(0xFFCC7A00),
              rimColor: const Color(0xFF995C00),
              onTap: _isSpinning ? () {} : () => _startSpin(useGems: true),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildVictoryBanner(LuckySpinPrize prize) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            prize.primaryColor.withValues(alpha: 0.25),
            prize.secondaryColor.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: prize.primaryColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: prize.primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(prize.icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOU WON!',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    prize.label,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              triggerHaptic(ref, HapticService.mediumTap);
              AudioService().playUiConfirm();
              Navigator.of(context).pop();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: prize.primaryColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: prize.primaryColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'CLAIM PRIZE',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the 8-slice wheel
class _CosmicWheelPainter extends CustomPainter {
  final List<LuckySpinPrize> prizes;
  _CosmicWheelPainter({required this.prizes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const count = 8;
    const sweepAngle = 2 * pi / count;

    // Draw outer golden metallic rim
    final rimPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawCircle(center, radius - 2, rimPaint);

    final bevelPaint = Paint()
      ..color = const Color(0xFF0F1428)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 5, bevelPaint);

    // Draw the 8 slices
    for (int i = 0; i < count; i++) {
      final startAngle = i * sweepAngle;
      final prize = prizes[i];

      // Slice path
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius - 5),
          startAngle,
          sweepAngle,
          false,
        )
        ..close();

      // Alternating radiant gradients
      final slicePaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            prize.primaryColor.withValues(alpha: 0.9),
            prize.secondaryColor,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawPath(path, slicePaint);

      // Slice divider border
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, borderPaint);

      // Draw Icon & Label inside slice
      canvas.save();
      final midAngle = startAngle + (sweepAngle / 2);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(midAngle);

      // Icon & text painter
      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: '${prize.icon}\n',
            style: const TextStyle(fontSize: 16),
          ),
          TextSpan(
            text: prize.label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(radius * 0.45, -textPainter.height / 2),
      );

      canvas.restore();
    }

    // Outer rim studs (stars/dots)
    for (int i = 0; i < 16; i++) {
      final dotAngle = i * (2 * pi / 16);
      final dotPos = Offset(
        center.dx + (radius - 2.5) * cos(dotAngle),
        center.dy + (radius - 2.5) * sin(dotAngle),
      );
      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(dotPos, 1.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicWheelPainter oldDelegate) => false;
}

/// Pointer peg painter pointing downward into the top of the wheel
class _PointerPegPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height) // tip pointing down
      ..lineTo(0, size.height * 0.25)
      ..lineTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.8, 0)
      ..lineTo(size.width, size.height * 0.25)
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFEA75), Color(0xFFFF9E00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);

    canvas.drawPath(path, paint);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _PointerPegPainter oldDelegate) => false;
}
