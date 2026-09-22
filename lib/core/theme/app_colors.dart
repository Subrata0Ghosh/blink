import 'dart:ui';

/// BLINK Color System — Dark cosmic palette with luminous crystal accents
class AppColors {
  AppColors._();

  // Base — Deep night / cosmic background
  static const Color background = Color(0xFF0A0E1A);
  static const Color backgroundLight = Color(0xFF121832);
  static const Color surface = Color(0xFF161D35);
  static const Color surfaceLight = Color(0xFF1E2747);

  // Primary — Electric violet / blue family
  static const Color primary = Color(0xFF7C4DFF);
  static const Color primaryLight = Color(0xFF9E7BFF);
  static const Color primaryDark = Color(0xFF5C2FE0);

  // Secondary — Cyan / mint accents
  static const Color cyan = Color(0xFF00E5FF);
  static const Color cyanLight = Color(0xFF66E5FF);
  static const Color cyanDark = Color(0xFF00B8D4);
  static const Color mint = Color(0xFF64FFDA);

  // Warm accent
  static const Color gold = Color(0xFFFFD740);
  static const Color warmYellow = Color(0xFFFFC107);
  static const Color amber = Color(0xFFFF9100);

  // Reward — Crystal glow
  static const Color gemPurple = Color(0xFFAA00FF);
  static const Color gemBlue = Color(0xFF2979FF);
  static const Color gemCyan = Color(0xFF00E5FF);
  static const Color gemGreen = Color(0xFF69F0AE);
  static const Color gemGold = Color(0xFFFFD740);
  static const Color gemRainbow = Color(0xFFFF6EE6);

  // Status
  static const Color success = Color(0xFF69F0AE);
  static const Color error = Color(0xFFFF5252);
  static const Color errorSoft = Color(0xFFFF8A80);
  static const Color warning = Color(0xFFFFD740);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF607D8B);

  // Overlay
  static const Color overlay = Color(0x80000000);
  static const Color glassWhite = Color(0x15FFFFFF);
  static const Color glassBorder = Color(0x20FFFFFF);

  // Rarity colors
  static const Color rarityCommon = Color(0xFF78909C);
  static const Color rarityRare = Color(0xFF2979FF);
  static const Color rarityEpic = Color(0xFFAA00FF);
  static const Color rarityLegendary = Color(0xFFFFD740);
  static const Color rarityMystery = Color(0xFFFF6EE6);

  // ──── COSMIC TACTILE BUTTON PALETTE ────
  // These provide light/dark/rim tones for the 3D tactile button system

  // Cosmic Cyan — Primary action (Play, Confirm)
  static const Color cosmicCyan = Color(0xFF00D4FF);
  static const Color cosmicCyanLight = Color(0xFF66E5FF);
  static const Color cosmicCyanDark = Color(0xFF009AC7);
  static const Color cosmicCyanRim = Color(0xFF006B8A);

  // Nebula Purple — Secondary action (Map, Navigate)
  static const Color nebulaPurple = Color(0xFF9C5BFF);
  static const Color nebulaPurpleLight = Color(0xFFBD8FFF);
  static const Color nebulaPurpleDark = Color(0xFF6E2FD4);
  static const Color nebulaPurpleRim = Color(0xFF4A1A94);

  // Solar Gold — Rewards, Premium
  static const Color solarGold = Color(0xFFFFCA28);
  static const Color solarGoldLight = Color(0xFFFFDF6B);
  static const Color solarGoldDark = Color(0xFFD49A00);
  static const Color solarGoldRim = Color(0xFF9E7000);

  // Stellar Green — Success, Correct
  static const Color stellarGreen = Color(0xFF4ADE80);
  static const Color stellarGreenLight = Color(0xFF86EFAC);
  static const Color stellarGreenDark = Color(0xFF22B957);
  static const Color stellarGreenRim = Color(0xFF137A3A);

  // Nova Orange — Warm accent, Events
  static const Color novaOrange = Color(0xFFFF8A50);
  static const Color novaOrangeLight = Color(0xFFFFB380);
  static const Color novaOrangeDark = Color(0xFFD45E24);
  static const Color novaOrangeRim = Color(0xFF993D12);

  // Danger Red — Wrong answer, Error
  static const Color dangerRed = Color(0xFFFF4D6A);
  static const Color dangerRedLight = Color(0xFFFF8099);
  static const Color dangerRedDark = Color(0xFFD42850);
  static const Color dangerRedRim = Color(0xFF941430);
}
