import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/app_review_share_service.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../services/leaderboard_service.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/characters/observer_avatar_badge.dart';
import '../../widgets/particles/particles.dart';

/// Cosmic Leaderboard & Offline Duel Standings
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _selectedTab = 0; // 0: Cosmic Observers, 1: Offline Duels
  List<DuelRecord> _duelRecords = [];
  bool _loadingDuels = true;

  @override
  void initState() {
    super.initState();
    AudioService().startAmbientMusic();
    _loadDuels();
  }

  Future<void> _loadDuels() async {
    final records = await LeaderboardService.getDuelRecords();
    if (mounted) {
      setState(() {
        _duelRecords = records;
        _loadingDuels = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);
    final rankings = LeaderboardService.getGlobalRankings(player);
    final myEntry = rankings.firstWhere(
      (e) => e.isCurrentUser,
      orElse: () => rankings.last,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarField(starCount: 50),
          const FloatingParticles(count: 14, color: AppColors.cyan),

          SafeArea(
            child: Column(
              children: [
                // ──── TOP HEADER BAR ────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
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
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'LEADERBOARD',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ──── TABS ────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13182B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF253354)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(index: 0, label: 'COSMIC ARENA'),
                        ),
                        Expanded(
                          child: _buildTabButton(index: 1, label: 'OFFLINE DUELS'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ──── TAB BODY ────
                Expanded(
                  child: _selectedTab == 0
                      ? _buildCosmicArenaTab(rankings)
                      : _buildOfflineDuelsTab(player.displayName),
                ),

                // ──── STICKY BOTTOM USER RANK CARD ────
                if (_selectedTab == 0) _buildStickyUserCard(myEntry),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label}) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        triggerHaptic(ref, HapticService.lightTap);
        AudioService().playUiClick();
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
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? const Color(0xFF071120) : AppColors.textMuted,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildCosmicArenaTab(List<LeaderboardEntry> rankings) {
    final top3 = rankings.take(3).toList();
    final remaining = rankings.skip(3).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // ──── TOP 3 PODIUM ────
          if (top3.length >= 3) _buildPodium(top3),

          const SizedBox(height: 20),

          // ──── REMAINING RANKS (#4+) ────
          ...remaining.map((entry) => _buildRankRow(entry)),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    // top3[0] = #1 (Center), top3[1] = #2 (Left), top3[2] = #3 (Right)
    final first = top3[0];
    final second = top3[1];
    final third = top3[2];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF263558)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // #2 Silver Pedestal
          _buildPodiumStep(
            entry: second,
            rank: 2,
            pedestalHeight: 88,
            medalColor: const Color(0xFFE2E8F0),
            glowColor: const Color(0xFF94A3B8),
          ),

          // #1 Gold Pedestal (Taller, elevated)
          _buildPodiumStep(
            entry: first,
            rank: 1,
            pedestalHeight: 114,
            medalColor: const Color(0xFFFFD700),
            glowColor: const Color(0xFFFFA000),
            hasCrown: true,
          ),

          // #3 Bronze Pedestal
          _buildPodiumStep(
            entry: third,
            rank: 3,
            pedestalHeight: 74,
            medalColor: const Color(0xFFCD7F32),
            glowColor: const Color(0xFFA0522D),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumStep({
    required LeaderboardEntry entry,
    required int rank,
    required double pedestalHeight,
    required Color medalColor,
    required Color glowColor,
    bool hasCrown = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasCrown)
          const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 24)
        else
          const SizedBox(height: 24),

        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.4),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ObserverAvatarBadge(
            avatarId: entry.avatarId,
            frameId: entry.frameId,
            size: rank == 1 ? 58 : 48,
          ),
        ),

        const SizedBox(height: 6),

        // Name
        SizedBox(
          width: 86,
          child: Text(
            entry.displayName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),

        // Score
        Text(
          '${entry.score}',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: medalColor,
          ),
        ),

        const SizedBox(height: 6),

        // 3D Pedestal Base
        Container(
          width: 86,
          height: pedestalHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                medalColor.withValues(alpha: 0.35),
                const Color(0xFF0F1528),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: medalColor.withValues(alpha: 0.6)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: medalColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankRow(LeaderboardEntry entry) {
    final isMe = entry.isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.cyan.withValues(alpha: 0.15) : const Color(0xFF13182B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? AppColors.cyan : const Color(0xFF222E4D),
          width: isMe ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isMe ? AppColors.cyan : AppColors.textMuted,
              ),
            ),
          ),

          // Avatar
          ObserverAvatarBadge(
            avatarId: entry.avatarId,
            frameId: entry.frameId,
            size: 38,
          ),
          const SizedBox(width: 12),

          // Name and Region
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Lv.${entry.level} • ${entry.region}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Streak flame
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF5277), size: 16),
              const SizedBox(width: 2),
              Text(
                '${entry.streak}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF5277),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Score
          Text(
            '${entry.score}',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isMe ? AppColors.cyan : AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyUserCard(LeaderboardEntry myEntry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1528),
        border: const Border(
          top: BorderSide(color: AppColors.cyan, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cyan),
            ),
            child: Text(
              'YOU #${myEntry.rank}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.cyan,
              ),
            ),
          ),
          const SizedBox(width: 14),
          ObserverAvatarBadge(
            avatarId: myEntry.avatarId,
            frameId: myEntry.frameId,
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  myEntry.displayName,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Score: ${myEntry.score} • Streak: ${myEntry.streak}d',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TactileButton(
            label: 'SHARE',
            width: 76,
            height: 36,
            fontSize: 12,
            faceColorTop: AppColors.cyan,
            faceColorBottom: const Color(0xFF007A99),
            rimColor: const Color(0xFF004D60),
            onTap: () {
              final player = ref.read(gameStateProvider);
              AppReviewShareService.shareApp(player: player);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineDuelsTab(String currentPlayerName) {
    if (_loadingDuels) {
      return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
    }

    if (_duelRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_kabaddi_rounded, color: Color(0xFF48587D), size: 48),
              const SizedBox(height: 14),
              Text(
                'No Offline Duels Recorded Yet',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Challenge a friend in Same-Device Duel or Local Wi-Fi to start your offline rivalry leaderboard!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TactileButton.cosmic(
                label: 'GO TO MULTIPLAYER HUB',
                height: 48,
                fontSize: 14,
                onTap: () => context.push('/multiplayer'),
              ),
            ],
          ),
        ),
      );
    }

    int myWins = _duelRecords.where((d) => d.winner == currentPlayerName).length;
    int totalDuels = _duelRecords.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Local Duel Stats Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2848), Color(0xFF10162B)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334370)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDuelStatItem(label: 'TOTAL DUELS', value: '$totalDuels'),
                _buildDuelStatItem(label: 'YOUR WINS', value: '$myWins', color: AppColors.success),
                _buildDuelStatItem(
                  label: 'WIN RATE',
                  value: totalDuels > 0 ? '${((myWins / totalDuels) * 100).round()}%' : '0%',
                  color: AppColors.gold,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'MATCH HISTORY',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          ..._duelRecords.map((duel) {
            final isWin = duel.winner == currentPlayerName;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF13182B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isWin ? AppColors.success.withValues(alpha: 0.4) : const Color(0xFF263352),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isWin ? Icons.emoji_events_rounded : Icons.close_rounded,
                    color: isWin ? const Color(0xFFFFD700) : AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${duel.winner} vs ${duel.loser}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Score: ${duel.scoreWinner} - ${duel.scoreLoser}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isWin ? 'WON' : 'LOST',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isWin ? AppColors.success : const Color(0xFFFF5277),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDuelStatItem({required String label, required String value, Color color = Colors.white}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
