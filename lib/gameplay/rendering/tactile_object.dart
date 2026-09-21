import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../challenge_engine/game_objects.dart';
import '../../services/haptic_service.dart';
import 'gem_2d5_painter.dart';
import 'star_2d5_painter.dart';
import 'moon_2d5_painter.dart';
import 'object_2d5_painter.dart';

/// Tactile 2.5D Game Object Component for BLINK
/// Features:
/// - Living idle motion (sinusoidal float, scale breathing, pendulum rotation)
/// - Dynamic contact shadow responding to float elevation
/// - Staggered spawn materialization with spring overshoot
/// - Physics-like squash, stretch, and bounce on tap
/// - Tap particle bursts and glow pulses
/// - Smooth interpolation for position/rotation/scale changes
/// - No flat PNG images; fully procedural 2.5D rendering
class TactileObject extends ConsumerStatefulWidget {
  final GameObject gameObject;
  final double baseSize;
  final int spawnIndex;
  final bool isSpawning;
  final VoidCallback? onTap;
  final bool showDebugLabel;

  const TactileObject({
    super.key,
    required this.gameObject,
    this.baseSize = 64.0,
    this.spawnIndex = 0,
    this.isSpawning = false,
    this.onTap,
    this.showDebugLabel = false,
  });

  @override
  ConsumerState<TactileObject> createState() => _TactileObjectState();
}

class _TactileObjectState extends ConsumerState<TactileObject>
    with TickerProviderStateMixin {
  // Idle breathing / rotation / particle cycle
  late AnimationController _idleController;

  // Tap squash & bounce controller
  late AnimationController _tapController;
  late Animation<double> _squashScaleX;
  late Animation<double> _squashScaleY;

  // Staggered spawn entrance controller
  late AnimationController _spawnController;
  late Animation<double> _spawnScale;
  late Animation<double> _spawnOpacity;

  bool _isPressed = false;
  double _glowBurst = 0.0;

  @override
  void initState() {
    super.initState();

    // 1. Continuous Idle Controller (varied duration per index to avoid rigid sync)
    final idleDurationMs = 2800 + (widget.spawnIndex % 4) * 300;
    _idleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: idleDurationMs),
    )..repeat();

    // 2. Tap Squash & Stretch Animation
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _squashScaleX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.16).chain(CurveTween(curve: Curves.easeOutQuad)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.16, end: 0.94).chain(CurveTween(curve: Curves.easeInOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
    ]).animate(_tapController);

    _squashScaleY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.84).chain(CurveTween(curve: Curves.easeOutQuad)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.84, end: 1.06).chain(CurveTween(curve: Curves.easeInOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
    ]).animate(_tapController);

    // 3. Staggered Spawn Controller
    _spawnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _spawnScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _spawnController, curve: Curves.easeOutBack),
    );
    _spawnOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _spawnController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _runSpawnSequence();
  }

  void _runSpawnSequence() async {
    if (widget.isSpawning) {
      final delay = widget.spawnIndex * 110;
      await Future.delayed(Duration(milliseconds: delay));
      if (mounted) {
        _spawnController.forward(from: 0.0);
      }
    } else {
      _spawnController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant TactileObject oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpawning && !oldWidget.isSpawning) {
      _spawnController.reset();
      _runSpawnSequence();
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _tapController.dispose();
    _spawnController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
      _glowBurst = 1.0;
    });
    _tapController.forward(from: 0.0);
    triggerHaptic(ref, HapticService.lightTap);
    widget.onTap?.call();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSize = widget.baseSize * widget.gameObject.size;

    return AnimatedBuilder(
      animation: Listenable.merge([_idleController, _tapController, _spawnController]),
      builder: (context, child) {
        final t = _idleController.value;

        // Idle levitation & breathing
        final floatOffsetY = sin((t * 2 * pi) + (widget.spawnIndex * 1.2)) * 4.5;
        final idleScale = 1.0 + 0.03 * sin((t * 2 * pi) + (widget.spawnIndex * 0.8));
        // Pendulum rotation (3 to 6 degrees)
        final idleRotation = widget.gameObject.rotation + (sin(t * 2 * pi) * 0.07);

        // Spawn transforms
        final spawnScaleVal = _spawnScale.value;
        final spawnOpacityVal = _spawnOpacity.value;

        if (spawnScaleVal <= 0.01 && widget.isSpawning) {
          return const SizedBox();
        }

        // Combined scales
        final finalScaleX = spawnScaleVal * idleScale * _squashScaleX.value;
        final finalScaleY = spawnScaleVal * idleScale * _squashScaleY.value;

        // 3D perspective pitch, yaw, and roll rotation
        final idleTiltX = sin((t * 2 * pi) + (widget.spawnIndex * 0.7)) * 0.10;
        final idleTiltY = cos((t * 2 * pi) + (widget.spawnIndex * 0.9)) * 0.12;

        final object3dMatrix = Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateX(idleTiltX)
          ..rotateY(idleTiltY)
          ..rotateZ(idleRotation)
          ..multiply(Matrix4.diagonal3Values(finalScaleX, finalScaleY, 1.0));

        return Opacity(
          opacity: spawnOpacityVal.clamp(0.0, 1.0),
          child: SizedBox(
            width: effectiveSize + 28,
            height: effectiveSize + 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Dynamic Contact Shadow on arena plane
                Positioned(
                  bottom: 2,
                  child: _buildContactShadow(
                    size: effectiveSize,
                    floatOffset: floatOffsetY,
                    scaleX: finalScaleX,
                  ),
                ),

                // 2. Tactile Interactive Body
                Positioned(
                  top: 8 + floatOffsetY,
                  child: GestureDetector(
                    onTapDown: _handleTapDown,
                    onTapUp: _handleTapUp,
                    onTapCancel: _handleTapCancel,
                    behavior: HitTestBehavior.opaque,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: object3dMatrix,
                      child: SizedBox(
                        width: effectiveSize,
                        height: effectiveSize,
                        child: CustomPaint(
                          painter: _getPainter(t),
                          size: Size(effectiveSize, effectiveSize),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Debug Label (hidden in commercial gameplay)
                if (widget.showDebugLabel)
                  Positioned(
                    bottom: 0,
                    child: Text(
                      widget.gameObject.type.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.7),
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

  Widget _buildContactShadow({
    required double size,
    required double floatOffset,
    required double scaleX,
  }) {
    // When object floats up: shadow is wider, blurrier, and lower opacity
    // When object is closer to arena: shadow is darker, sharper, and slightly smaller
    final normalizedElevation = ((floatOffset + 5) / 10).clamp(0.0, 1.0);
    final shadowWidth = (size * 0.75 * (0.85 + 0.25 * normalizedElevation) * scaleX).clamp(10.0, 120.0);
    final shadowHeight = (size * 0.22 * (0.85 + 0.2 * normalizedElevation)).clamp(4.0, 30.0);
    final shadowOpacity = (0.55 - 0.22 * normalizedElevation).clamp(0.15, 0.7);

    return Container(
      width: shadowWidth,
      height: shadowHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.elliptical(shadowWidth / 2, shadowHeight / 2)),
        gradient: RadialGradient(
          colors: [
            Colors.black.withValues(alpha: shadowOpacity),
            Colors.black.withValues(alpha: shadowOpacity * 0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );
  }

  CustomPainter _getPainter(double idleProgress) {
    final color = widget.gameObject.color;
    final glow = (_isPressed ? 1.0 : 0.6) + (_glowBurst * 0.4);

    switch (widget.gameObject.type) {
      case GameObjectType.gem:
        return Gem2d5Painter(
          baseColor: color,
          animationProgress: idleProgress,
          glowIntensity: glow,
          isPressed: _isPressed,
        );
      case GameObjectType.star:
        return Star2d5Painter(
          baseColor: color,
          animationProgress: idleProgress,
          glowIntensity: glow,
          isPressed: _isPressed,
        );
      case GameObjectType.moon:
        return Moon2d5Painter(
          baseColor: color,
          animationProgress: idleProgress,
          glowIntensity: glow,
          isPressed: _isPressed,
        );
      default:
        return Object2d5Painter(
          type: widget.gameObject.type,
          baseColor: color,
          animationProgress: idleProgress,
          glowIntensity: glow,
          isPressed: _isPressed,
        );
    }
  }
}
