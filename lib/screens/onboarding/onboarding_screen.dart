import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/characters/tactile_nova_companion.dart';
import '../../widgets/particles/particles.dart';
import '../../services/game_state_service.dart';

/// Onboarding — 3 atmospheric screens + name entry
class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'Look carefully.',
      subtitle: 'The world is full of details\nwaiting to be noticed.',
      icon: Icons.visibility_rounded,
      assetPath: AppAssets.blinkLogo,
      gradientColors: [AppColors.primary, AppColors.cyan],
    ),
    _OnboardingPage(
      title: 'Everything changes.',
      subtitle: 'When you blink, reality shifts.\nCan you spot what\'s different?',
      icon: Icons.auto_awesome_rounded,
      assetPath: AppAssets.floatingIsland,
      gradientColors: [AppColors.cyan, AppColors.mint],
    ),
    _OnboardingPage(
      title: 'Your challenge begins.',
      subtitle: 'Observe. Remember. Discover.\nThe Shift World awaits.',
      icon: Icons.rocket_launch_rounded,
      assetPath: AppAssets.shiftGem,
      gradientColors: [AppColors.primary, AppColors.gemPurple],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _completeOnboarding() {
    ref.read(gameStateProvider.notifier).completeOnboarding(_nameController.text);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarField(starCount: 60),
          const FloatingParticles(count: 10, color: AppColors.primaryLight),
          SafeArea(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              physics: const BouncingScrollPhysics(),
              children: [
                ..._pages.map((page) => _buildIntroPage(page)),
                _buildNamePage(),
              ],
            ),
          ),
          // ──── 3D PAGE INDICATORS & TACTILE NAVIGATION ────
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // 3D Pill Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final isActive = _currentPage == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: isActive ? 34 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [AppColors.cosmicCyanLight, AppColors.cosmicCyanDark],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isActive ? null : const Color(0xFF161F36),
                        border: Border.all(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                        boxShadow: [
                          if (isActive)
                            BoxShadow(
                              color: AppColors.cyan.withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 3,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                // 3D Candy Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: _currentPage < 3
                      ? TactileButton.cosmic(
                          label: 'NEXT',
                          fontSize: 18,
                          height: 56,
                          onTap: _nextPage,
                        )
                      : TactileButton.cosmic(
                          label: 'START JOURNEY',
                          fontSize: 18,
                          height: 56,
                          onTap: _completeOnboarding,
                        ),
                ),
              ],
            ),
          ),
          // 3D Skip button
          if (_currentPage < 3)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    3,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'SKIP',
                    style: GoogleFonts.outfit(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIntroPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 3D Floating Astral Pedestal Cradling Artwork
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ground aura shadow
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 140,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: page.gradientColors[0].withValues(alpha: 0.45),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),

                // 3D Beveled Pedestal Ring
                Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF070B19),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: page.gradientColors[0].withValues(alpha: 0.45),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        if (page.assetPath != null)
                          Image.asset(
                            page.assetPath!,
                            fit: BoxFit.cover,
                          )
                        else
                          Center(
                            child: Icon(
                              page.icon,
                              size: 58,
                              color: page.gradientColors[0],
                            ),
                          ),

                        // Curved top glass specular sheen along the circular perimeter
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 64,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.38),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Bottom inner sphere shadow for 3D depth
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 40,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 44),
          // 3D Embossed Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
              shadows: [
                Shadow(
                  color: page.gradientColors[0].withValues(alpha: 0.8),
                  offset: const Offset(0, 2),
                  blurRadius: 2,
                ),
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ──── INTERACTIVE 3D NOVA COMPANION ON HOLOGRAM BASE ────
          const Center(
            child: TactileNovaCompanion(
              size: 135,
              showHologramRing: true,
              enableDialogue: true,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'What\'s your name?',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [
                const Shadow(
                  color: Color(0xFF007A99),
                  offset: Offset(0, 2),
                  blurRadius: 2,
                ),
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a name for your cosmic observer.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          // 3D Recessed Console Entry Slot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1122),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cyan.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_outline_rounded, color: AppColors.cyan, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.start,
                    decoration: InputDecoration(
                      hintText: 'Enter Observer Name',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 16,
                        color: AppColors.textMuted.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // Space for button at bottom
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? assetPath;
  final List<Color> gradientColors;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.assetPath,
    required this.gradientColors,
  });
}
