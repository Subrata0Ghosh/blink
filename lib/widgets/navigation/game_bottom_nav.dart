import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';

/// Unique 3D Tactile Bottom Navigation Dock for BLINK
/// Features:
/// - 3D docked base with dark extruded bevel rim and drop shadow
/// - Active tab: elevated 3D tactile pill button with cosmic cyan gradient, 3D bottom rim, and top specular highlight
/// - Inactive tabs: tactile 3D button pedestals that compress downward when tapped
/// - Tactile haptic feedback and spring physics on every tap
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
            color: Color(0xFF2E3858),
            width: 1.5,
          ),
          bottom: BorderSide(
            color: Color(0xFF080C18),
            width: 3.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                _build3dTab(context, 0, Icons.map_rounded, 'MAP', '/world'),
                const SizedBox(width: 8),
                _build3dTab(context, 1, Icons.today_rounded, 'EVENTS', '/daily-shift'),
                const SizedBox(width: 8),
                _build3dTab(context, 2, Icons.storefront_rounded, 'SHOP', '/collect'),
                const SizedBox(width: 8),
                _build3dTab(context, 3, Icons.person_rounded, 'PROFILE', '/profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3dTab(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    String route,
  ) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: _TactileNavTab(
        icon: icon,
        label: label,
        isSelected: isSelected,
        onTap: () {
          if (currentIndex == index) return;
          context.go(route);
        },
      ),
    );
  }
}

class _TactileNavTab extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TactileNavTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TactileNavTab> createState() => _TactileNavTabState();
}

class _TactileNavTabState extends State<_TactileNavTab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
    HapticFeedback.lightImpact();
    AudioService().playUiClick();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    const rimHeight = 4.0;
    const height = 48.0;
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final pushDown = t * (rimHeight - 0.5);

          return SizedBox(
            height: height + rimHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ──── 1. BOTTOM 3D RIM (Extruded Base) ────
                Positioned(
                  top: rimHeight,
                  left: 0,
                  right: 0,
                  height: height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.cosmicCyanRim : const Color(0xFF090D18),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.cyan.withValues(alpha: 0.4),
                                blurRadius: 8.0 - (t * 4.0),
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 3,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                    ),
                  ),
                ),

                // ──── 2. TOP GLOSSY FACE (Moves down on press) ────
                Positioned(
                  top: pushDown,
                  left: 0,
                  right: 0,
                  height: height,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.cosmicCyanLight,
                                AppColors.cosmicCyanDark,
                              ],
                            )
                          : const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF222B48),
                                Color(0xFF13182C),
                              ],
                            ),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.65)
                            : Colors.white.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Top Specular Highlight Crescent
                          Positioned(
                            top: 1,
                            left: 4,
                            right: 4,
                            height: height * 0.40,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14),
                                  bottom: Radius.elliptical(30, 6),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: isSelected ? 0.55 : 0.25),
                                    Colors.white.withValues(alpha: 0.02),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Inner Content (Icon + Label)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.icon,
                                size: isSelected ? 22 : 20,
                                color: isSelected ? Colors.white : AppColors.textMuted,
                                shadows: isSelected
                                    ? [
                                        Shadow(
                                          color: AppColors.cosmicCyanRim,
                                          offset: const Offset(0, 1.5),
                                          blurRadius: 2,
                                        ),
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          offset: const Offset(0, 2),
                                          blurRadius: 3,
                                        ),
                                      ]
                                    : null,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.label,
                                style: GoogleFonts.outfit(
                                  fontSize: isSelected ? 10.5 : 9.5,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.textMuted,
                                  letterSpacing: 0.8,
                                  shadows: isSelected
                                      ? [
                                          Shadow(
                                            color: AppColors.cosmicCyanRim,
                                            offset: const Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
