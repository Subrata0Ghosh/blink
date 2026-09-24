import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// Available interactive behaviors for Nova
enum NovaBehavior {
  idle,
  spinning,
  hopping,
  scanning,
  talking,
  waving,
}

/// Interactive 3D Nova Robot Companion Widget
///
/// Features:
/// - Significantly enlarged, high-presence proportions
/// - Articulated zero-gravity limb movements:
///   * Alternating paddling kicks for both legs with micro-thruster ion glow
///   * Floating buoyant arm sways and cheerful waving gestures
/// - Organic living face system:
///   * Natural periodic eye blinking with sleek robotic eyelids
///   * Curious pupil glance tracking and sparkly star glints
///   * Expressive happy eye morphing ("^ ^") on joy and taps
///   * Breathing cyan/rosy blush on cheeks
///   * Cognitive forehead visor pattern pulse
/// - Pulsing chest arc reactor energy core
/// - 3D Perspective Tilt on user drag and touch
/// - Holographic 3D emitter platform with orbiting particles
/// - Rich interactive tap behaviors (360° spin, joyful hop, speech bubble, scan)
class TactileNovaCompanion extends StatefulWidget {
  final double size;
  final bool enableDialogue;
  final bool showHologramRing;
  final VoidCallback? onTap;

  const TactileNovaCompanion({
    super.key,
    this.size = 120,
    this.enableDialogue = true,
    this.showHologramRing = true,
    this.onTap,
  });

  @override
  State<TactileNovaCompanion> createState() => _TactileNovaCompanionState();
}

class _TactileNovaCompanionState extends State<TactileNovaCompanion>
    with TickerProviderStateMixin {
  // 1. Idle hovering controller (2200ms continuous buoyancy)
  late AnimationController _idleController;

  // 2. Breathing controller (3200ms chest expansion & heart pulse)
  late AnimationController _breatheController;

  // 3. Leg paddling controller (1800ms alternating kicks)
  late AnimationController _legController;

  // 4. Natural blink controller (160ms eyelid shutter)
  late AnimationController _blinkController;
  Timer? _blinkTimer;

  // 5. Friendly hand wave controller (1200ms)
  late AnimationController _waveController;
  Timer? _waveTimer;

  // 6. Holographic ring rotation
  late AnimationController _ringController;

  // 7. Interactive behaviors: spin, hop, scan
  late AnimationController _spinController;
  late AnimationController _hopController;
  late Animation<double> _hopAnim;
  late AnimationController _scanController;
  late Animation<double> _scanAnim;

  // Touch 3D perspective tilt
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  // Current active behavior
  NovaBehavior _currentBehavior = NovaBehavior.idle;
  String? _speechText;
  Timer? _speechTimer;

  static const List<String> _dialoguePool = [
    'Reality shifted! Did you see?',
    'Keep your eyes sharp, Observer!',
    'The cosmos is full of secrets!',
    'Beep boop! Ready to explore!',
    'Every blink holds a clue!',
    'Together we are unstoppable!',
  ];

  int _tapCount = 0;

  @override
  void initState() {
    super.initState();

    // 1. Hover buoyancy
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // 2. Breathing & heartbeat
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // 3. Leg paddling kicks
    _legController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 4. Holographic ring rotation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // 5. Natural Blinking Controller
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    // Schedule natural periodic blinks every 3.5 - 4.5 seconds
    _startPeriodicBlinking();

    // 6. Idle hand wave controller
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Schedule occasional friendly idle waves every 9-11 seconds
    _startPeriodicWaving();

    // 7. 360 Spin
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // 8. Hop / Joyful bounce
    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _hopAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -30.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -30.0, end: 0.0).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 55,
      ),
    ]).animate(_hopController);

    // 9. Curious scan & tilt
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scanAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.22).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.22, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_scanController);
  }

  void _startPeriodicBlinking() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (!mounted) return;
      if (_currentBehavior == NovaBehavior.idle || _currentBehavior == NovaBehavior.talking) {
        _blinkController.forward(from: 0.0).then((_) {
          if (mounted) _blinkController.reverse();
        });
      }
    });
  }

  void _startPeriodicWaving() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 9500), (_) {
      if (!mounted) return;
      if (_currentBehavior == NovaBehavior.idle) {
        _waveController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _idleController.dispose();
    _breatheController.dispose();
    _legController.dispose();
    _ringController.dispose();
    _blinkController.dispose();
    _waveController.dispose();
    _spinController.dispose();
    _hopController.dispose();
    _scanController.dispose();
    _blinkTimer?.cancel();
    _waveTimer?.cancel();
    _speechTimer?.cancel();
    super.dispose();
  }

  void _triggerRandomBehavior() {
    HapticFeedback.mediumImpact();
    widget.onTap?.call();

    // Trigger an immediate blink and wave or cycle through special actions
    _tapCount++;
    final behaviorIndex = _tapCount % 5;

    switch (behaviorIndex) {
      case 0: // Cheerful Wave
        setState(() => _currentBehavior = NovaBehavior.waving);
        _waveController.forward(from: 0.0).then((_) {
          if (mounted) setState(() => _currentBehavior = NovaBehavior.idle);
        });
        break;

      case 1: // Joyful Hop with Leg Tuck
        setState(() => _currentBehavior = NovaBehavior.hopping);
        _hopController.forward(from: 0.0).then((_) {
          if (mounted) setState(() => _currentBehavior = NovaBehavior.idle);
        });
        break;

      case 2: // 360 Spin
        setState(() => _currentBehavior = NovaBehavior.spinning);
        _spinController.forward(from: 0.0).then((_) {
          if (mounted) setState(() => _currentBehavior = NovaBehavior.idle);
        });
        break;

      case 3: // Thought Bubble Dialogue
        if (widget.enableDialogue) {
          final text = _dialoguePool[Random().nextInt(_dialoguePool.length)];
          _speechTimer?.cancel();
          setState(() {
            _currentBehavior = NovaBehavior.talking;
            _speechText = text;
          });
          _speechTimer = Timer(const Duration(milliseconds: 2600), () {
            if (mounted) {
              setState(() {
                _speechText = null;
                _currentBehavior = NovaBehavior.idle;
              });
            }
          });
        }
        break;

      case 4: // Curious Scan & Tilt
        setState(() => _currentBehavior = NovaBehavior.scanning);
        _scanController.forward(from: 0.0).then((_) {
          if (mounted) setState(() => _currentBehavior = NovaBehavior.idle);
        });
        break;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _tiltY = (_tiltY + details.delta.dx * 0.007).clamp(-0.4, 0.4);
      _tiltX = (_tiltX - details.delta.dy * 0.007).clamp(-0.4, 0.4);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() {
      _tiltX = 0.0;
      _tiltY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return GestureDetector(
      onTap: _triggerRandomBehavior,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _idleController,
          _breatheController,
          _legController,
          _ringController,
          _blinkController,
          _waveController,
          _spinController,
          _hopController,
          _scanController,
        ]),
        builder: (context, _) {
          // Floating offset (sine wave)
          final idleY = sin(_idleController.value * 2 * pi) * 7.0;
          final hopY = _hopAnim.value;
          final totalY = idleY + hopY;

          // 3D Spin angle (Y-axis rotation)
          final spinAngle = _spinController.value * 2 * pi;

          // Scanning tilt
          final scanTilt = _scanAnim.value;

          // Breathing scale
          final breathe = sin(_breatheController.value * 2 * pi);
          final scaleY = 1.0 + (breathe * 0.025);
          final scaleX = 1.0 - (breathe * 0.015);

          final isHappy = _currentBehavior == NovaBehavior.spinning ||
              _currentBehavior == NovaBehavior.hopping ||
              _currentBehavior == NovaBehavior.talking ||
              _currentBehavior == NovaBehavior.waving;

          // Alternating Leg paddling angles (zero-gravity kick)
          final legProgress = _legController.value * 2 * pi;
          final isHopping = _hopController.isAnimating && _hopAnim.value < -8;
          final isWaving = _waveController.isAnimating || _currentBehavior == NovaBehavior.waving;

          final leftLegAngle = isHopping ? -0.20 : (sin(legProgress) * 0.12);
          final rightLegAngle = isHopping ? 0.20 : (sin(legProgress + pi) * 0.12);
          final legTuckY = isHopping ? -9.0 : 0.0;

          // Arm floating and waving angles
          final waveProgress = _waveController.value * 5 * pi;
          final rightArmAngle = isWaving
              ? (-0.46 + (sin(waveProgress) * 0.24))
              : isHappy
                  ? 0.22
                  : (-sin(_idleController.value * 2 * pi) * 0.08);
          final leftArmAngle = isHappy
              ? -0.22
              : (sin(_idleController.value * 2 * pi) * 0.08);

          // Character frame dimensions
          final bodySize = size * 1.16;

          return SizedBox(
            width: size * 1.38,
            height: size * 1.44,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // ──── 1. HOLOGRAPHIC 3D EMITTER PLATFORM ────
                if (widget.showHologramRing)
                  Positioned(
                    bottom: 0,
                    child: CustomPaint(
                      painter: _HologramRingPainter(
                        rotation: _ringController.value * 2 * pi,
                        intensity: 0.85 + (sin(_idleController.value * 2 * pi) * 0.15),
                      ),
                      size: Size(size * 1.25, size * 0.38),
                    ),
                  ),

                // ──── 2. 3D NOVA ROBOT BODY (Perspective transform) ────
                Positioned(
                  top: (size * 0.10) + totalY,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002) // Perspective depth
                      ..rotateX(_tiltX + scanTilt)
                      ..rotateY(_tiltY + spinAngle),
                    child: SizedBox(
                      width: bodySize,
                      height: bodySize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Radiant ambient atmospheric aura
                          Container(
                            width: bodySize * 0.88,
                            height: bodySize * 0.88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cyan.withValues(alpha: isHappy ? 0.65 : 0.42),
                                  blurRadius: 36,
                                  spreadRadius: 6,
                                ),
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: isHappy ? 0.50 : 0.30),
                                  blurRadius: 52,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),

                          // ──── ARTICULATED LIVING BODY LAYERS ────
                          // A. LEGS LAYER (Back layer, underneath pelvic rim)
                          Transform.translate(
                            offset: Offset(0, legTuckY),
                            child: Stack(
                              children: [
                                // Left Leg (viewer's left, hip pivot)
                                Transform.rotate(
                                  angle: leftLegAngle,
                                  alignment: const Alignment(-0.111, 0.514),
                                  child: Image.asset(
                                    AppAssets.novaLegLeft,
                                    width: bodySize,
                                    height: bodySize,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                                // Right Leg (viewer's right, hip pivot)
                                Transform.rotate(
                                  angle: rightLegAngle,
                                  alignment: const Alignment(0.113, 0.514),
                                  child: Image.asset(
                                    AppAssets.novaLegRight,
                                    width: bodySize,
                                    height: bodySize,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // B. TORSO & HEAD LAYER (Middle layer with living breathing scale)
                          Transform.scale(
                            scaleY: scaleY,
                            scaleX: scaleX,
                            alignment: Alignment.bottomCenter,
                            child: Image.asset(
                              AppAssets.novaTorso,
                              width: bodySize,
                              height: bodySize,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),

                          // C. ARMS LAYER (Front layer, smoothly socketed at shoulders)
                          // Left Arm (viewer's left, shoulder pivot)
                          Transform.rotate(
                            angle: leftArmAngle,
                            alignment: const Alignment(-0.297, 0.162),
                            child: Image.asset(
                              AppAssets.novaArmLeft,
                              width: bodySize,
                              height: bodySize,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                          // Right Arm (viewer's right, shoulder pivot / wave)
                          Transform.rotate(
                            angle: rightArmAngle,
                            alignment: const Alignment(0.260, 0.162),
                            child: Image.asset(
                              AppAssets.novaArmRight,
                              width: bodySize,
                              height: bodySize,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),

                          // Micro-thruster ion rings under feet (active during hover/hop)
                          Positioned(
                            bottom: (bodySize * 0.13) - legTuckY,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildIonThruster(intensity: 0.65 + (sin(legProgress) * 0.25)),
                                SizedBox(width: bodySize * 0.16),
                                _buildIonThruster(intensity: 0.65 + (sin(legProgress + pi) * 0.25)),
                              ],
                            ),
                          ),

                          // ──── LIVING FACE OVERLAY (Blinking, gazing, blushing) ────
                          CustomPaint(
                            painter: _NovaFacePainter(
                              blinkProgress: _blinkController.value,
                              glanceX: _tiltY * 0.8 + (sin(_idleController.value * 2 * pi) * 0.25),
                              glanceY: _tiltX * 0.8 - (breathe * 0.20),
                              isHappy: isHappy,
                              breathe: breathe,
                            ),
                            size: Size(bodySize, bodySize),
                          ),

                          // ──── CHEST ARC REACTOR PULSING CORE ────
                          // Aligned exactly with Nova's chest core (at x=0.555, y=0.588)
                          Positioned(
                            top: bodySize * 0.585,
                            left: bodySize * 0.535,
                            child: Container(
                              width: bodySize * 0.055,
                              height: bodySize * 0.055,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE8FDFF),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.cyanLight,
                                    blurRadius: 10 + (breathe * 4),
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: AppColors.primary,
                                    blurRadius: 18 + (breathe * 6),
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ──── 3. 3D THOUGHT / SPEECH BUBBLE ────
                if (_speechText != null)
                  Positioned(
                    top: -16,
                    child: _buildThoughtBubble(_speechText!),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIonThruster({required double intensity}) {
    final clamped = intensity.clamp(0.2, 1.0);
    return Container(
      width: 14,
      height: 7,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.elliptical(14, 7)),
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: clamped * 0.9),
            AppColors.cyan.withValues(alpha: clamped * 0.6),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: clamped * 0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildThoughtBubble(String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 190),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1528),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.85), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        ),
        // Bubble pointer tail dots
        const SizedBox(height: 2),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyan,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyan,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for Nova's living face features:
/// - Natural blinking eyelids with glowing robotic seams
/// - Pupil tracking glints that glance around
/// - Joyful smiling eye morphing ("^ ^")
/// - Luminous rosy-cyan cheek blush
/// - Forehead neural visor pulse
class _NovaFacePainter extends CustomPainter {
  final double blinkProgress;
  final double glanceX;
  final double glanceY;
  final bool isHappy;
  final double breathe;

  _NovaFacePainter({
    required this.blinkProgress,
    required this.glanceX,
    required this.glanceY,
    required this.isHappy,
    required this.breathe,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ──── TRUE CALIBRATED LANDMARKS (matching 1024x1024 Nova artwork) ────
    final leftEye = Offset(size.width * 0.490, size.height * 0.366);
    final rightEye = Offset(size.width * 0.662, size.height * 0.360);
    final leftEyeW = size.width * 0.155;
    final leftEyeH = size.height * 0.150;
    final rightEyeW = size.width * 0.135;
    final rightEyeH = size.height * 0.145;

    // 1. CHEEK BLUSH (Positioned right beneath the real eyes)
    final blushAlpha = isHappy ? 0.48 : (0.16 + (breathe * 0.08).clamp(0.0, 0.26));
    final blushPaint = Paint()
      ..color = const Color(0xFFFF62A5).withValues(alpha: blushAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final leftCheek = Offset(size.width * 0.420, size.height * 0.445);
    final rightCheek = Offset(size.width * 0.720, size.height * 0.440);
    canvas.drawOval(
      Rect.fromCenter(center: leftCheek, width: size.width * 0.08, height: size.width * 0.04),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: rightCheek, width: size.width * 0.08, height: size.width * 0.04),
      blushPaint,
    );

    // 2. FOREHEAD VISOR COGNITIVE PULSE
    final visorCenter = Offset(size.width * 0.540, size.height * 0.230);
    final visorGlow = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.30 + (breathe * 0.15).clamp(0.0, 0.30))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(visorCenter, size.width * 0.045, visorGlow);

    if (isHappy) {
      // 3. HAPPY SMILING ARC EYES ("^ ^")
      final arcPaint = Paint()
        ..color = const Color(0xFF55EEFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1);

      // Left happy arc over left eye
      final leftRect = Rect.fromCenter(center: leftEye, width: leftEyeW * 0.9, height: leftEyeH * 0.85);
      canvas.drawArc(leftRect, pi * 1.15, pi * 0.70, false, arcPaint);

      // Right happy arc over right eye
      final rightRect = Rect.fromCenter(center: rightEye, width: rightEyeW * 0.9, height: rightEyeH * 0.85);
      canvas.drawArc(rightRect, pi * 1.15, pi * 0.70, false, arcPaint);
      return;
    }

    // 4. NATURAL EYE BLINKING EYELIDS (Aligned exactly over real eyes)
    if (blinkProgress > 0.05) {
      final shutterFraction = blinkProgress.clamp(0.0, 1.0);
      final eyelidPaint = Paint()
        ..color = const Color(0xFFE2E7F3)
        ..style = PaintingStyle.fill;

      final eyelidSeamPaint = Paint()
        ..color = AppColors.cyanLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1);

      // Draw shutter over left eye
      final leftEyelidRect = Rect.fromCenter(
        center: leftEye,
        width: leftEyeW,
        height: leftEyeH * shutterFraction,
      );
      canvas.drawOval(leftEyelidRect, eyelidPaint);
      if (shutterFraction > 0.55) {
        canvas.drawLine(
          Offset(leftEye.dx - leftEyeW * 0.42, leftEye.dy + (leftEyeH * shutterFraction * 0.40)),
          Offset(leftEye.dx + leftEyeW * 0.42, leftEye.dy + (leftEyeH * shutterFraction * 0.40)),
          eyelidSeamPaint,
        );
      }

      // Draw shutter over right eye
      final rightEyelidRect = Rect.fromCenter(
        center: rightEye,
        width: rightEyeW,
        height: rightEyeH * shutterFraction,
      );
      canvas.drawOval(rightEyelidRect, eyelidPaint);
      if (shutterFraction > 0.55) {
        canvas.drawLine(
          Offset(rightEye.dx - rightEyeW * 0.42, rightEye.dy + (rightEyeH * shutterFraction * 0.40)),
          Offset(rightEye.dx + rightEyeW * 0.42, rightEye.dy + (rightEyeH * shutterFraction * 0.40)),
          eyelidSeamPaint,
        );
      }
    } else {
      // 5. CURIOUS PUPIL GLANCE SPARKLES
      final glanceOffset = Offset(glanceX * 3.5, glanceY * 2.5);
      final sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);

      canvas.drawCircle(leftEye + glanceOffset + const Offset(1, -2), 2.2, sparklePaint);
      canvas.drawCircle(rightEye + glanceOffset + const Offset(1, -2), 2.2, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NovaFacePainter old) {
    return old.blinkProgress != blinkProgress ||
        old.glanceX != glanceX ||
        old.glanceY != glanceY ||
        old.isHappy != isHappy ||
        old.breathe != breathe;
  }
}

/// Custom painter for the glowing 3D perspective holographic platform ring
class _HologramRingPainter extends CustomPainter {
  final double rotation;
  final double intensity;

  _HologramRingPainter({required this.rotation, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radiusX = size.width * 0.46;
    final radiusY = size.height * 0.46;

    // Outer ambient glowing ellipse
    final ambientPaint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.25 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final rect = Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2);
    canvas.drawOval(rect, ambientPaint);

    // Outer crisp beveled ring
    final ringPaint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.70 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawOval(rect, ringPaint);

    // Inner bright beam core
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final innerRect = Rect.fromCenter(center: center, width: radiusX * 1.55, height: radiusY * 1.55);
    canvas.drawOval(innerRect, innerPaint);

    // Orbiting holographic energy nodes
    const particleCount = 4;
    final motePaint = Paint()..color = AppColors.cyanLight;
    final haloPaint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < particleCount; i++) {
      final angle = rotation + (i * 2 * pi / particleCount);
      final px = center.dx + (radiusX * cos(angle));
      final py = center.dy + (radiusY * sin(angle));
      canvas.drawCircle(Offset(px, py), 4.0, haloPaint);
      canvas.drawCircle(Offset(px, py), 2.4, motePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HologramRingPainter old) =>
      old.rotation != rotation || old.intensity != intensity;
}
