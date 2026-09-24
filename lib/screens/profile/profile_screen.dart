import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../models/player_state.dart';
import '../../services/game_state_service.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/characters/observer_avatar_badge.dart';
import '../../widgets/navigation/game_bottom_nav.dart';
import '../../widgets/particles/particles.dart';
import '../../widgets/sliders/tactile_jelly_slider.dart';
import '../../widgets/sliders/tactile_jelly_switch.dart';
import 'more_audio_modal.dart';
import 'observer_edit_modal.dart';

/// Observer Profile & Audio Control Center for BLINK
/// Features:
/// - Hanging celestial signboard with framed avatar and "Edit" button
/// - Copyable Observer ID with instant clipboard feedback
/// - Candy-Crush style tactile 3D audio sliders & switches (Music, SFX)
/// - "More Audio" cosmic tuning sheet (Voice, Balance, Bass, Sparkle)
/// - Performance & streak stats breakdown
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _openEditModal() {
    AudioService().playUiClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ObserverEditModal(),
    );
  }

  void _openMoreAudioModal() {
    AudioService().playUiClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const MoreAudioModal(),
    );
  }

  void _copyObserverId(String id) {
    Clipboard.setData(ClipboardData(text: id));
    HapticFeedback.lightImpact();
    AudioService().playGemPickup();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 20),
            const SizedBox(width: 10),
            Text(
              'Observer ID $id copied!',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B233A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF38E5FE), width: 1.2),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    final accuracy = player.totalChallenges > 0
        ? ((player.correctAnswers / player.totalChallenges) * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarField(starCount: 50),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ──── TOP HEADER ────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_rounded, color: AppColors.cyan, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'OBSERVER PROFILE',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.cyan,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Gems
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          children: [
                            Image.asset(AppAssets.shiftGem, width: 18, height: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${player.gems}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ──── HANGING CELESTIAL SIGNBOARD (Reference Screenshot 4) ────
                  _buildHangingSignboard(player),

                  const SizedBox(height: 20),

                  // ──── OBSERVER ID CAPSULE (Reference Screenshot 3) ────
                  _buildObserverIdBox(player.observerId),

                  const SizedBox(height: 24),

                  // ──── AUDIO CONTROLS / SETTINGS & ACCESSIBILITY ────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SETTINGS & ACCESSIBILITY',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAudioControlsSection(player, notifier),

                  const SizedBox(height: 24),

                  // ──── STATS BREAKDOWN / PERFORMANCE STATS ────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PERFORMANCE STATS',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatsGrid(player, accuracy),

                  const SizedBox(height: 24),

                  // ──── HAPTICS & ACCESSIBILITY ────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E263D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.vibration_rounded,
                                color: AppColors.cyan,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Haptic Feedback',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Tactile pulses on taps and rewards',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        TactileJellySwitch(
                          value: player.hapticEnabled,
                          onChanged: (_) => notifier.toggleHaptic(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ──── COSMIC NOTIFICATIONS & REMINDERS ────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E263D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: AppColors.cyan,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cosmic Notifications',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'World shifts & energy alerts',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Test Button
                        GestureDetector(
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            AudioService().playUiClick();
                            await NotificationService().showInstantNotification();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.notifications_active_rounded, color: AppColors.cyan, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Cosmic notification sent! Check drawer.',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF1B233A),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: AppColors.cyan, width: 1.2),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF007A99)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cyan.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'TEST',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const GameBottomNav(currentIndex: 3),
    );
  }

  /// Hanging signboard styled card with celestial strings and wooden/gold pins
  Widget _buildHangingSignboard(PlayerState player) {
    return Column(
      children: [
        // Two hanging cords / cords with rings
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHangingCord(),
            const SizedBox(width: 130),
            _buildHangingCord(),
          ],
        ),

        // Main Profile Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF161C30),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF2E395A), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.15),
                blurRadius: 26,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top Cloud Crest / Scallop Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF283457),
                      const Color(0xFF1A223B).withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar inside glowing 3D Frame
                    ObserverAvatarBadge(
                      avatarId: player.selectedAvatarId,
                      frameId: player.selectedFrameId,
                      size: 68,
                    ),
                    const SizedBox(width: 16),

                    // Name & Region
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.displayName,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.cyan.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Level ${player.level}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.cyan,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFFFF7BB9)),
                              Text(
                                player.country,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFBAC7E3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Active Today • Cosmic Observer',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00E676),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Glossy 3D Pink "Edit" Button
                    TactileButton(
                      label: 'Edit',
                      fontSize: 14,
                      width: 72,
                      height: 38,
                      faceColorTop: const Color(0xFFFF6EB4),
                      faceColorBottom: const Color(0xFFD61876),
                      rimColor: const Color(0xFF8E0C4C),
                      onTap: _openEditModal,
                    ),
                  ],
                ),
              ),

              // Decorative candy stripe seam
              Container(
                height: 3,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF7BB9),
                      Color(0xFF38E5FE),
                      Color(0xFFFF7BB9),
                    ],
                  ),
                ),
              ),

              // Quick Highlight Stats Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickMetric('XP', '${player.xp}'),
                    Container(width: 1, height: 26, color: const Color(0xFF2C385A)),
                    _buildQuickMetric('STREAK', '${player.currentStreak}d'),
                    Container(width: 1, height: 26, color: const Color(0xFF2C385A)),
                    _buildQuickMetric('COMBO', 'x${player.bestCombo}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHangingCord() {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFFFD700),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xAAFFD700),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        Container(
          width: 2.5,
          height: 18,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFD700), Color(0xFF38E5FE)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// User ID box with 3D copy button (Reference Screenshot 3)
  Widget _buildObserverIdBox(String observerId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161C30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF283454)),
      ),
      child: Row(
        children: [
          Text(
            'User id:  ',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFBAC7E3),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1424),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF242E4C)),
            ),
            child: Text(
              observerId,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Spacer(),
          // 3D Copy button (circle with blue gem shine)
          GestureDetector(
            onTap: () => _copyObserverId(observerId),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.3, -0.3),
                  radius: 0.85,
                  colors: [
                    Color(0xFF80D8FF),
                    Color(0xFF0091EA),
                    Color(0xFF004D79),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0091EA).withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.copy_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Master Audio Controls Section (Reference Screenshot 1)
  Widget _buildAudioControlsSection(PlayerState player, GameStateNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161C30),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2B3658)),
      ),
      child: Column(
        children: [
          // 1. Music Row: Switch & 3D Slider
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Music:',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    TactileJellySwitch(
                      value: player.musicEnabled,
                      onChanged: (_) => notifier.toggleMusic(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TactileJellySlider(
                  value: player.musicEnabled ? player.musicVolume : 0.0,
                  onChanged: (val) {
                    if (!player.musicEnabled) notifier.toggleMusic();
                    notifier.setMusicVolume(val);
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF252F4E)),

          // 2. Sound Effects Row: Switch & 3D Slider
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sound effects:',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    TactileJellySwitch(
                      value: player.sfxEnabled,
                      onChanged: (_) => notifier.toggleSfx(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TactileJellySlider(
                  value: player.sfxEnabled ? player.sfxVolume : 0.0,
                  onChanged: (val) {
                    if (!player.sfxEnabled) notifier.toggleSfx();
                    notifier.setSfxVolume(val);
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF252F4E)),

          // 3. More Audio Button Row (Reference Screenshot 1)
          GestureDetector(
            onTap: _openMoreAudioModal,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'More Audio',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFF85C2),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.3, -0.3),
                        radius: 0.85,
                        colors: [
                          Color(0xFFFF7BB9),
                          Color(0xFFE91E63),
                          Color(0xFF880E4F),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Performance & General Stats Grid (Reference Screenshot 4)
  Widget _buildStatsGrid(PlayerState player, String accuracy) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'LEVELS WON',
                value: '${player.correctAnswers}',
                badgeIcon: Icons.check_circle_rounded,
                badgeColor: const Color(0xFF00E676),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'SHIFTS SPOTTED',
                value: '${player.totalChallenges}',
                badgeIcon: Icons.remove_red_eye_rounded,
                badgeColor: const Color(0xFF00B0FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'LOGIN STREAK',
                value: '${player.currentStreak} Days',
                badgeIcon: Icons.calendar_today_rounded,
                badgeColor: const Color(0xFFFFB300),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'BEST COMBO',
                value: 'x${player.bestCombo}',
                badgeIcon: Icons.local_fire_department_rounded,
                badgeColor: const Color(0xFFFF5252),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'ACCURACY',
                value: '$accuracy%',
                badgeIcon: Icons.track_changes_rounded,
                badgeColor: const Color(0xFFE040FB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'BEST REACTION',
                value: player.bestReactionTimeMs > 0 ? '${player.bestReactionTimeMs}ms' : '--',
                badgeIcon: Icons.bolt_rounded,
                badgeColor: const Color(0xFF00E5FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData badgeIcon,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161C30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF283452)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor.withValues(alpha: 0.18),
              border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Icon(badgeIcon, color: badgeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
