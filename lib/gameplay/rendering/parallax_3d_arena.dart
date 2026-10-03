import 'package:flutter/material.dart';

/// 2.5D Parallax 3D Perspective Tilt Container
/// Dynamically tilts the arena and its celestial objects along the X and Y axes
/// in response to player finger movement, creating an authentic 3D physical depth sensation.
class Parallax3dArena extends StatefulWidget {
  final Widget child;
  final double maxTiltAngle;
  final bool enabled;

  const Parallax3dArena({
    super.key,
    required this.child,
    this.maxTiltAngle = 0.12, // ~7 degrees of 3D perspective tilt
    this.enabled = true,
  });

  @override
  State<Parallax3dArena> createState() => _Parallax3dArenaState();
}

class _Parallax3dArenaState extends State<Parallax3dArena>
    with SingleTickerProviderStateMixin {
  late final AnimationController _springController;
  late Animation<double> _rotXAnimation;
  late Animation<double> _rotYAnimation;

  double _currentRotX = 0.0;
  double _currentRotY = 0.0;
  double _targetRotX = 0.0;
  double _targetRotY = 0.0;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rotXAnimation = const AlwaysStoppedAnimation(0.0);
    _rotYAnimation = const AlwaysStoppedAnimation(0.0);
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerMoveEvent event, Size size) {
    if (!widget.enabled || size.width == 0 || size.height == 0) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Normalized offset from center: -1.0 to +1.0
    final normX = ((event.localPosition.dx - centerX) / centerX).clamp(-1.0, 1.0);
    final normY = ((event.localPosition.dy - centerY) / centerY).clamp(-1.0, 1.0);

    setState(() {
      _currentRotY = normX * widget.maxTiltAngle;
      _currentRotX = -normY * widget.maxTiltAngle;
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!widget.enabled) return;
    _springBackToCenter();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (!widget.enabled) return;
    _springBackToCenter();
  }

  void _springBackToCenter() {
    _targetRotX = 0.0;
    _targetRotY = 0.0;

    _rotXAnimation = Tween<double>(begin: _currentRotX, end: _targetRotX).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );
    _rotYAnimation = Tween<double>(begin: _currentRotY, end: _targetRotY).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );

    _springController.forward(from: 0.0).then((_) {
      _currentRotX = 0.0;
      _currentRotY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerMove: (e) => _onPointerMove(e, size),
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: AnimatedBuilder(
            animation: _springController,
            builder: (context, child) {
              final rotX = _springController.isAnimating
                  ? _rotXAnimation.value
                  : _currentRotX;
              final rotY = _springController.isAnimating
                  ? _rotYAnimation.value
                  : _currentRotY;

              // 3D Perspective Matrix
              final matrix = Matrix4.identity()
                ..setEntry(3, 2, 0.0012) // Z-perspective depth
                ..rotateX(rotX)
                ..rotateY(rotY);

              return Transform(
                alignment: FractionalOffset.center,
                transform: matrix,
                child: child,
              );
            },
            child: widget.child,
          ),
        );
      },
    );
  }
}
