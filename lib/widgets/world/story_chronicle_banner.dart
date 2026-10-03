import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../models/solar_realm_model.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';
import '../buttons/tactile_button.dart';

/// Cosmic Story Journey Banner displayed at the top of the level map
/// Features:
/// - Current Planetary Realm & Chapter Story title
/// - Interactive Nova Hologram Avatar that expands the story log
/// - Alien companion status badge
/// - One-tap Zoom Out toggle to the Solar Orrery Galaxy view
class StoryChronicleBanner extends StatefulWidget {
  final SolarRealm currentRealm;
  final int activeLevel;
  final VoidCallback onToggleOrrery;
  final bool isOrreryOpen;

  const StoryChronicleBanner({
    super.key,
    required this.currentRealm,
    required this.activeLevel,
    required this.onToggleOrrery,
    this.isOrreryOpen = false,
  });

  @override
  State<StoryChronicleBanner> createState() => _StoryChronicleBannerState();
}

class _StoryChronicleBannerState extends State<StoryChronicleBanner>
    with SingleTickerProviderStateMixin {
  bool _isStoryExpanded = false;

  void _toggleStoryLog() {
    HapticService.lightTap();
    AudioService().playUiConfirm();
    setState(() {
      _isStoryExpanded = !_isStoryExpanded;
    });
  }

  void _showFullStoryModal(BuildContext context) {
    HapticService.mediumTap();
    AudioService().playPowerUp();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1022),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.currentRealm.atmosphereColor.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.currentRealm.planetColor.withValues(alpha: 0.35),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top header with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_stories_rounded, color: AppColors.cyan, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'SOLAR CHRONICLES',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.cyan,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    TactileButton.close(
                      size: 36,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Chapter Title & Planet
                Text(
                  widget.currentRealm.chapterTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.currentRealm.name,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.currentRealm.atmosphereColor,
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 18),

                // Nova Transmission Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141A32),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nova Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cyan, width: 1.5),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            AppAssets.novaHappy,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, color: AppColors.cyan),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NOVA TRANSMISSION',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.cyan,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.currentRealm.storyTransmission,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFE2E8F0),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Alien Companion Bio Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141A32),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: widget.currentRealm.alien.glowColor.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              widget.currentRealm.alien.secondaryColor,
                              widget.currentRealm.alien.primaryColor,
                            ],
                          ),
                        ),
                        child: Icon(widget.currentRealm.alien.icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.currentRealm.alien.name} (${widget.currentRealm.alien.title})',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: widget.currentRealm.alien.glowColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.currentRealm.alien.bio,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF94A3B8),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                TactileButton.cosmic(
                  label: 'RESUME EXPEDITION',
                  height: 48,
                  fontSize: 14,
                  width: double.infinity,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final realm = widget.currentRealm;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF090D1C).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: realm.atmosphereColor.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: realm.planetColor.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // 1. Nova Hologram Avatar (Tappable to expand dialogue)
                GestureDetector(
                  onTap: _toggleStoryLog,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cyan, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            AppAssets.novaHappy,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, color: AppColors.cyan, size: 18),
                          ),
                        ),
                      ),
                      // Small pulse pip
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // 2. Chapter Title & Objective
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showFullStoryModal(context),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                realm.chapterTitle.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: realm.atmosphereColor,
                                  letterSpacing: 0.6,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.info_outline_rounded,
                              size: 11,
                              color: realm.atmosphereColor.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          realm.missionObjective,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // 3. 3D Orrery / Galaxy Zoom Toggle Button
                TactileButton.solar(
                  label: widget.isOrreryOpen ? 'SURFACE' : 'ORRERY',
                  icon: widget.isOrreryOpen ? Icons.landscape_rounded : Icons.public_rounded,
                  width: 82,
                  height: 32,
                  fontSize: 9.5,
                  onTap: widget.onToggleOrrery,
                ),
              ],
            ),
          ),

          // Collapsible Nova Dialogue Log
          if (_isStoryExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF050814),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Icon(widget.currentRealm.alien.icon, color: widget.currentRealm.alien.glowColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nova: "${realm.storyTransmission}"',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFFCBD5E1),
                          height: 1.3,
                        ),
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
}
