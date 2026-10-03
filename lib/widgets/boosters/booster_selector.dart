import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/booster_model.dart';
import '../../services/game_state_service.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';
import '../buttons/tactile_button.dart';

/// Pre-game booster selection modal
/// Shows all available boosters with inventory counts, allows the player
/// to select up to 3 boosters, and purchase new ones with gems.
class BoosterSelector extends ConsumerStatefulWidget {
  final void Function(ActiveBoosters boosters) onConfirm;
  final VoidCallback onSkip;

  const BoosterSelector({
    super.key,
    required this.onConfirm,
    required this.onSkip,
  });

  @override
  ConsumerState<BoosterSelector> createState() => _BoosterSelectorState();
}

class _BoosterSelectorState extends ConsumerState<BoosterSelector>
    with SingleTickerProviderStateMixin {
  ActiveBoosters _active = const ActiveBoosters();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(parent: _slideController, curve: Curves.easeIn);
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _toggleBooster(BoosterType type) {
    final player = ref.read(gameStateProvider);
    if (!player.boosterInventory.has(type) && !_active.isActive(type)) return;
    if (_active.isFull && !_active.isActive(type)) return;

    AudioService().playUiClick();
    triggerHaptic(ref, HapticService.lightTap);
    setState(() {
      _active = _active.toggle(type);
    });
  }

  Future<void> _purchaseBooster(BoosterType type) async {
    final success = await ref.read(gameStateProvider.notifier).purchaseBooster(type);
    if (success) {
      AudioService().playGemPickup();
      triggerHaptic(ref, HapticService.mediumTap);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(Booster.fromType(type).icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  '${Booster.fromType(type).name} purchased!',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E2640),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      AudioService().playWrong();
      triggerHaptic(ref, HapticService.lightTap);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough gems!',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.error.withValues(alpha: 0.9),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirm() {
    // Consume selected boosters from inventory
    if (_active.selected.isNotEmpty) {
      ref.read(gameStateProvider.notifier).consumeBoosters(_active.selected);
    }
    AudioService().playUiConfirm();
    triggerHaptic(ref, HapticService.mediumTap);
    widget.onConfirm(_active);
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);
    final inventory = player.boosterInventory;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      'SELECT BOOSTERS',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.glassWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💎', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(
                            '${player.gems}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gemCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Choose up to ${ActiveBoosters.maxActive} boosters for this session',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Booster grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: Booster.all.map((booster) {
                    final owned = inventory.countOf(booster.type);
                    final isSelected = _active.isActive(booster.type);
                    final canSelect = owned > 0 || isSelected;
                    final isFull = _active.isFull && !isSelected;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _BoosterCard(
                        booster: booster,
                        ownedCount: owned,
                        isSelected: isSelected,
                        canSelect: canSelect && !isFull,
                        gems: player.gems,
                        onTap: () => _toggleBooster(booster.type),
                        onBuy: () => _purchaseBooster(booster.type),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // 3D Tactile Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  children: [
                    // 3D Tactile Skip button
                    SizedBox(
                      width: 95,
                      child: TactileButton.dark(
                        label: 'SKIP',
                        height: 52,
                        fontSize: 14,
                        onTap: widget.onSkip,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 3D Tactile Go / Play button
                    Expanded(
                      child: _active.selected.isEmpty
                          ? TactileButton.nebula(
                              label: 'PLAY WITHOUT BOOSTERS',
                              height: 52,
                              fontSize: 13,
                              onTap: _confirm,
                            )
                          : TactileButton.cosmic(
                              label: 'GO WITH ${_active.selected.length} BOOSTER${_active.selected.length > 1 ? "S" : ""}',
                              icon: Icons.bolt_rounded,
                              height: 52,
                              fontSize: 13,
                              onTap: _confirm,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual booster card
class _BoosterCard extends StatelessWidget {
  final Booster booster;
  final int ownedCount;
  final bool isSelected;
  final bool canSelect;
  final int gems;
  final VoidCallback onTap;
  final VoidCallback onBuy;

  const _BoosterCard({
    required this.booster,
    required this.ownedCount,
    required this.isSelected,
    required this.canSelect,
    required this.gems,
    required this.onTap,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = gems >= booster.gemCost;

    return GestureDetector(
      onTap: canSelect ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? booster.color.withValues(alpha: 0.12)
              : AppColors.backgroundLight.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? booster.color.withValues(alpha: 0.6) : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: booster.glowColor,
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? booster.color.withValues(alpha: 0.2)
                    : AppColors.glassWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? booster.color.withValues(alpha: 0.4)
                      : Colors.transparent,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                booster.icon,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 12),

            // Name & description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booster.name,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? booster.color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    booster.description,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Count badge or buy button
            if (ownedCount > 0) ...[
              // Owned count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? booster.color.withValues(alpha: 0.2)
                      : AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'x$ownedCount',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? booster.color : AppColors.textSecondary,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle_rounded,
                  color: booster.color,
                  size: 20,
                ),
              ],
            ] else ...[
              // Buy button
              GestureDetector(
                onTap: onBuy,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: canAfford
                        ? LinearGradient(
                            colors: [
                              booster.color.withValues(alpha: 0.7),
                              booster.color.withValues(alpha: 0.5),
                            ],
                          )
                        : null,
                    color: canAfford ? null : AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💎', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Text(
                        '${booster.gemCost}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: canAfford ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
