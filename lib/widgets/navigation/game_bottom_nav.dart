import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_service.dart';
import '../characters/observer_avatar_badge.dart';

/// Unique 3D Tactile Bottom Navigation Dock for BLINK
/// Features:
/// - 3D docked base with dark extruded bevel rim and drop shadow
/// - Active tab: elevated 3D tactile pill button with cosmic cyan gradient, 3D bottom rim, and top specular highlight
/// - Inactive tabs: tactile 3D button pedestals that compress downward when tapped
/// - Tactile haptic feedback and spring physics on every tap
class GameBottomNav extends ConsumerWidget {
  final int currentIndex;

  const GameBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameStateProvider);
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _build3dTab(context, 0, Icons.map_rounded, 'MAP', '/world'),
                const SizedBox(width: 8),
                _build3dTab(context, 1, Icons.today_rounded, 'EVENTS', '/daily-shift'),
                const SizedBox(width: 8),
                _build3dTab(context, 2, Icons.storefront_rounded, 'SHOP', '/collect'),
                const SizedBox(width: 8),
                _build3dTab(
                  context,
                  3,
                  Icons.person_rounded,
                  'PROFILE',
                  '/profile',
                  customIcon: ClipOval(
                    child: ObserverAvatarBadge(
                      avatarId: player.selectedAvatarId,
                      frameId: player.selectedFrameId,
                      size: 20,
                      isCircle: true,
                      showShadow: false,
                    ),
                  ),
                ),
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
    String route, {
    Widget? customIcon,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: _TactileNavTab(
        icon: icon,
        customIcon: customIcon,
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
  final IconData? icon;
  final Widget? customIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TactileNavTab({
    this.icon,
    this.customIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TactileNavTab> createState() => _TactileNavTabState();
}

class _TactileNavTabState extends State<_TactileNavTab> with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );

    if (widget.isSelected) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant _TactileNavTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _bounceController.forward(from: 0.0);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _bounceController.reset();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _pressController.forward();
    HapticFeedback.lightImpact();
    AudioService().playUiClick();
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
    if (widget.isSelected) {
      _bounceController.forward(from: 0.0);
    }
    widget.onTap();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    const rimHeight = 4.0;
    const height = 44.0;
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressController, _bounceController]),
        builder: (context, _) {
          final t = _pressController.value;
          final pushDown = t * (rimHeight - 0.5);
          final bounceVal = widget.isSelected ? _bounceAnimation.value : 0.0;
          // Scale reaches ~1.22 at peak and settles smoothly at 1.0
          final orbScale = widget.isSelected ? (0.35 + 0.65 * bounceVal).clamp(0.0, 1.35) : 1.0;
          // Vertical spring: pops up from pushDown to -16 (with elastic overshoot)
          final orbTop = widget.isSelected ? (pushDown - 16.0 * bounceVal.clamp(0.0, 1.3)) : pushDown;
          // Subtle playful wobble tilt as it pops out
          final orbWobble = widget.isSelected ? (1.0 - bounceVal).clamp(-0.5, 0.5) * 0.12 : 0.0;

          return SizedBox(
            height: height + rimHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
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
                                color: AppColors.cyan.withValues(alpha: 0.45),
                                blurRadius: 10.0 - (t * 4.0),
                                spreadRadius: 1.5,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
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
                            ? Colors.white.withValues(alpha: 0.7)
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
                                    Colors.white.withValues(alpha: isSelected ? 0.55 : 0.22),
                                    Colors.white.withValues(alpha: 0.02),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Inner Content:
                          // If ACTIVE: prominent, bold text showing clearly with room beneath the protruding 3D icon
                          // If INACTIVE: icon + label
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Transform.scale(
                                scale: (0.85 + 0.15 * bounceVal).clamp(0.5, 1.15),
                                child: Text(
                                  widget.label,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                    shadows: [
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
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.customIcon != null)
                                  SizedBox(
                                    width: 19,
                                    height: 19,
                                    child: widget.customIcon!,
                                  )
                                else if (widget.icon != null)
                                  Icon(
                                    widget.icon!,
                                    size: 19,
                                    color: const Color(0xFF8896B8),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.label,
                                  style: GoogleFonts.outfit(
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF8896B8),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ──── 3. 3D FLOATING ICON POPPING OUTSIDE BUTTON (When Active) ────
                if (isSelected)
                  Positioned(
                    top: orbTop, // Bouncy spring vertical position!
                    child: Transform.rotate(
                      angle: orbWobble,
                      child: Transform.scale(
                        scale: orbScale,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              center: Alignment(-0.25, -0.4),
                              radius: 0.95,
                              colors: [
                                Color(0xFF94FBFF), // Brilliant cyan highlight dome
                                Color(0xFF00D2FF), // Vivid cyan core
                                Color(0xFF00759E), // Deep 3D rim shadow
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.8,
                            ),
                            boxShadow: [
                              // Intense neon cyan aura
                              BoxShadow(
                                color: AppColors.cyan.withValues(alpha: 0.7),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                              // Drop shadow cast downward onto button pill
                              BoxShadow(
                                color: const Color(0xFF001A30).withValues(alpha: 0.75),
                                blurRadius: 5,
                                offset: const Offset(0, 3.5),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Top specular shine crescent
                              Positioned(
                                top: 2,
                                left: 5,
                                right: 5,
                                height: 13,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.8),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // 3D Embossed Icon
                              if (widget.customIcon != null)
                                ClipOval(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: widget.customIcon!,
                                  ),
                                )
                              else if (widget.icon != null)
                                Icon(
                                  widget.icon!,
                                  size: 20,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0xFF004968),
                                      offset: Offset(0, 1.5),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                            ],
                          ),
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
