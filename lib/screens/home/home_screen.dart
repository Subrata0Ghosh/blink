import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/particles/particles.dart';
import '../../services/game_state_service.dart';
import '../../models/player_state.dart';
import '../../core/constants/app_assets.dart';

/// Home screen — alive, animated, with floating world preview
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  int _selectedNav = 0;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Animated background
          const StarField(starCount: 50),
          const FloatingParticles(count: 12, color: AppColors.primaryLight),

          SafeArea(
            child: Column(
              children: [
                // ──── TOP BAR ────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      // Avatar
                      GlowPulse(
                        glowColor: AppColors.cyan,
                        maxBlur: 14,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.8), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyan.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              AppAssets.novaIdle,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Level + Name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.displayName,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Level ${player.level}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.cyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Gem counter
                      _buildGemCounter(player.gems),
                    ],
                  ),
                ),

                // ──── XP BAR ────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _buildXpBar(player),
                ),

                const Spacer(flex: 1),

                // ──── FLOATING WORLD PREVIEW ────
                AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnimation.value),
                      child: child,
                    );
                  },
                  child: _buildWorldPreview(player),
                ),

                const SizedBox(height: 16),

                // Nova name
                Text(
                  'THE SHIFT WORLD',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 3,
                  ),
                ),

                const Spacer(flex: 1),

                // ──── PLAY BUTTON ────
                GlowPulse(
                  glowColor: AppColors.primary,
                  maxBlur: 25,
                  child: GestureDetector(
                    onTap: () => context.push('/play'),
                    child: Container(
                      width: 200,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'PLAY',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ──── QUICK ACCESS BUTTONS ────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickButton('DAILY\nSHIFT', Icons.today_rounded, AppColors.cyan),
                      _buildQuickButton('MYSTERY', Icons.help_outline_rounded, AppColors.gemPurple),
                      _buildQuickButton('WORLD', Icons.public_rounded, AppColors.mint),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
      // ──── BOTTOM NAVIGATION ────
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildGemCounter(int gems) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shift Gem asset icon
          Image.asset(
            AppAssets.shiftGem,
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$gems',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpBar(PlayerState player) {
    final progress = player.xpToNextLevel > 0
        ? (player.xp / player.xpToNextLevel).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XP',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${player.xp} / ${player.xpToNextLevel}',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
          ),
        ),
      ],
    );
  }

  Widget _buildWorldPreview(PlayerState player) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.cyan.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 3D Floating Island sanctuary
          ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Image.asset(
              AppAssets.floatingIsland,
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
          ),
          // Nova floating companion hovering above the island
          Positioned(
            top: 20,
            child: _buildNova(),
          ),
        ],
      ),
    );
  }

  Widget _buildNova() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 6,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          AppAssets.novaIdle,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildQuickButton(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // Future feature screens
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'HOME'),
              _buildNavItem(1, Icons.play_circle_rounded, 'PLAY'),
              _buildNavItem(2, Icons.public_rounded, 'WORLD'),
              _buildNavItem(3, Icons.grid_view_rounded, 'COLLECT'),
              _buildNavItem(4, Icons.person_rounded, 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedNav == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNav = index);
        if (index == 1) context.push('/play');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.cyan : AppColors.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.cyan : AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
