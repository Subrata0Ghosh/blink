import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/world/floating_island_painter.dart';

/// The architectural structure / role of each island in a planetary realm
enum IslandRole {
  realmGateway,   // Level 1, 5, 9, 13, 17: Planetary warp gate arrival pad
  alienSanctuary, // Level 2, 6, 10, 14, 18: Living habitat of the planet's alien companion
  crystalSpire,   // Level 3, 7, 11, 15, 19: Towering energy refraction obelisk
  citadelCastle,  // Level 4, 8, 12, 16, 20: Grand fortress citadel with turrets & banners
}

/// An interactive alien companion inhabiting each solar realm
class AlienCompanion {
  final String id;
  final String name;
  final String title;
  final String species;
  final String bio;
  final String greeting;
  final Color primaryColor;
  final Color secondaryColor;
  final Color glowColor;
  final IconData icon;

  const AlienCompanion({
    required this.id,
    required this.name,
    required this.title,
    required this.species,
    required this.bio,
    required this.greeting,
    required this.primaryColor,
    required this.secondaryColor,
    required this.glowColor,
    required this.icon,
  });
}

/// A distinct planetary realm orbiting the central Solarium Sun
class SolarRealm {
  final int index;
  final String id;
  final String name;
  final String romanNumeral;
  final String subTitle;
  final String chapterTitle;
  final String storyTransmission;
  final String missionObjective;
  final IslandBiome biome;
  final int startLevel;
  final int endLevel;
  final Color planetColor;
  final Color atmosphereColor;
  final Color ringColor;
  final double orbitRadius;
  final AlienCompanion alien;

  const SolarRealm({
    required this.index,
    required this.id,
    required this.name,
    required this.romanNumeral,
    required this.subTitle,
    required this.chapterTitle,
    required this.storyTransmission,
    required this.missionObjective,
    required this.biome,
    required this.startLevel,
    required this.endLevel,
    required this.planetColor,
    required this.atmosphereColor,
    required this.ringColor,
    required this.orbitRadius,
    required this.alien,
  });

  /// The 5 Solar Realms of the BLINK universe
  static const List<SolarRealm> realms = [
    SolarRealm(
      index: 0,
      id: 'solaria_prime',
      name: 'Solaria Prime',
      romanNumeral: 'I',
      subTitle: 'The Verdant Cradle',
      chapterTitle: 'Chapter I: The Solaria Genesis',
      storyTransmission:
          'Observer! The ancient Solar Beacons on Solaria Prime have dimmed. Awaken Zobi and restore the roots of the Emerald Citadel!',
      missionObjective: 'Reignite 4 Root Beacons & free Zobi',
      biome: IslandBiome.verdantAstral,
      startLevel: 1,
      endLevel: 4,
      planetColor: Color(0xFF10B981),
      atmosphereColor: Color(0xFF34D399),
      ringColor: Color(0xFF059669),
      orbitRadius: 90,
      alien: AlienCompanion(
        id: 'zobi',
        name: 'Zobi',
        title: 'Sproutling Guardian',
        species: 'Chlorophyll Sylph',
        bio: 'A playful leaf-sprite born from ancient stardust roots. Can sense quantum anomalies before they shift.',
        greeting: 'Pip-pip! The emerald leaves whisper your arrival, Observer!',
        primaryColor: Color(0xFF22C55E),
        secondaryColor: Color(0xFF86EFAC),
        glowColor: Color(0xFF4ADE80),
        icon: Icons.eco_rounded,
      ),
    ),
    SolarRealm(
      index: 1,
      id: 'amethea_iv',
      name: 'Amethea IV',
      romanNumeral: 'II',
      subTitle: 'The Amethyst Rings',
      chapterTitle: 'Chapter II: Echoes of the Prism Void',
      storyTransmission:
          'Amethea’s rings are trembling under void resonance. Align the giant quartz spires before the crystal core shatters!',
      missionObjective: 'Harmonize the Resonance Spires & rescue Lumi',
      biome: IslandBiome.cosmicCrystal,
      startLevel: 5,
      endLevel: 8,
      planetColor: Color(0xFFA855F7),
      atmosphereColor: Color(0xFFC084FC),
      ringColor: Color(0xFFE879F9),
      orbitRadius: 145,
      alien: AlienCompanion(
        id: 'lumi',
        name: 'Lumi',
        title: 'Prism-Fox',
        species: 'Crystalline Vulpix',
        bio: 'Born within geode meteors. Shimmers with pure refracted light and guides lost travelers through cosmic storms.',
        greeting: 'Chirp-glow! The violet facets sing when you find the differences!',
        primaryColor: Color(0xFFA855F7),
        secondaryColor: Color(0xFFE879F9),
        glowColor: Color(0xFFD8B4FE),
        icon: Icons.auto_awesome_rounded,
      ),
    ),
    SolarRealm(
      index: 2,
      id: 'pyrocron_forge',
      name: 'Pyrocron Core',
      romanNumeral: 'III',
      subTitle: 'The Molten Hearth',
      chapterTitle: 'Chapter III: The Heart of the Forge',
      storyTransmission:
          'Thermodynamic warning! The Pyrocron Core powers the interplanetary warp grid. Help Ignis vent the lava chambers!',
      missionObjective: 'Stabilize Basalt Chambers & ignite the Core',
      biome: IslandBiome.solarMagma,
      startLevel: 9,
      endLevel: 12,
      planetColor: Color(0xFFFF5722),
      atmosphereColor: Color(0xFFFF8A65),
      ringColor: Color(0xFFFFB74D),
      orbitRadius: 200,
      alien: AlienCompanion(
        id: 'ignis',
        name: 'Ignis',
        title: 'Cinder-Golem',
        species: 'Magmite Core',
        bio: 'A miniature living volcano with a molten heart of gold. Crafts indestructible shields from cooled basalt.',
        greeting: 'Grumble-spark! Hot lava flows, but your eyes are hotter, hero!',
        primaryColor: Color(0xFFFF6D00),
        secondaryColor: Color(0xFFFFAB40),
        glowColor: Color(0xFFFF3D00),
        icon: Icons.whatshot_rounded,
      ),
    ),
    SolarRealm(
      index: 3,
      id: 'aetheria_heights',
      name: 'Aetheria Clouds',
      romanNumeral: 'IV',
      subTitle: 'The Golden Stratosphere',
      chapterTitle: 'Chapter IV: Above the Solar Gale',
      storyTransmission:
          'Gravity is unstable! Navigate the golden celestial skyway and guide Zephyr through the turbulent solar storm!',
      missionObjective: 'Traverse the Golden Skyway & ascend the Sanctum',
      biome: IslandBiome.aetherCloud,
      startLevel: 13,
      endLevel: 16,
      planetColor: Color(0xFF38BDF8),
      atmosphereColor: Color(0xFF7DD3FC),
      ringColor: Color(0xFFFDE047),
      orbitRadius: 255,
      alien: AlienCompanion(
        id: 'zephyr',
        name: 'Zephyr',
        title: 'Sky-Nimbus',
        species: 'Celestial Cetacean',
        bio: 'Glides across golden cloud oceans. Inhales space dust and exhales glittering starlight rainbows.',
        greeting: 'Whoosh~ Welcome to the stratosphere! Keep your footing on the clouds!',
        primaryColor: Color(0xFF38BDF8),
        secondaryColor: Color(0xFFBAE6FD),
        glowColor: Color(0xFF7DD3FC),
        icon: Icons.cloud_rounded,
      ),
    ),
    SolarRealm(
      index: 4,
      id: 'starforge_omega',
      name: 'Starforge Omega',
      romanNumeral: 'V',
      subTitle: 'The Quantum Citadel',
      chapterTitle: 'Chapter V: The Master Architect',
      storyTransmission:
          'Final Sector! The central Dyson Sphere AI is locked by encrypted void shifts. Decode all sequences to save the Galaxy!',
      missionObjective: 'Overclock the Core Processor & liberate the Solar System',
      biome: IslandBiome.cyberStarforge,
      startLevel: 17,
      endLevel: 20,
      planetColor: Color(0xFF00E5FF),
      atmosphereColor: Color(0xFF18FFFF),
      ringColor: Color(0xFF7C4DFF),
      orbitRadius: 310,
      alien: AlienCompanion(
        id: 'volt',
        name: 'Volt',
        title: 'Quantum Drone',
        species: 'Nanite Matrix',
        bio: 'A hyper-intelligent cyber assistant created during the Golden Age. Calculates 1 billion shifts per millisecond.',
        greeting: 'Beep-boop! Quantum coherence at 99.8%. Ready for maximum processing!',
        primaryColor: AppColors.cyan,
        secondaryColor: Color(0xFF80D8FF),
        glowColor: Color(0xFF00E5FF),
        icon: Icons.memory_rounded,
      ),
    ),
  ];

  /// Get the realm that corresponds to a given level (1 to 20)
  static SolarRealm getRealmForLevel(int level) {
    final clamped = level.clamp(1, 20);
    final realmIdx = ((clamped - 1) ~/ 4).clamp(0, 4);
    return realms[realmIdx];
  }

  /// Get the role of an island based on its level within its realm
  static IslandRole getIslandRole(int level) {
    final indexInRealm = (level - 1) % 4;
    switch (indexInRealm) {
      case 0:
        return IslandRole.realmGateway;   // Entry pad
      case 1:
        return IslandRole.alienSanctuary; // Alien companion
      case 2:
        return IslandRole.crystalSpire;   // Power crystal
      case 3:
      default:
        return IslandRole.citadelCastle;  // Milestone Castle fortress
    }
  }
}
