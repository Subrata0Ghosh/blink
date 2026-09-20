import 'package:equatable/equatable.dart';

/// Core player state — persisted locally
class PlayerState extends Equatable {
  final String displayName;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int gems;
  final int totalChallenges;
  final int correctAnswers;
  final int bestCombo;
  final int currentStreak; // daily streak
  final int bestStreak;
  final int bestReactionTimeMs;
  final DateTime? lastPlayedDate;
  final bool onboardingComplete;
  final bool soundEnabled;
  final bool hapticEnabled;
  final double musicVolume;
  final double sfxVolume;
  final int worldLevel; // world growth progression

  const PlayerState({
    this.displayName = 'Observer',
    this.level = 1,
    this.xp = 0,
    this.xpToNextLevel = 100,
    this.gems = 0,
    this.totalChallenges = 0,
    this.correctAnswers = 0,
    this.bestCombo = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.bestReactionTimeMs = 0,
    this.lastPlayedDate,
    this.onboardingComplete = false,
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.musicVolume = 1.0,
    this.sfxVolume = 1.0,
    this.worldLevel = 1,
  });

  PlayerState copyWith({
    String? displayName,
    int? level,
    int? xp,
    int? xpToNextLevel,
    int? gems,
    int? totalChallenges,
    int? correctAnswers,
    int? bestCombo,
    int? currentStreak,
    int? bestStreak,
    int? bestReactionTimeMs,
    DateTime? lastPlayedDate,
    bool? onboardingComplete,
    bool? soundEnabled,
    bool? hapticEnabled,
    double? musicVolume,
    double? sfxVolume,
    int? worldLevel,
  }) {
    return PlayerState(
      displayName: displayName ?? this.displayName,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      gems: gems ?? this.gems,
      totalChallenges: totalChallenges ?? this.totalChallenges,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      bestCombo: bestCombo ?? this.bestCombo,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      bestReactionTimeMs: bestReactionTimeMs ?? this.bestReactionTimeMs,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      worldLevel: worldLevel ?? this.worldLevel,
    );
  }

  /// XP needed for a given level
  static int xpForLevel(int level) => 80 + (level * 20);

  @override
  List<Object?> get props => [
        displayName, level, xp, xpToNextLevel, gems, totalChallenges,
        correctAnswers, bestCombo, currentStreak, bestStreak,
        bestReactionTimeMs, lastPlayedDate, onboardingComplete,
        soundEnabled, hapticEnabled, musicVolume, sfxVolume, worldLevel,
      ];
}

/// Result of a single challenge round
class ChallengeResult {
  final bool correct;
  final int reactionTimeMs;
  final bool isPerfect;
  final int xpEarned;
  final int gemsEarned;
  final int combo;
  final String challengeType;

  const ChallengeResult({
    required this.correct,
    required this.reactionTimeMs,
    this.isPerfect = false,
    this.xpEarned = 0,
    this.gemsEarned = 0,
    this.combo = 0,
    this.challengeType = 'change',
  });
}
