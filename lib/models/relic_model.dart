import 'package:flutter/material.dart';

/// Represents a collectible Cosmic Relic in the Constellation Codex
class CosmicRelic {
  final String id;
  final String name;
  final String title;
  final String lore;
  final String perkDescription;
  final IconData icon;
  final Color auraColor;
  final int unlockLevel;
  final String unlockRequirement;

  const CosmicRelic({
    required this.id,
    required this.name,
    required this.title,
    required this.lore,
    required this.perkDescription,
    required this.icon,
    required this.auraColor,
    required this.unlockLevel,
    required this.unlockRequirement,
  });

  static const List<CosmicRelic> allRelics = [
    CosmicRelic(
      id: 'chrono_shard',
      name: 'Chrono Shard',
      title: 'Fragment of Still Time',
      lore: 'Forged in the timeless center of a dormant pulsar. Allows the observer to perceive what fleeting eyes miss.',
      perkDescription: '+1.0s observation time in all dimensions',
      icon: Icons.hourglass_top_rounded,
      auraColor: Color(0xFF00E5FF),
      unlockLevel: 2,
      unlockRequirement: 'Reach Observer Level 2',
    ),
    CosmicRelic(
      id: 'starlight_prism',
      name: 'Starlight Prism',
      title: 'Crystal of Harmonic Waves',
      lore: 'Refracts ambient cosmic light into pure harmonic stardust, multiplying rewards during unbroken streaks.',
      perkDescription: '+50% bonus Stardust on combo streaks',
      icon: Icons.diamond_rounded,
      auraColor: Color(0xFFA855F7),
      unlockLevel: 3,
      unlockRequirement: 'Reach Observer Level 3',
    ),
    CosmicRelic(
      id: 'nebula_heart',
      name: 'Nebula Heart',
      title: 'Pulsing Core of Creation',
      lore: 'A warm, living cluster of star-nursery plasma that shields observers when reality slips.',
      perkDescription: '1 free mistake absorption each day',
      icon: Icons.favorite_rounded,
      auraColor: Color(0xFFFF4081),
      unlockLevel: 3,
      unlockRequirement: 'Maintain a 3-Day login streak',
    ),
    CosmicRelic(
      id: 'singularity_bell',
      name: 'Singularity Bell',
      title: 'Harmonic Tone of Orion',
      lore: 'When tapped, its resonance pierces dimensional veils, singing with ancient celestial frequencies.',
      perkDescription: 'Harmonic crystalline chime on correct shifts',
      icon: Icons.notifications_active_rounded,
      auraColor: Color(0xFFFFD700),
      unlockLevel: 4,
      unlockRequirement: 'Reach Observer Level 4',
    ),
    CosmicRelic(
      id: 'eye_of_chronos',
      name: 'Eye of Chronos',
      title: 'The Supreme Watcher',
      lore: 'The ultimate insignia awarded only to Master Observers who have pierced the veil of the Shift World.',
      perkDescription: 'Permanent ethereal Zen aura and +100% XP',
      icon: Icons.remove_red_eye_rounded,
      auraColor: Color(0xFF00FFB2),
      unlockLevel: 5,
      unlockRequirement: 'Reach Observer Level 5',
    ),
  ];
}
