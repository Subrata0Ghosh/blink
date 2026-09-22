import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../services/game_state_service.dart';
import '../../services/haptic_service.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/characters/tactile_nova_companion.dart';
import '../../widgets/particles/particles.dart';

/// Home / Welcome Screen — BLINK Cosmic Identity
/// Features:
/// - Deep space gradient background with floating particle effects
/// - Glowing neon "BLINK" title with cyan/purple aura pulse
/// - Level & rank glassmorphic info pill
/// - Giant cosmic cyan 3D "Play" button with tactile press physics
/// - Secondary nebula purple "Level Map" button
/// - Bottom utility row (Settings, rank chip, Events)
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

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ──── 1. DEEP SPACE GRADIENT BACKGROUND ────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.3),
                  radius: 1.2,
                  colors: [
                    Color(0xFF1A1F40), // Subtle nebula center
                    Color(0xFF0F1328), // Mid-depth
                    AppColors.background, // Deep black edges
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
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
                        label: 'Full',
                        glowColor: const Color(0xFFFF5580),
                      ),

                      // Gems Pill
                      _buildGlassPill(
                        icon: Icons.diamond_rounded,
                        iconColor: AppColors.gemCyan,
                        label: '${player.gems > 0 ? player.gems : 250}',
                        glowColor: AppColors.gemCyan,
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
                        // BLINK Logo if available, else text
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

                // ──── INTERACTIVE 3D NOVA COMPANION (No dark background, 3D behaviors) ────
                const Center(
                  child: TactileNovaCompanion(
                    size: 108,
                    showHologramRing: true,
                    enableDialogue: true,
                  ),
                ),

                const Spacer(),

                // ──── BOTTOM ACTION BUTTONS ────
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
                          context.push('/play');
                        },
                      ),

                      const SizedBox(height: 14),

                      // Secondary Nebula Purple "Level Map" button
                      TactileButton.nebula(
                        label: 'LEVEL MAP',
                        fontSize: 18,
                        height: 50,
                        width: double.infinity,
                        icon: Icons.map_rounded,
                        onTap: () {
                          triggerHaptic(ref, HapticService.mediumTap);
                          context.go('/world');
                        },
                      ),

                      const SizedBox(height: 18),

                      // Bottom row: Settings, Level info, Events
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Settings circle
                          TactileButton.circle(
                            size: 50,
                            faceColorTop: AppColors.surfaceLight,
                            faceColorBottom: const Color(0xFF0F1328),
                            rimColor: const Color(0xFF080C1A),
                            onTap: () {
                              triggerHaptic(ref, HapticService.lightTap);
                              context.go('/profile');
                            },
                            child: const Icon(
                              Icons.settings_rounded,
                              color: AppColors.textSecondary,
                              size: 24,
                            ),
                          ),

                          // Level chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.glassWhite,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Text(
                              'Level ${player.level} • Star Master',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),

                          // Daily Events circle
                          TactileButton.circle(
                            size: 50,
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
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),
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
  }) {
    return Container(
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
    );
  }
}
