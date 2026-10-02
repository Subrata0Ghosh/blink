import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../services/leaderboard_service.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/particles/particles.dart';

/// Hub for selecting offline multiplayer modes (Same Device or Local Wi-Fi P2P)
class MultiplayerHubScreen extends ConsumerStatefulWidget {
  const MultiplayerHubScreen({super.key});

  @override
  ConsumerState<MultiplayerHubScreen> createState() => _MultiplayerHubScreenState();
}

class _MultiplayerHubScreenState extends ConsumerState<MultiplayerHubScreen> {
  List<DuelRecord> _recentDuels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AudioService().startAmbientMusic();
    _loadDuelHistory();
  }

  Future<void> _loadDuelHistory() async {
    final records = await LeaderboardService.getDuelRecords();
    if (mounted) {
      setState(() {
        _recentDuels = records;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarField(starCount: 50),
          const FloatingParticles(count: 12, color: AppColors.cyan),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ──── HEADER ────
                  Row(
                    children: [
                      TactileButton.circle(
                        size: 42,
                        faceColorTop: const Color(0xFF252E4C),
                        faceColorBottom: const Color(0xFF13182B),
                        rimColor: const Color(0xFF080C18),
                        onTap: () {
                          AudioService().playUiBack();
                          context.pop();
                        },
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OFFLINE MULTIPLAYER',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'Play together without internet connection',
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

                  const SizedBox(height: 24),

                  // ──── HERO CARD: SAME-DEVICE DUEL (Pass & Play) ────
                  _buildModeCard(
                    title: 'SAME-DEVICE DUEL',
                    subtitle: 'Pass & Play on 1 phone. Real-time buzzers & perception challenge.',
                    badge: 'INSTANT • NO SETUP',
                    badgeColor: const Color(0xFF00E5FF),
                    gradientColors: [const Color(0xFF005266), const Color(0xFF0A1F38)],
                    borderColor: AppColors.cyan,
                    icon: Icons.splitscreen_rounded,
                    buttonLabel: 'START DUEL',
                    onTap: () {
                      triggerHaptic(ref, HapticService.mediumTap);
                      AudioService().playUiConfirm();
                      context.push('/local-duel');
                    },
                  ),

                  const SizedBox(height: 18),

                  // ──── HERO CARD: LOCAL WI-FI / HOTSPOT P2P ────
                  _buildModeCard(
                    title: 'LOCAL WI-FI / HOTSPOT',
                    subtitle: 'Connect 2 phones over local Wi-Fi or Hotspot. Zero data used.',
                    badge: '2 PHONES • ZERO DATA',
                    badgeColor: const Color(0xFFFF5277),
                    gradientColors: [const Color(0xFF6B1135), const Color(0xFF1E0A1E)],
                    borderColor: const Color(0xFFFF5277),
                    icon: Icons.wifi_tethering_rounded,
                    buttonLabel: 'HOST OR JOIN ROOM',
                    onTap: () {
                      triggerHaptic(ref, HapticService.mediumTap);
                      AudioService().playUiConfirm();
                      context.push('/p2p-room');
                    },
                  ),

                  const SizedBox(height: 24),

                  // ──── RECENT DUEL HISTORY HEADER ────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, color: AppColors.cyan, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'RECENT DUEL RECORDS',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push('/leaderboard'),
                        child: Text(
                          'Leaderboard →',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cyan,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: AppColors.cyan),
                      ),
                    )
                  else if (_recentDuels.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13182B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF263352)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.sports_esports_rounded, color: Color(0xFF556891), size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'No offline duels yet',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start a duel with a friend sitting next to you!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._recentDuels.take(5).map((duel) => _buildDuelItem(duel, player.displayName)),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required List<Color> gradientColors,
    required Color borderColor,
    required IconData icon,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TactileButton(
            label: buttonLabel,
            height: 48,
            fontSize: 14,
            width: double.infinity,
            faceColorTop: Colors.white,
            faceColorBottom: const Color(0xFFD6E4FF),
            rimColor: const Color(0xFF8FAEE0),
            textColor: const Color(0xFF0C1329),
            onTap: onTap,
          ),
        ],
      ),
    );
  }

  Widget _buildDuelItem(DuelRecord duel, String currentPlayerName) {
    final isPlayerWinner = duel.winner == currentPlayerName;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF13182B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPlayerWinner
              ? AppColors.success.withValues(alpha: 0.4)
              : const Color(0xFF263352),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPlayerWinner
                  ? AppColors.success.withValues(alpha: 0.2)
                  : const Color(0xFF222B45),
            ),
            child: Icon(
              isPlayerWinner ? Icons.emoji_events_rounded : Icons.sports_kabaddi_rounded,
              color: isPlayerWinner ? const Color(0xFFFFD700) : AppColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${duel.winner} defeated ${duel.loser}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Score: ${duel.scoreWinner} - ${duel.scoreLoser}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isPlayerWinner ? 'VICTORY' : 'DEFEAT',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isPlayerWinner ? AppColors.success : AppColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
