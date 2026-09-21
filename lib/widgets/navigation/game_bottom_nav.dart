import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Cosmic Bottom Navigation Bar for BLINK
/// Features:
/// - Dark glassmorphic base matching BLINK's cosmic identity
/// - Active tab: Glowing cyan accent underline + bright icon
/// - Inactive tabs: Muted icons
/// - Outfit typography consistent with Profile & Collectible screens
class GameBottomNav extends StatelessWidget {
  final int currentIndex;

  const GameBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(
            color: AppColors.glassBorder,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTab(context, 0, Icons.map_rounded, 'MAP', '/world'),
              _buildTab(context, 1, Icons.today_rounded, 'EVENTS', '/daily-shift'),
              _buildTab(context, 2, Icons.storefront_rounded, 'SHOP', '/collect'),
              _buildTab(context, 3, Icons.person_rounded, 'PROFILE', '/profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    String route,
  ) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (currentIndex == index) return;
          context.go(route);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated glowing dot for active tab
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSelected ? 32 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isSelected ? AppColors.cyan : Colors.transparent,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.cyan.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            // Icon
            Icon(
              icon,
              size: isSelected ? 24 : 22,
              color: isSelected ? AppColors.cyan : AppColors.textMuted,
              shadows: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            const SizedBox(height: 3),
            // Label
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.cyan : AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
