import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../gameplay/challenge_engine/challenge_engine.dart';
import '../../gameplay/challenge_engine/game_objects.dart';
import '../../widgets/particles/particles.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../core/constants/app_assets.dart';

/// Play screen — the core gameplay loop
class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> with TickerProviderStateMixin {
  final ChallengeEngine _engine = ChallengeEngine();
  Challenge? _challenge;
  int _round = 1;
  int _combo = 0;
  int _score = 0;
  int _totalXp = 0;
  int _totalGems = 0;
  int _correctCount = 0;

  // Phase management
  _GamePhase _phase = _GamePhase.intro;
  Timer? _timer;
  double _timeLeft = 0;
  DateTime? _answerStartTime;

  // Animations
  late AnimationController _countdownController;
  late AnimationController _sceneController;
  late AnimationController _feedbackController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  int _countdownValue = 3;
  bool _showPerfect = false;
  bool _showEnergyRing = false;
  int? _selectedAnswer;
  bool? _lastAnswerCorrect;

  @override
  void initState() {
    super.initState();

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _sceneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _startRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownController.dispose();
    _sceneController.dispose();
    _feedbackController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startRound() {
    final player = ref.read(gameStateProvider);
    final mode = _engine.getRandomUnlockedMode(player.level);
    final difficulty = player.level + (_round - 1) * 2;

    setState(() {
      _challenge = _engine.generateChallenge(mode: mode, difficulty: difficulty);
      _phase = _GamePhase.intro;
      _selectedAnswer = null;
      _lastAnswerCorrect = null;
      _showPerfect = false;
      _showEnergyRing = false;
      _countdownValue = 3;
    });

    _runIntroSequence();
  }

  void _runIntroSequence() async {
    // Show mode name + instruction briefly
    await Future.delayed(const Duration(milliseconds: 800));

    // Countdown 3-2-1
    setState(() => _phase = _GamePhase.countdown);
    for (int i = 3; i >= 1; i--) {
      setState(() => _countdownValue = i);
      _countdownController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 700));
    }

    // Show scene
    setState(() => _phase = _GamePhase.observe);
    _sceneController.forward(from: 0);
    _timeLeft = _challenge!.observeTime;

    // Timer for observation
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _timeLeft -= 0.05;
        if (_timeLeft <= 0) {
          timer.cancel();
          _onObserveComplete();
        }
      });
    });
  }

  void _onObserveComplete() {
    if (_challenge!.modifiedScene != null) {
      // Show modified scene
      setState(() => _phase = _GamePhase.modified);
      _sceneController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _showAnswerPhase();
      });
    } else {
      _showAnswerPhase();
    }
  }

  void _showAnswerPhase() {
    setState(() {
      _phase = _GamePhase.answer;
      _timeLeft = _challenge!.answerTime;
      _answerStartTime = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _timeLeft -= 0.05;
        if (_timeLeft <= 0) {
          timer.cancel();
          _onAnswerTimeout();
        }
      });
    });
  }

  void _onAnswerSelected(int index) {
    if (_selectedAnswer != null) return;
    _timer?.cancel();

    final reactionTime = DateTime.now().difference(_answerStartTime!).inMilliseconds;
    final correct = index == _challenge!.correctAnswerIndex;

    setState(() {
      _selectedAnswer = index;
      _lastAnswerCorrect = correct;
    });

    if (correct) {
      _combo++;
      _correctCount++;
      final result = ref.read(gameStateProvider.notifier).processChallengeResult(
        correct: true,
        reactionTimeMs: reactionTime,
        currentCombo: _combo,
        challengeType: _challenge!.mode.name,
      );
      _totalXp += result.xpEarned;
      _totalGems += result.gemsEarned;
      _score += 100 + (_combo * 10);

      triggerHaptic(ref, HapticService.correctAnswer);

      if (result.isPerfect) {
        setState(() {
          _showPerfect = true;
          _showEnergyRing = true;
        });
        triggerHaptic(ref, HapticService.perfectAnswer);
      }

      _feedbackController.forward(from: 0);

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          if (_round >= 5) {
            _goToResult();
          } else {
            _round++;
            _startRound();
          }
        }
      });
    } else {
      _combo = 0;
      ref.read(gameStateProvider.notifier).processChallengeResult(
        correct: false,
        reactionTimeMs: reactionTime,
        currentCombo: 0,
        challengeType: _challenge!.mode.name,
      );
      triggerHaptic(ref, HapticService.wrongAnswer);
      _shakeController.forward(from: 0);

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          if (_round >= 5) {
            _goToResult();
          } else {
            _round++;
            _startRound();
          }
        }
      });
    }
  }

  void _onAnswerTimeout() {
    _onAnswerSelected(-1); // Treat timeout as wrong
  }

  void _goToResult() {
    context.pushReplacement('/result', extra: {
      'score': _score,
      'xp': _totalXp,
      'gems': _totalGems,
      'correct': _correctCount,
      'total': _round,
      'combo': _combo,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarField(starCount: 30),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
          // Energy ring overlay
          if (_showEnergyRing)
            Positioned.fill(
              child: EnergyRing(
                color: AppColors.cyan,
                onComplete: () => setState(() => _showEnergyRing = false),
              ),
            ),
          // Perfect text overlay
          if (_showPerfect)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.2),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Text(
                      'PERFECT',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.cyan,
                        letterSpacing: 6,
                        shadows: [
                          Shadow(
                            color: AppColors.cyan.withValues(alpha: 0.6),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onEnd: () {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) setState(() => _showPerfect = false);
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
            ),
          ),
          const Spacer(),
          // Round indicator
          Text(
            'ROUND $_round / 5',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          // Combo indicator
          if (_combo > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.2),
                    AppColors.amber.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Text(
                'x$_combo',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                ),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_phase) {
      case _GamePhase.intro:
        return _buildIntroPhase();
      case _GamePhase.countdown:
        return _buildCountdownPhase();
      case _GamePhase.observe:
        return _buildObservePhase(false);
      case _GamePhase.modified:
        return _buildObservePhase(true);
      case _GamePhase.answer:
        return _buildAnswerPhase();
    }
  }

  Widget _buildIntroPhase() {
    if (_challenge == null) return const SizedBox();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _challenge!.modeName,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.cyan,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _challenge!.instruction,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownPhase() {
    return Center(
      child: AnimatedBuilder(
        animation: _countdownController,
        builder: (context, _) {
          final scale = 1.0 + (1.0 - _countdownController.value) * 0.5;
          final opacity = 1.0 - _countdownController.value * 0.3;
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Text(
                '$_countdownValue',
                style: GoogleFonts.outfit(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyan,
                  shadows: [
                    Shadow(
                      color: AppColors.cyan.withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildObservePhase(bool showModified) {
    if (_challenge == null) return const SizedBox();
    final scene = showModified ? (_challenge!.modifiedScene ?? _challenge!.originalScene) : _challenge!.originalScene;

    return Column(
      children: [
        // Timer bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _buildTimerBar(),
        ),
        const SizedBox(height: 8),
        if (showModified)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'What changed?',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
          ),
        // Scene
        Expanded(
          child: AnimatedBuilder(
            animation: _sceneController,
            builder: (context, child) {
              return Opacity(
                opacity: _sceneController.value,
                child: Transform.scale(
                  scale: 0.9 + _sceneController.value * 0.1,
                  child: child,
                ),
              );
            },
            child: _buildScene(scene),
          ),
        ),
      ],
    );
  }

  Widget _buildScene(List<GameObject> objects) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Scene background
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
              ),
            ),
            // Objects
            ...objects.map((obj) {
              final x = 16 + obj.position.dx * (constraints.maxWidth - 32);
              final y = 16 + obj.position.dy * (constraints.maxHeight - 32);
              return Positioned(
                left: x - 25,
                top: y - 25,
                child: _buildGameObject(obj),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildGameObject(GameObject obj) {
    final size = 52.0 * obj.size;
    String? assetPath;
    if (obj.type == GameObjectType.orb) {
      assetPath = AppAssets.gameOrb;
    } else if (obj.type == GameObjectType.cube) {
      assetPath = AppAssets.gameCube;
    } else if (obj.type == GameObjectType.crystal) {
      assetPath = AppAssets.shiftGem;
    }

    if (assetPath != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: obj.type == GameObjectType.orb ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: obj.type == GameObjectType.cube ? BorderRadius.circular(10) : null,
          boxShadow: [
            BoxShadow(
              color: obj.color.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(obj.type == GameObjectType.cube ? 10 : size / 2),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            color: obj.color.withValues(alpha: 0.35),
            colorBlendMode: BlendMode.color,
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GameObjectPainter(obj),
      ),
    );
  }

  Widget _buildAnswerPhase() {
    if (_challenge == null) return const SizedBox();

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = sin(_shakeAnimation.value * pi * 6) * 8 * (1 - _shakeAnimation.value);
        return Transform.translate(
          offset: Offset(_lastAnswerCorrect == false ? shakeOffset : 0, 0),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Timer bar
            _buildTimerBar(),
            const SizedBox(height: 24),
            // Question
            Text(
              _challenge!.question,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            // Answer buttons
            ..._challenge!.answers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAnswerButton(entry.key, entry.value),
              );
            }),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton(int index, String text) {
    final isSelected = _selectedAnswer == index;
    final isCorrect = index == _challenge!.correctAnswerIndex;
    final showResult = _selectedAnswer != null;

    Color bgColor = AppColors.surfaceLight;
    Color borderColor = AppColors.glassBorder;
    Color textColor = AppColors.textPrimary;

    if (showResult) {
      if (isCorrect) {
        bgColor = AppColors.success.withValues(alpha: 0.15);
        borderColor = AppColors.success;
        textColor = AppColors.success;
      } else if (isSelected && !isCorrect) {
        bgColor = AppColors.error.withValues(alpha: 0.15);
        borderColor = AppColors.error;
        textColor = AppColors.error;
      }
    }

    return GestureDetector(
      onTap: () => _onAnswerSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected && isCorrect
              ? [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 12)]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            if (showResult && isCorrect)
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
            if (showResult && isSelected && !isCorrect)
              Icon(Icons.cancel_rounded, color: AppColors.error, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBar() {
    final maxTime = _phase == _GamePhase.observe
        ? _challenge!.observeTime
        : _challenge!.answerTime;
    final progress = maxTime > 0 ? (_timeLeft / maxTime).clamp(0.0, 1.0) : 0.0;
    final isLow = progress < 0.25;

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 4,
        backgroundColor: AppColors.surfaceLight,
        valueColor: AlwaysStoppedAnimation<Color>(
          isLow ? AppColors.error : AppColors.cyan,
        ),
      ),
    );
  }
}

// ── Game object painter ──
class _GameObjectPainter extends CustomPainter {
  final GameObject obj;
  _GameObjectPainter(this.obj);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final paint = Paint()..color = obj.color;
    final glowPaint = Paint()
      ..color = obj.color.withValues(alpha: 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4);

    // Draw glow
    canvas.drawCircle(center, radius * 1.2, glowPaint);

    // Draw shape based on type
    switch (obj.type) {
      case GameObjectType.orb:
        final gradient = RadialGradient(
          colors: [obj.color, obj.color.withValues(alpha: 0.6)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
        canvas.drawCircle(center, radius, Paint()..shader = gradient);
        // Highlight
        canvas.drawCircle(
          center + Offset(-radius * 0.3, -radius * 0.3),
          radius * 0.2,
          Paint()..color = Colors.white.withValues(alpha: 0.5),
        );
        break;

      case GameObjectType.crystal:
      case GameObjectType.gem:
        final path = Path();
        path.moveTo(center.dx, center.dy - radius);
        path.lineTo(center.dx + radius * 0.7, center.dy);
        path.lineTo(center.dx, center.dy + radius);
        path.lineTo(center.dx - radius * 0.7, center.dy);
        path.close();
        canvas.drawPath(path, paint);
        break;

      case GameObjectType.cube:
        final rect = Rect.fromCenter(center: center, width: radius * 1.6, height: radius * 1.6);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );
        break;

      case GameObjectType.triangle:
        final path = Path();
        path.moveTo(center.dx, center.dy - radius);
        path.lineTo(center.dx + radius, center.dy + radius * 0.7);
        path.lineTo(center.dx - radius, center.dy + radius * 0.7);
        path.close();
        canvas.drawPath(path, paint);
        break;

      case GameObjectType.star:
        _drawStar(canvas, center, radius, 5, paint);
        break;

      case GameObjectType.moon:
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(
          center + Offset(radius * 0.4, -radius * 0.2),
          radius * 0.7,
          Paint()..color = AppColors.surface,
        );
        break;

      case GameObjectType.ring:
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = obj.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius * 0.3,
        );
        break;

      case GameObjectType.leaf:
        final path = Path();
        path.moveTo(center.dx, center.dy - radius);
        path.quadraticBezierTo(center.dx + radius * 1.2, center.dy, center.dx, center.dy + radius);
        path.quadraticBezierTo(center.dx - radius * 1.2, center.dy, center.dx, center.dy - radius);
        path.close();
        canvas.drawPath(path, paint);
        break;

      case GameObjectType.bolt:
        final path = Path();
        path.moveTo(center.dx, center.dy - radius);
        path.lineTo(center.dx + radius * 0.5, center.dy - radius * 0.1);
        path.lineTo(center.dx + radius * 0.1, center.dy + radius * 0.1);
        path.lineTo(center.dx + radius * 0.6, center.dy + radius);
        path.lineTo(center.dx - radius * 0.1, center.dy + radius * 0.2);
        path.lineTo(center.dx - radius * 0.3, center.dy - radius * 0.1);
        path.close();
        canvas.drawPath(path, paint);
        break;
    }

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: obj.type.label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy + radius + 4));
  }

  void _drawStar(Canvas canvas, Offset center, double radius, int points, Paint paint) {
    final path = Path();
    final angleStep = pi / points;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = -pi / 2 + i * angleStep;
      final point = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GameObjectPainter old) => false;
}

enum _GamePhase {
  intro,
  countdown,
  observe,
  modified,
  answer,
}
