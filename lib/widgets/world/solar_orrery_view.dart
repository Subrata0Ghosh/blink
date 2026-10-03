import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/solar_realm_model.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';
import '../buttons/tactile_button.dart';

/// Solar Planetary Orrery View
/// Features:
/// - Central radiant Solarium Sun with animated coronal flares and solar plasma
/// - 5 Concentric planetary orbits with depth perspective
/// - 5 Interactive 3D planetary globes with rings, atmospheres, star progress, and alien badges
/// - Tap any planet to smooth-zoom into its island archipelago
class SolarOrreryView extends StatefulWidget {
  final int activeLevel;
  final Map<int, int> levelStars;
  final Function(SolarRealm realm) onSelectRealm;
  final VoidCallback onZoomInToCurrent;

  const SolarOrreryView({
    super.key,
    required this.activeLevel,
    required this.levelStars,
    required this.onSelectRealm,
    required this.onZoomInToCurrent,
  });

  @override
  State<SolarOrreryView> createState() => _SolarOrreryViewState();
}

class _SolarOrreryViewState extends State<SolarOrreryView>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbitController;
  SolarRealm? _selectedRealm;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _selectedRealm = SolarRealm.getRealmForLevel(widget.activeLevel);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  int _getStarsForRealm(SolarRealm realm) {
    int count = 0;
    for (int lvl = realm.startLevel; lvl <= realm.endLevel; lvl++) {
      count += widget.levelStars[lvl] ?? 0;
    }
    return count;
  }

  bool _isRealmUnlocked(SolarRealm realm) {
    return widget.activeLevel >= realm.startLevel;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentRealm = SolarRealm.getRealmForLevel(widget.activeLevel);
    final selected = _selectedRealm ?? currentRealm;

    return Stack(
      children: [
        // 1. Deep Cosmic Void Background with Nebula Tint
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF1E1435),
                  Color(0xFF0F0C24),
                  Color(0xFF06060F),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // 2. Solar Orrery Canvas (Orbits, Sun, & Planets)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _orbitController,
            builder: (context, _) {
              return CustomPaint(
                painter: _OrreryOrbitLinesPainter(
                  realms: SolarRealm.realms,
                  pulse: _orbitController.value,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Central Solarium Sun
                    _buildSolariumSun(),

                    // 5 Orbiting Planets
                    ...SolarRealm.realms.map((realm) {
                      return _buildPlanetGlobe(realm, size);
                    }),
                  ],
                ),
              );
            },
          ),
        ),

        // 3. Top Cosmic Header Bar
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Galaxy System Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0E1B).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.25),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.public_rounded, color: AppColors.cyan, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'SOLAR ORRERY SYSTEM',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tactile Zoom In Button
                TactileButton.cosmic(
                  label: 'ENTER PLANET',
                  icon: Icons.zoom_in_rounded,
                  width: 140,
                  height: 38,
                  fontSize: 11,
                  onTap: () {
                    HapticService.mediumTap();
                    AudioService().playUiConfirm();
                    widget.onSelectRealm(selected);
                  },
                ),
              ],
            ),
          ),
        ),

        // 4. Bottom Selected Planet Story & Info Card
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: SafeArea(
            child: _buildPlanetStoryCard(selected),
          ),
        ),
      ],
    );
  }

  Widget _buildSolariumSun() {
    final sunT = _orbitController.value * 2 * pi;
    final pulseScale = 1.0 + (sin(sunT * 3) * 0.05);

    return Transform.scale(
      scale: pulseScale,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Colors.white,
              Color(0xFFFFF176),
              Color(0xFFFF9800),
              Color(0xFFFF3D00),
            ],
            stops: [0.0, 0.35, 0.75, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withValues(alpha: 0.8),
              blurRadius: 36,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: const Color(0xFFFF5722).withValues(alpha: 0.5),
              blurRadius: 54,
              spreadRadius: 14,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.wb_sunny_rounded,
            color: Color(0xFFFFF9C4),
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanetGlobe(SolarRealm realm, Size screenSize) {
    final isUnlocked = _isRealmUnlocked(realm);
    final isSelected = _selectedRealm?.id == realm.id;
    final baseRadius = 60.0 + (realm.index * 36.0);

    // Orbit position offset by planet index
    final speedMultiplier = 1.0 / (realm.index + 1);
    final angle = (_orbitController.value * 2 * pi * speedMultiplier) + (realm.index * 1.3);
    final posX = cos(angle) * baseRadius;
    final posY = sin(angle) * (baseRadius * 0.75); // Elliptical 3D perspective

    final planetSize = 36.0 + (realm.index == 1 ? 8.0 : (realm.index == 4 ? 6.0 : 0.0));

    return Transform.translate(
      offset: Offset(posX, posY),
      child: GestureDetector(
        onTap: () {
          HapticService.lightTap();
          AudioService().playUiConfirm();
          setState(() {
            _selectedRealm = realm;
          });
        },
        onDoubleTap: () {
          HapticService.mediumTap();
          AudioService().playPowerUp();
          widget.onSelectRealm(realm);
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Selected Halo Ring
            if (isSelected)
              Container(
                width: planetSize + 22,
                height: planetSize + 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: realm.atmosphereColor.withValues(alpha: 0.8),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),

            // Planet Planetary Rings (for Amethea IV)
            if (realm.index == 1)
              Transform.rotate(
                angle: -0.4,
                child: Container(
                  width: planetSize * 1.8,
                  height: planetSize * 0.6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.elliptical(planetSize * 1.8, planetSize * 0.6)),
                    border: Border.all(
                      color: realm.ringColor.withValues(alpha: 0.7),
                      width: 3.5,
                    ),
                  ),
                ),
              ),

            // 3D Planet Sphere Globe
            Container(
              width: planetSize,
              height: planetSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.35),
                  radius: 0.85,
                  colors: isUnlocked
                      ? [
                          Colors.white,
                          realm.atmosphereColor,
                          realm.planetColor,
                          const Color(0xFF090D18),
                        ]
                      : [
                          const Color(0xFF64748B),
                          const Color(0xFF334155),
                          const Color(0xFF0F172A),
                        ],
                  stops: isUnlocked ? const [0.0, 0.35, 0.75, 1.0] : const [0.0, 0.6, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUnlocked
                        ? realm.atmosphereColor.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.4),
                    blurRadius: 14,
                    spreadRadius: isSelected ? 3 : 1,
                  ),
                ],
              ),
              child: !isUnlocked
                  ? const Center(
                      child: Icon(Icons.lock_rounded, color: Colors.white70, size: 16),
                    )
                  : null,
            ),

            // Planet Name Label
            Positioned(
              bottom: -22,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C101E).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? realm.atmosphereColor : Colors.white24,
                    width: 1,
                  ),
                ),
                child: Text(
                  realm.name,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanetStoryCard(SolarRealm realm) {
    final isUnlocked = _isRealmUnlocked(realm);
    final stars = _getStarsForRealm(realm);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1527).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: realm.atmosphereColor.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: realm.planetColor.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Realm Title & Level Range
          Row(
            children: [
              // Planet Emblem
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [realm.atmosphereColor, realm.planetColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: realm.planetColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    realm.romanNumeral,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      realm.chapterTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: realm.atmosphereColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      realm.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Stars pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB800), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$stars / 12',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Story Transmission
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF090D18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                // Alien Mascot Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [realm.alien.secondaryColor, realm.alien.primaryColor],
                    ),
                  ),
                  child: Icon(realm.alien.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),

                // Transmission Lore
                Expanded(
                  child: Text(
                    realm.storyTransmission,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFCBD5E1),
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action Buttons: Zoom In to Archipelago / Locked prompt
          if (isUnlocked)
            TactileButton.cosmic(
              label: 'EXPLORE ${realm.name.toUpperCase()} (LV ${realm.startLevel}-${realm.endLevel})',
              icon: Icons.rocket_launch_rounded,
              height: 48,
              fontSize: 13,
              width: double.infinity,
              onTap: () {
                HapticService.heavyTap();
                AudioService().playPowerUp();
                widget.onSelectRealm(realm);
              },
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Complete Level ${realm.startLevel - 1} to unlock this realm',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OrreryOrbitLinesPainter extends CustomPainter {
  final List<SolarRealm> realms;
  final double pulse;

  _OrreryOrbitLinesPainter({
    required this.realms,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < realms.length; i++) {
      final realm = realms[i];
      final rx = 60.0 + (i * 36.0);
      final ry = rx * 0.75;

      final orbitPaint = Paint()
        ..color = realm.atmosphereColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawOval(
        Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
        orbitPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrreryOrbitLinesPainter oldDelegate) {
    return oldDelegate.pulse != pulse;
  }
}
