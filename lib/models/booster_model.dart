import 'dart:ui';

/// Booster types available in BLINK
///
/// Each booster provides a strategic advantage during gameplay:
/// - [timeFreeze] — Extra observation time to study the scene
/// - [secondChance] — Retry a wrong answer once per round
/// - [revealHint] — Briefly highlights the change/answer
/// - [scoreMultiplier] — 2x gems earned for the entire session
/// - [streakShield] — Protects your combo streak on one mistake
enum BoosterType {
  timeFreeze,
  secondChance,
  revealHint,
  scoreMultiplier,
  streakShield,
}

/// Booster definition with metadata
class Booster {
  final BoosterType type;
  final String name;
  final String description;
  final String icon;
  final int gemCost;
  final Color color;
  final Color glowColor;

  const Booster({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.gemCost,
    required this.color,
    required this.glowColor,
  });

  /// All available boosters
  static const List<Booster> all = [
    Booster(
      type: BoosterType.timeFreeze,
      name: 'Chrono Freeze',
      description: '+3s extra observation time',
      icon: '⏳',
      gemCost: 50,
      color: Color(0xFF00E5FF),
      glowColor: Color(0x4000E5FF),
    ),
    Booster(
      type: BoosterType.secondChance,
      name: 'Shift Retry',
      description: 'Retry one wrong answer',
      icon: '🔄',
      gemCost: 75,
      color: Color(0xFF69F0AE),
      glowColor: Color(0x4069F0AE),
    ),
    Booster(
      type: BoosterType.revealHint,
      name: 'Nova\'s Eye',
      description: 'Briefly reveals the answer',
      icon: '👁',
      gemCost: 100,
      color: Color(0xFFAA00FF),
      glowColor: Color(0x40AA00FF),
    ),
    Booster(
      type: BoosterType.scoreMultiplier,
      name: 'Gem Storm',
      description: '2x gems for entire session',
      icon: '💎',
      gemCost: 150,
      color: Color(0xFFFFD740),
      glowColor: Color(0x40FFD740),
    ),
    Booster(
      type: BoosterType.streakShield,
      name: 'Nebula Shield',
      description: 'Protects combo on 1 mistake',
      icon: '🛡',
      gemCost: 60,
      color: Color(0xFF7C4DFF),
      glowColor: Color(0x407C4DFF),
    ),
  ];

  /// Look up a Booster definition by type
  static Booster fromType(BoosterType type) {
    return all.firstWhere((b) => b.type == type);
  }
}

/// Player's booster inventory — how many of each they own
class BoosterInventory {
  final Map<BoosterType, int> counts;

  const BoosterInventory({this.counts = const {}});

  /// Get count for a specific booster type
  int countOf(BoosterType type) => counts[type] ?? 0;

  /// Whether the player owns at least one of this booster
  bool has(BoosterType type) => countOf(type) > 0;

  /// Create a copy with one booster added
  BoosterInventory add(BoosterType type, [int amount = 1]) {
    final updated = Map<BoosterType, int>.from(counts);
    updated[type] = (updated[type] ?? 0) + amount;
    return BoosterInventory(counts: updated);
  }

  /// Create a copy with one booster consumed
  BoosterInventory use(BoosterType type) {
    final current = counts[type] ?? 0;
    if (current <= 0) return this;
    final updated = Map<BoosterType, int>.from(counts);
    updated[type] = current - 1;
    return BoosterInventory(counts: updated);
  }

  /// Serialize to a simple string for SharedPreferences storage
  /// Format: "timeFreeze:3,secondChance:1,streakShield:5"
  String encode() {
    return counts.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.key.name}:${e.value}')
        .join(',');
  }

  /// Deserialize from SharedPreferences string
  static BoosterInventory decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return const BoosterInventory();
    final map = <BoosterType, int>{};
    for (final part in encoded.split(',')) {
      final kv = part.split(':');
      if (kv.length == 2) {
        final type = BoosterType.values.where((t) => t.name == kv[0]).firstOrNull;
        final count = int.tryParse(kv[1]);
        if (type != null && count != null && count > 0) {
          map[type] = count;
        }
      }
    }
    return BoosterInventory(counts: map);
  }

  /// Total number of boosters owned
  int get totalCount => counts.values.fold(0, (a, b) => a + b);
}

/// Active boosters selected for the current gameplay session
class ActiveBoosters {
  final Set<BoosterType> selected;

  const ActiveBoosters({this.selected = const {}});

  bool isActive(BoosterType type) => selected.contains(type);

  bool get hasTimeFreeze => isActive(BoosterType.timeFreeze);
  bool get hasSecondChance => isActive(BoosterType.secondChance);
  bool get hasRevealHint => isActive(BoosterType.revealHint);
  bool get hasScoreMultiplier => isActive(BoosterType.scoreMultiplier);
  bool get hasStreakShield => isActive(BoosterType.streakShield);

  ActiveBoosters toggle(BoosterType type) {
    final updated = Set<BoosterType>.from(selected);
    if (updated.contains(type)) {
      updated.remove(type);
    } else if (updated.length < maxActive) {
      updated.add(type);
    }
    return ActiveBoosters(selected: updated);
  }

  /// Max boosters that can be active at once
  static const int maxActive = 3;

  bool get isFull => selected.length >= maxActive;
}
