import 'package:flutter/material.dart';
import 'booster_model.dart';

enum SpinPrizeType {
  gems,
  booster,
}

class LuckySpinPrize {
  final String id;
  final String label;
  final String icon;
  final SpinPrizeType type;
  final int amount;
  final BoosterType? boosterType;
  final Color primaryColor;
  final Color secondaryColor;
  final int weight; // Selection weight for spin calculation

  const LuckySpinPrize({
    required this.id,
    required this.label,
    required this.icon,
    required this.type,
    required this.amount,
    this.boosterType,
    required this.primaryColor,
    required this.secondaryColor,
    this.weight = 10,
  });

  /// The 8 cosmic prizes on the wheel
  static const List<LuckySpinPrize> prizes = [
    LuckySpinPrize(
      id: 'gems_50',
      label: '50 GEMS',
      icon: '💎',
      type: SpinPrizeType.gems,
      amount: 50,
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF0077B6),
      weight: 30,
    ),
    LuckySpinPrize(
      id: 'booster_time_freeze',
      label: '+3s FREEZE',
      icon: '⏱️',
      type: SpinPrizeType.booster,
      amount: 1,
      boosterType: BoosterType.timeFreeze,
      primaryColor: Color(0xFF48CAE4),
      secondaryColor: Color(0xFF0096C7),
      weight: 18,
    ),
    LuckySpinPrize(
      id: 'gems_100',
      label: '100 GEMS',
      icon: '💎',
      type: SpinPrizeType.gems,
      amount: 100,
      primaryColor: Color(0xFF7000FF),
      secondaryColor: Color(0xFF4A00B0),
      weight: 15,
    ),
    LuckySpinPrize(
      id: 'booster_second_chance',
      label: 'RETRY',
      icon: '🔄',
      type: SpinPrizeType.booster,
      amount: 1,
      boosterType: BoosterType.secondChance,
      primaryColor: Color(0xFFFF9E00),
      secondaryColor: Color(0xFFCC7A00),
      weight: 14,
    ),
    LuckySpinPrize(
      id: 'booster_hint',
      label: 'HINT',
      icon: '👁️',
      type: SpinPrizeType.booster,
      amount: 1,
      boosterType: BoosterType.revealHint,
      primaryColor: Color(0xFF9D4EDD),
      secondaryColor: Color(0xFF5A189A),
      weight: 12,
    ),
    LuckySpinPrize(
      id: 'gems_250',
      label: '250 JACKPOT!',
      icon: '👑',
      type: SpinPrizeType.gems,
      amount: 250,
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFFFFA000),
      weight: 5,
    ),
    LuckySpinPrize(
      id: 'booster_shield',
      label: 'SHIELD',
      icon: '🛡️',
      type: SpinPrizeType.booster,
      amount: 1,
      boosterType: BoosterType.streakShield,
      primaryColor: Color(0xFF06D6A0),
      secondaryColor: Color(0xFF048A66),
      weight: 14,
    ),
    LuckySpinPrize(
      id: 'booster_multiplier',
      label: '2x GEMS',
      icon: '🔮',
      type: SpinPrizeType.booster,
      amount: 1,
      boosterType: BoosterType.scoreMultiplier,
      primaryColor: Color(0xFFFF007F),
      secondaryColor: Color(0xFF99004C),
      weight: 12,
    ),
  ];
}
