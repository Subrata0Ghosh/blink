import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../services/app_review_share_service.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../services/leaderboard_service.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/particles/particles.dart';

enum DuelPhase {
  setup,
  observe,
  blink,
  spot,
  roundResult,
  matchOver,
}

class _DuelObject {
  final int id;
  final String shape; // 'star', 'crystal', 'ring', 'orb'
  final Color color;

  const _DuelObject({
    required this.id,
    required this.shape,
    required this.color,
  });

  _DuelObject copyWith({String? shape, Color? color}) {
    return _DuelObject(
      id: id,
      shape: shape ?? this.shape,
      color: color ?? this.color,
    );
  }
}

/// Same-Device 2-Player Offline Duel Screen (Pass & Play)
class LocalDuelScreen extends ConsumerStatefulWidget {
  const LocalDuelScreen({super.key});

  @override
  ConsumerState<LocalDuelScreen> createState() => _LocalDuelScreenState();
}

class _LocalDuelScreenState extends ConsumerState<LocalDuelScreen> with TickerProviderStateMixin {
  DuelPhase _phase = DuelPhase.setup;

  String _player1Name = 'Player 1';
  String _player2Name = 'Player 2';
  int _targetWins = 2; // Best of 3 (first to 2)

  int _p1Score = 0;
  int _p2Score = 0;
  int _currentRound = 1;

  int _countdown = 3;
  Timer? _roundTimer;

  List<_DuelObject> _originalObjects = [];
  List<_DuelObject> _currentObjects = [];
  int _changedIndex = 0;
  String _shiftDescription = '';

  int? _buzzedPlayer; // 1 or 2
  String _roundResultMessage = '';
  Color _roundResultColor = AppColors.cyan;

  late AnimationController _blinkAnimController;

  final List<Color> _palette = const [
    Color(0xFF00E5FF),
    Color(0xFFFF3366),
    Color(0xFFFFD700),
    Color(0xFF00E676),
    Color(0xFFB388FF),
  ];

  final List<String> _shapes = const ['star', 'crystal', 'ring', 'orb'];

  @override
  void initState() {
    super.initState();
    _blinkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Pre-populate Player 1 with active user's name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = ref.read(gameStateProvider);
      setState(() {
        _player1Name = player.displayName;
      });
    });
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _blinkAnimController.dispose();
    super.dispose();
  }

  void _startDuel() {
    _p1Score = 0;
    _p2Score = 0;
    _currentRound = 1;
    _startRound();
  }

  void _startRound() {
    _roundTimer?.cancel();
    _buzzedPlayer = null;

    // Generate 4 objects
    final rand = Random();
    final objects = <_DuelObject>[];
    for (int i = 0; i < 4; i++) {
      objects.add(_DuelObject(
        id: i,
        shape: _shapes[rand.nextInt(_shapes.length)],
        color: _palette[i % _palette.length],
      ));
    }

    _originalObjects = List.from(objects);
    _changedIndex = rand.nextInt(objects.length);

    // Create the shifted variant
    final target = objects[_changedIndex];
    final otherColors = _palette.where((c) => c != target.color).toList();
    final newColor = otherColors[rand.nextInt(otherColors.length)];

    _currentObjects = List.generate(objects.length, (i) {
      if (i == _changedIndex) {
        return target.copyWith(color: newColor);
      }
      return objects[i];
    });

    _shiftDescription = 'Color of item ${_changedIndex + 1} shifted!';

    setState(() {
      _phase = DuelPhase.observe;
      _countdown = 3;
    });

    AudioService().playUiConfirm();

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
        AudioService().playUiClick();
      } else {
        timer.cancel();
        _triggerBlink();
      }
    });
  }

  void _triggerBlink() async {
    setState(() => _phase = DuelPhase.blink);
    triggerHaptic(ref, HapticService.mediumTap);
    AudioService().playMysteryStinger();

    await _blinkAnimController.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    await _blinkAnimController.reverse();

    if (!mounted) return;
    setState(() {
      _phase = DuelPhase.spot;
    });
  }

  void _playerBuzzed(int playerIndex) {
    if (_buzzedPlayer != null) return;
    triggerHaptic(ref, HapticService.heavyTap);
    AudioService().playUiConfirm();

    setState(() {
      _buzzedPlayer = playerIndex;
    });
  }

  void _selectObjectGuess(int tappedIndex) {
    if (_phase != DuelPhase.spot || _buzzedPlayer == null) return;

    final isCorrect = tappedIndex == _changedIndex;
    final answeringPlayer = _buzzedPlayer!;

    if (isCorrect) {
      triggerHaptic(ref, HapticService.correctAnswer);
      AudioService().playLevelUp();
      if (answeringPlayer == 1) {
        _p1Score++;
        _roundResultMessage = '$_player1Name SPOTTED IT! (+1 Point)';
        _roundResultColor = AppColors.cyan;
      } else {
        _p2Score++;
        _roundResultMessage = '$_player2Name SPOTTED IT! (+1 Point)';
        _roundResultColor = const Color(0xFFFF5277);
      }
    } else {
      triggerHaptic(ref, HapticService.lightTap);
      AudioService().playUiBack();
      // Wrong guess awards point to other player
      if (answeringPlayer == 1) {
        _p2Score++;
        _roundResultMessage = '$_player1Name missed! +1 Point to $_player2Name';
        _roundResultColor = const Color(0xFFFF5277);
      } else {
        _p1Score++;
        _roundResultMessage = '$_player2Name missed! +1 Point to $_player1Name';
        _roundResultColor = AppColors.cyan;
      }
    }

    setState(() => _phase = DuelPhase.roundResult);

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (_p1Score >= _targetWins || _p2Score >= _targetWins) {
        _finishMatch();
      } else {
        _currentRound++;
        _startRound();
      }
    });
  }

  void _finishMatch() {
    final winner = _p1Score >= _targetWins ? _player1Name : _player2Name;
    final loser = _p1Score >= _targetWins ? _player2Name : _player1Name;
    final scoreWinner = max(_p1Score, _p2Score);
    final scoreLoser = min(_p1Score, _p2Score);

    // Save to leaderboard records
    LeaderboardService.recordDuelResult(
      winner: winner,
      loser: loser,
      scoreWinner: scoreWinner,
      scoreLoser: scoreLoser,
    );

    setState(() => _phase = DuelPhase.matchOver);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarField(starCount: 40),

          // Main body content depending on phase
          SafeArea(
            child: _buildPhaseContent(),
          ),

          // Blink blackout curtain
          if (_phase == DuelPhase.blink)
            FadeTransition(
              opacity: _blinkAnimController,
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Text(
                    'BLINK!',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.cyan,
                      letterSpacing: 6,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case DuelPhase.setup:
        return _buildSetupView();
      case DuelPhase.observe:
      case DuelPhase.blink:
      case DuelPhase.spot:
      case DuelPhase.roundResult:
        return _buildGameplayView();
      case DuelPhase.matchOver:
        return _buildMatchOverView();
    }
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              TactileButton.circle(
                size: 40,
                faceColorTop: const Color(0xFF252E4C),
                faceColorBottom: const Color(0xFF13182B),
                rimColor: const Color(0xFF080C18),
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 14),
              Text(
                'DUEL SETUP',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Player 1 Card (Cyan)
          _buildPlayerInputCard(
            playerNum: 1,
            title: 'PLAYER 1 (Cyan)',
            color: AppColors.cyan,
            defaultName: _player1Name,
            onChanged: (val) => _player1Name = val.trim().isEmpty ? 'Player 1' : val.trim(),
          ),

          const SizedBox(height: 16),

          // VS Medallion
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E2642),
              border: Border.all(color: const Color(0xFF3B4D7E), width: 1.5),
            ),
            child: Text(
              'VS',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Player 2 Card (Magenta)
          _buildPlayerInputCard(
            playerNum: 2,
            title: 'PLAYER 2 (Magenta)',
            color: const Color(0xFFFF5277),
            defaultName: _player2Name,
            onChanged: (val) => _player2Name = val.trim().isEmpty ? 'Player 2' : val.trim(),
          ),

          const SizedBox(height: 28),

          // Match Format Selector
          Text(
            'MATCH FORMAT',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFormatChip(label: 'Best of 3', targetWins: 2),
              const SizedBox(width: 14),
              _buildFormatChip(label: 'Best of 5', targetWins: 3),
            ],
          ),

          const SizedBox(height: 36),

          TactileButton.cosmic(
            label: 'START DUEL ⚔️',
            height: 56,
            fontSize: 18,
            width: double.infinity,
            onTap: _startDuel,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInputCard({
    required int playerNum,
    required String title,
    required Color color,
    required String defaultName,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13182B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: defaultName,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Enter name',
              hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
              filled: true,
              fillColor: const Color(0xFF0C101F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChip({required String label, required int targetWins}) {
    final active = _targetWins == targetWins;
    return GestureDetector(
      onTap: () => setState(() => _targetWins = targetWins),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.cyan.withValues(alpha: 0.25) : const Color(0xFF161E34),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppColors.cyan : const Color(0xFF2E3E66),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildGameplayView() {
    return Column(
      children: [
        // Top Player 2 Buzzer Zone (rotated or top banner)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF10162B),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF5277),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _player2Name,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '$_p2Score / $_targetWins',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFF5277),
                ),
              ),
            ],
          ),
        ),

        // Round & State Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: const Color(0xFF0A0F1E),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ROUND $_currentRound',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _phase == DuelPhase.observe
                    ? 'LOOK CAREFULLY! ($_countdown s)'
                    : _phase == DuelPhase.spot
                        ? (_buzzedPlayer == null
                            ? 'TAP YOUR BUZZER WHEN READY!'
                            : 'PLAYER $_buzzedPlayer BUZZED! TAP WHAT CHANGED!')
                        : '$_roundResultMessage${_shiftDescription.isNotEmpty ? ' • $_shiftDescription' : ''}',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _phase == DuelPhase.roundResult ? _roundResultColor : AppColors.gold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),

        // Arena: 4 Objects Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final displayObjects =
                    _phase == DuelPhase.observe ? _originalObjects : _currentObjects;
                if (displayObjects.isEmpty) return const SizedBox();

                final obj = displayObjects[index];
                return GestureDetector(
                  onTap: () => _selectObjectGuess(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF151C33),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: obj.color.withValues(alpha: 0.6),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: obj.color.withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _getIconForShape(obj.shape),
                        size: 58,
                        color: obj.color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Dual Buzzer Control Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Player 1 Buzzer
              Expanded(
                child: TactileButton(
                  label: _buzzedPlayer == 1 ? 'P1 BUZZED! 🔔' : 'P1 BUZZER',
                  height: 52,
                  fontSize: 14,
                  faceColorTop: AppColors.cyan,
                  faceColorBottom: const Color(0xFF007A99),
                  rimColor: const Color(0xFF004D60),
                  onTap: () {
                    if (_phase == DuelPhase.spot && _buzzedPlayer == null) {
                      _playerBuzzed(1);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Player 2 Buzzer
              Expanded(
                child: TactileButton(
                  label: _buzzedPlayer == 2 ? 'P2 BUZZED! 🔔' : 'P2 BUZZER',
                  height: 52,
                  fontSize: 14,
                  faceColorTop: const Color(0xFFFF5277),
                  faceColorBottom: const Color(0xFFBA133B),
                  rimColor: const Color(0xFF7A0924),
                  onTap: () {
                    if (_phase == DuelPhase.spot && _buzzedPlayer == null) {
                      _playerBuzzed(2);
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Bottom Player 1 Status Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF10162B),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _player1Name,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '$_p1Score / $_targetWins',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchOverView() {
    final winner = _p1Score >= _targetWins ? _player1Name : _player2Name;
    final loser = _p1Score >= _targetWins ? _player2Name : _player1Name;
    final winnerColor = _p1Score >= _targetWins ? AppColors.cyan : const Color(0xFFFF5277);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Nova Winner Mascot
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: winnerColor.withValues(alpha: 0.5),
                    blurRadius: 32,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(AppAssets.novaHappy, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'VICTORY!',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$winner WINS THE DUEL!',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: winnerColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Final Score: $_p1Score - $_p2Score',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),

            const SizedBox(height: 36),

            // Rematch Button
            TactileButton.cosmic(
              label: 'PLAY REMATCH ⚔️',
              height: 54,
              fontSize: 16,
              width: double.infinity,
              onTap: _startDuel,
            ),
            const SizedBox(height: 14),

            // Share Duel Victory
            TactileButton.nebula(
              label: 'SHARE DUEL RESULT 🚀',
              height: 50,
              fontSize: 15,
              width: double.infinity,
              onTap: () {
                AppReviewShareService.shareScore(
                  score: max(_p1Score, _p2Score),
                  combo: 0,
                  opponentName: loser,
                  isDuelVictory: true,
                );
              },
            ),
            const SizedBox(height: 14),

            // Return to Hub
            TactileButton.dark(
              label: 'RETURN TO HUB',
              height: 48,
              fontSize: 14,
              width: double.infinity,
              onTap: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForShape(String shape) {
    switch (shape) {
      case 'star':
        return Icons.star_rounded;
      case 'crystal':
        return Icons.diamond_rounded;
      case 'ring':
        return Icons.circle_outlined;
      case 'orb':
      default:
        return Icons.lens_rounded;
    }
  }
}
