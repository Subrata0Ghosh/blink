import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
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
          // Page indicators + navigation
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Page dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? AppColors.cyan
                            : AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                // Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _currentPage < 3
                      ? _buildButton('NEXT', _nextPage)
                      : _buildButton('PLAY NOW', _completeOnboarding, isPrimary: true),
                ),
              ],
            ),
          ),
          // Skip button
          if (_currentPage < 3)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: TextButton(
                onPressed: () {
                  _pageController.animateToPage(
                    3,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: Text(
                  'SKIP',
                  style: GoogleFonts.outfit(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing artwork container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.gradientColors[0].withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: page.gradientColors[1].withValues(alpha: 0.25),
                  blurRadius: 60,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: page.assetPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(70),
                    child: Image.asset(
                      page.assetPath!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: page.gradientColors.map((c) => c.withValues(alpha: 0.15)).toList(),
                      ),
                    ),
                    child: Icon(
                      page.icon,
                      size: 48,
                      color: page.gradientColors[0],
                    ),
                  ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nova Mascot Artwork
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.5),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(65),
              child: Image.asset(
                AppAssets.novaIdle,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'What\'s your name?',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a name for your observer.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: TextField(
              controller: _nameController,
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Observer',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 18,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 120), // Space for button at bottom
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])
              : null,
          color: isPrimary ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.glassBorder),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isPrimary ? Colors.white : AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
        ),
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
