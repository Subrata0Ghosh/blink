import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../services/leaderboard_service.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/particles/particles.dart';

/// Local Wi-Fi / Portable Hotspot Peer-to-Peer Game Screen (Connect 2 phones without internet)
class P2pRoomScreen extends ConsumerStatefulWidget {
  const P2pRoomScreen({super.key});

  @override
  ConsumerState<P2pRoomScreen> createState() => _P2pRoomScreenState();
}

class _P2pRoomScreenState extends ConsumerState<P2pRoomScreen> with TickerProviderStateMixin {
  final MultiplayerService _service = MultiplayerService();
  final TextEditingController _ipController = TextEditingController();

  int _selectedTab = 0; // 0: Host, 1: Join
  bool _isHosting = false;
  bool _isConnecting = false;
  String? _hostIp;

  StreamSubscription? _msgSub;

  // In-Game P2P state
  bool _inGame = false;
  String _gamePhase = 'waiting'; // 'observe', 'blink', 'spot', 'result', 'game_over'
  int _roundNumber = 1;
  int _myScore = 0;
  int _oppScore = 0;
  int _countdown = 3;
  Timer? _countdownTimer;

  int _changedIndex = 0;
  List<int> _objectColors = [];
  int? _shiftedColor;

  late AnimationController _blinkAnim;

  final List<Color> _palette = const [
    Color(0xFF00E5FF),
    Color(0xFFFF3366),
    Color(0xFFFFD700),
    Color(0xFF00E676),
  ];

  @override
  void initState() {
    super.initState();
    _blinkAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _msgSub = _service.onMessage?.listen(_handleP2PMessage);

    // Initial check for local IP
    MultiplayerService.getLocalIpAddress().then((ip) {
      if (mounted && ip != null) {
        setState(() {
          _hostIp = ip;
          // Set default join address to same subnet
          final parts = ip.split('.');
          if (parts.length == 4) {
            _ipController.text = '${parts[0]}.${parts[1]}.${parts[2]}.1';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _msgSub?.cancel();
    _service.disconnect();
    _ipController.dispose();
    _blinkAnim.dispose();
    super.dispose();
  }

  void _startHosting() async {
    final player = ref.read(gameStateProvider);
    setState(() => _isHosting = true);

    final ip = await _service.startHostRoom(myName: player.displayName);
    if (mounted) {
      setState(() {
        _hostIp = ip;
      });
      _msgSub?.cancel();
      _msgSub = _service.onMessage?.listen(_handleP2PMessage);
    }
  }

  void _joinHost() async {
    final player = ref.read(gameStateProvider);
    final targetIp = _ipController.text.trim();
    if (targetIp.isEmpty) return;

    setState(() => _isConnecting = true);
    triggerHaptic(ref, HapticService.mediumTap);

    final success = await _service.joinHostRoom(
      hostAddress: targetIp,
      myName: player.displayName,
    );

    if (mounted) {
      setState(() => _isConnecting = false);
      if (success) {
        AudioService().playUiConfirm();
        _msgSub?.cancel();
        _msgSub = _service.onMessage?.listen(_handleP2PMessage);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not connect to $targetIp. Make sure both phones are on same Wi-Fi / Hotspot!',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFF991B1B),
          ),
        );
      }
    }
  }

  void _startP2PMatch() {
    if (!_service.isHost || !_service.isConnected) return;

    _myScore = 0;
    _oppScore = 0;
    _roundNumber = 1;

    _broadcastStartRound();
  }

  void _broadcastStartRound() {
    final rand = Random();
    final seed = rand.nextInt(100000);
    _changedIndex = rand.nextInt(4);

    _service.sendMessage({
      'type': 'start_round',
      'round': _roundNumber,
      'seed': seed,
      'changedIndex': _changedIndex,
    });

    _setupRound(seed: seed, changedIndex: _changedIndex);
  }

  void _setupRound({required int seed, required int changedIndex}) {
    final rand = Random(seed);
    _objectColors = List.generate(4, (_) => rand.nextInt(_palette.length));
    _changedIndex = changedIndex;

    // Determine shifted color
    final originalColorIndex = _objectColors[_changedIndex];
    _shiftedColor = (originalColorIndex + 1) % _palette.length;

    setState(() {
      _inGame = true;
      _gamePhase = 'observe';
      _countdown = 3;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _triggerP2PBlink();
      }
    });
  }

  void _triggerP2PBlink() async {
    setState(() => _gamePhase = 'blink');
    triggerHaptic(ref, HapticService.mediumTap);

    await _blinkAnim.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    await _blinkAnim.reverse();

    if (mounted) {
      setState(() => _gamePhase = 'spot');
    }
  }

  void _tapGuess(int tappedIndex) {
    if (_gamePhase != 'spot') return;

    final isCorrect = tappedIndex == _changedIndex;
    final player = ref.read(gameStateProvider);

    _service.sendMessage({
      'type': 'player_answer',
      'playerName': player.displayName,
      'correct': isCorrect,
    });

    _resolveRound(winnerIsMe: isCorrect, responderName: player.displayName);
  }

  void _resolveRound({required bool winnerIsMe, required String responderName}) {
    if (winnerIsMe) {
      _myScore++;
      triggerHaptic(ref, HapticService.correctAnswer);
      AudioService().playLevelUp();
    } else {
      _oppScore++;
      triggerHaptic(ref, HapticService.lightTap);
      AudioService().playUiBack();
    }

    setState(() => _gamePhase = 'result');

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (_myScore >= 2 || _oppScore >= 2) {
        setState(() => _gamePhase = 'game_over');
        final player = ref.read(gameStateProvider);
        LeaderboardService.recordDuelResult(
          winner: _myScore >= 2 ? player.displayName : _service.opponentName,
          loser: _myScore >= 2 ? _service.opponentName : player.displayName,
          scoreWinner: max(_myScore, _oppScore),
          scoreLoser: min(_myScore, _oppScore),
        );
      } else if (_service.isHost) {
        _roundNumber++;
        _broadcastStartRound();
      }
    });
  }

  void _handleP2PMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == 'start_round') {
      final round = msg['round'] as int? ?? 1;
      final seed = msg['seed'] as int? ?? 42;
      final changedIndex = msg['changedIndex'] as int? ?? 0;
      _roundNumber = round;
      _setupRound(seed: seed, changedIndex: changedIndex);
    } else if (type == 'player_answer') {
      final isCorrect = msg['correct'] as bool? ?? false;
      final responder = msg['playerName'] as String? ?? 'Opponent';
      // If opponent got it right, opponent won. If opponent missed, I won!
      _resolveRound(winnerIsMe: !isCorrect, responderName: responder);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarField(starCount: 40),

          SafeArea(
            child: _inGame ? _buildInGameView() : _buildLobbyView(),
          ),

          // Blink effect overlay
          if (_gamePhase == 'blink')
            FadeTransition(
              opacity: _blinkAnim,
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

  Widget _buildLobbyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              TactileButton.circle(
                size: 40,
                faceColorTop: const Color(0xFF252E4C),
                faceColorBottom: const Color(0xFF13182B),
                rimColor: const Color(0xFF080C18),
                onTap: () {
                  AudioService().playUiBack();
                  context.pop();
                },
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOCAL WI-FI / HOTSPOT',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Play together on 2 separate devices offline',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Mode Switch Tabs (Host vs Join)
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF13182B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF253354)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildLobbyTab(index: 0, label: '📡 HOST ROOM'),
                ),
                Expanded(
                  child: _buildLobbyTab(index: 1, label: '🔗 JOIN ROOM'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (_selectedTab == 0) _buildHostCard() else _buildJoinCard(),

          const SizedBox(height: 24),

          // How It Works Guide Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1424),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF202C48)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.cyan, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'HOW OFFLINE P2P WORKS',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cyan,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '1. Turn on Wi-Fi on both phones OR turn on Mobile Hotspot on Phone 1 and connect Phone 2 to it.\n'
                  '2. No cellular data or active internet needed!\n'
                  '3. Phone 1 taps Host Room; Phone 2 enters Phone 1\'s IP and taps Connect.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLobbyTab({required int index, required String label}) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        triggerHaptic(ref, HapticService.lightTap);
        setState(() => _selectedTab = index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: active ? AppColors.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? const Color(0xFF081224) : AppColors.textMuted,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildHostCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13182B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOSTING AN OFFLINE ROOM',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.cyan,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your Room IP Address:',
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A395C)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _hostIp ?? 'Detecting IP...',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Port 8888',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.cyan),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_isHosting)
            TactileButton.cosmic(
              label: 'OPEN ROOM FOR PLAYERS',
              height: 50,
              fontSize: 14,
              width: double.infinity,
              onTap: _startHosting,
            )
          else ...[
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.cyan),
                ),
                const SizedBox(width: 12),
                Text(
                  _service.isConnected
                      ? 'Player Connected: ${_service.opponentName}!'
                      : 'Waiting for player to connect...',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _service.isConnected ? AppColors.success : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_service.isConnected)
              TactileButton.cosmic(
                label: 'START DUEL MATCH ⚔️',
                height: 52,
                fontSize: 15,
                width: double.infinity,
                onTap: _startP2PMatch,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildJoinCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13182B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF5277).withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JOIN A ROOM',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFF5277),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Enter Host Phone\'s IP Address:',
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _ipController,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. 192.168.43.1',
              hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
              filled: true,
              fillColor: const Color(0xFF0A0E1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2A395C)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          TactileButton(
            label: _isConnecting
                ? 'CONNECTING...'
                : (_service.isConnected ? 'CONNECTED TO HOST! ✅' : 'CONNECT TO HOST 🔗'),
            height: 50,
            fontSize: 14,
            width: double.infinity,
            faceColorTop: const Color(0xFFFF5277),
            faceColorBottom: const Color(0xFFB51036),
            rimColor: const Color(0xFF6B061D),
            onTap: () {
              if (!_isConnecting && !_service.isConnected) {
                _joinHost();
              }
            },
          ),
          if (_service.isConnected) ...[
            const SizedBox(height: 12),
            Text(
              'Connected to ${_service.opponentName}! Waiting for Host to start match...',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.cyan,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInGameView() {
    if (_gamePhase == 'game_over') {
      final iWon = _myScore >= 2;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (iWon ? AppColors.cyan : const Color(0xFFFF5277)).withValues(alpha: 0.5),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(iWon ? AppAssets.novaHappy : AppAssets.novaIdle),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                iWon ? 'VICTORY!' : 'DEFEAT',
                style: GoogleFonts.outfit(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: iWon ? AppColors.cyan : const Color(0xFFFF5277),
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Final: You $_myScore - $_oppScore ${_service.opponentName}',
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 28),
              TactileButton.cosmic(
                label: 'RETURN TO LOBBY',
                height: 50,
                fontSize: 15,
                width: double.infinity,
                onTap: () {
                  setState(() => _inGame = false);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Top Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF10162B),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOU: $_myScore',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyan,
                ),
              ),
              Text(
                'ROUND $_roundNumber',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
              Text(
                '${_service.opponentName}: $_oppScore',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFF5277),
                ),
              ),
            ],
          ),
        ),

        // Phase prompt
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: const Color(0xFF090D1A),
          child: Center(
            child: Text(
              _gamePhase == 'observe'
                  ? 'OBSERVE! ($_countdown s)'
                  : (_gamePhase == 'spot' ? 'TAP WHAT CHANGED!' : 'ROUND RESULT!'),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _gamePhase == 'spot' ? AppColors.cyan : AppColors.gold,
              ),
            ),
          ),
        ),

        // Arena
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
                if (_objectColors.length < 4) return const SizedBox();

                Color color = _palette[_objectColors[index]];
                if (_gamePhase != 'observe' && index == _changedIndex && _shiftedColor != null) {
                  color = _palette[_shiftedColor!];
                }

                return GestureDetector(
                  onTap: () => _tapGuess(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF151C33),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: color.withValues(alpha: 0.6), width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.diamond_rounded,
                        size: 54,
                        color: color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
