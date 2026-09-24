import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../widgets/animations/calm_ambient_glow.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/characters/tactile_nova_companion.dart';
import '../../widgets/modals/daily_quests_modal.dart';
import '../../widgets/modals/daily_rewards_modal.dart';
import '../../widgets/modals/relics_modal.dart';
import '../../widgets/particles/particles.dart';

/// Home / Welcome Screen — BLINK Cosmic Identity
/// Features:
/// - Soothing breathing cosmic nebula with floating stardust motes (Calm & Eye-catchy)
/// - Glowing neon "BLINK" title with cyan/purple aura pulse
/// - Quick Daily Gift notification chip with instant 7-day streak calendar modal
/// - Giant cosmic cyan 3D "Play" button with tactile press physics
/// - Secondary nebula purple "Level Map" button
/// - Calm Zen Practice Mode button for relaxing, unhurried observation
/// - Bottom utility row (Settings, Daily Missions, Events)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    AudioService().startAmbientMusic();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _openDailyRewards() {
    triggerHaptic(ref, HapticService.mediumTap);
    showDialog(
      context: context,
      builder: (context) => const DailyRewardsModal(),
    );
  }

  void _openDailyQuests() {
    triggerHaptic(ref, HapticService.mediumTap);
    showDialog(
      context: context,
      builder: (context) => const DailyQuestsModal(),
    );
  }

  void _openRelics() {
    triggerHaptic(ref, HapticService.mediumTap);
    AudioService().playUiConfirm();
    showDialog(
      context: context,
      builder: (context) => const RelicsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);
    final hasReward = player.isDailyRewardAvailable;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ──── 1. CALM ATMOSPHERIC BREATHING NEBULA & MOTES ────
          const Positioned.fill(
            child: CalmAmbientGlow(enableMotes: true),
          ),

          // ──── 2. FLOATING COSMIC PARTICLES ────
          const Positioned.fill(
            child: StarField(starCount: 45),
          ),

          // ──── 3. CENTERED CONTENT ────
          SafeArea(
            child: Column(
              children: [
                // Top status pills
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Lives Heart Pill
                      _buildGlassPill(
                        icon: Icons.favorite_rounded,
                        iconColor: const Color(0xFFFF5580),
                        label: 'Infinite',
                        glowColor: const Color(0xFFFF5580),
                        onTap: () {
                          triggerHaptic(ref, HapticService.lightTap);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.favorite_rounded, color: Color(0xFFFF5277), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Cosmic Energy is Infinite! No lives lost.',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF1B233A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Color(0xFFFF5277), width: 1.2),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),

                      // Daily Gift Chip (If ready)
                      if (hasReward)
                        GestureDetector(
                          onTap: _openDailyRewards,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cyan.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'GIFT READY',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Gems Pill
                      _buildGlassPill(
                        icon: Icons.diamond_rounded,
                        iconColor: AppColors.gemCyan,
                        label: '${player.gems > 0 ? player.gems : 250}',
                        glowColor: AppColors.gemCyan,
                        onTap: _openDailyRewards,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ──── GLOWING BLINK TITLE ────
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan.withValues(alpha: _glowAnimation.value * 0.3),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: _glowAnimation.value * 0.2),
                            blurRadius: 80,
                            spreadRadius: 30,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppColors.cyan, AppColors.primaryLight, AppColors.cyan],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'BLINK',
                            style: GoogleFonts.outfit(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 8.0,
                              shadows: [
                                Shadow(
                                  color: AppColors.cyan.withValues(alpha: 0.6),
                                  offset: const Offset(0, 0),
                                  blurRadius: 20,
                                ),
                                const Shadow(
                                  color: Color(0xFF001830),
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Text(
                            'COSMIC ODYSSEY',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cyan,
                              letterSpacing: 4.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ──── INTERACTIVE 3D NOVA COMPANION ────
                const Center(
                  child: TactileNovaCompanion(
                    size: 108,
                    showHologramRing: true,
                    enableDialogue: true,
                  ),
                ),

                const Spacer(),

                // ──── ACTION BUTTONS ────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Giant Cosmic Cyan 3D "Play" Button
                      TactileButton.cosmic(
                        label: 'PLAY',
                        fontSize: 28,
                        height: 66,
                        width: double.infinity,
                        onTap: () {
                          triggerHaptic(ref, HapticService.mediumTap);
                          ref.read(gameStateProvider.notifier).setCalmMode(false);
                          context.push('/play');
                        },
                      ),

                      const SizedBox(height: 12),

                      // Secondary Row: Level Map & Calm Zen Mode
                      Row(
                        children: [
                          Expanded(
                            child: TactileButton.nebula(
                              label: 'LEVEL MAP',
                              fontSize: 15,
                              height: 48,
                              icon: Icons.map_rounded,
                              onTap: () {
                                triggerHaptic(ref, HapticService.mediumTap);
                                context.go('/world');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TactileButton(
                              label: 'CALM ZEN',
                              fontSize: 15,
                              height: 48,
                              icon: Icons.spa_rounded,
                              faceColorTop: const Color(0xFF00B4D8),
                              faceColorBottom: const Color(0xFF0077B6),
                              rimColor: const Color(0xFF023E8A),
                              onTap: () {
                                triggerHaptic(ref, HapticService.lightTap);
                                ref.read(gameStateProvider.notifier).setCalmMode(true);
                                context.push('/play');
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Bottom Utility Row: Settings, Daily Missions, Events
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Settings circle
                          TactileButton.circle(
                            size: 48,
                            faceColorTop: AppColors.surfaceLight,
                            faceColorBottom: const Color(0xFF0F1328),
                            rimColor: const Color(0xFF080C18),
                            onTap: () {
                              triggerHaptic(ref, HapticService.lightTap);
                              context.go('/profile');
                            },
                            child: const Icon(
                              Icons.settings_rounded,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ),

                          // Daily Missions Button
                          GestureDetector(
                            onTap: _openDailyQuests,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161E34),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF2E3E66)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.military_tech_rounded,
                                    color: AppColors.gold,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Missions',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Constellation Codex / Relics Button
                          GestureDetector(
                            onTap: _openRelics,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161E34),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.55)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.20),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Color(0xFFFFD700),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Relics',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Daily Events circle
                          TactileButton.circle(
                            size: 48,
                            faceColorTop: AppColors.novaOrangeLight,
                            faceColorBottom: AppColors.novaOrangeDark,
                            rimColor: AppColors.novaOrangeRim,
                            onTap: () {
                              triggerHaptic(ref, HapticService.lightTap);
                              context.push('/daily-shift');
                            },
                            child: const Icon(
                              Icons.today_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color glowColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
