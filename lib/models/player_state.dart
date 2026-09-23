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
  final bool musicEnabled;
  final bool sfxEnabled;
  final bool hapticEnabled;
  final double musicVolume;
  final double sfxVolume;
  final int worldLevel; // world growth progression
  final String observerId;
  final String selectedAvatarId;
  final String selectedFrameId;
  final String country;
  final bool voiceEnabled;
  final bool monoAudio;
  final double audioBalance;
  final double bassWarmth;
  final double sparkleSoftness;

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
    this.musicEnabled = true,
    this.sfxEnabled = true,
    this.hapticEnabled = true,
    this.musicVolume = 0.5,
    this.sfxVolume = 0.8,
    this.worldLevel = 1,
    this.observerId = '16710538479',
    this.selectedAvatarId = 'nova_happy',
    this.selectedFrameId = 'frame_cyan',
    this.country = 'Cosmos',
    this.voiceEnabled = true,
    this.monoAudio = false,
    this.audioBalance = 0.0,
    this.bassWarmth = 0.5,
    this.sparkleSoftness = 0.6,
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
    bool? musicEnabled,
    bool? sfxEnabled,
    bool? hapticEnabled,
    double? musicVolume,
    double? sfxVolume,
    int? worldLevel,
    String? observerId,
    String? selectedAvatarId,
    String? selectedFrameId,
    String? country,
    bool? voiceEnabled,
    bool? monoAudio,
    double? audioBalance,
    double? bassWarmth,
    double? sparkleSoftness,
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
      musicEnabled: musicEnabled ?? this.musicEnabled,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      worldLevel: worldLevel ?? this.worldLevel,
      observerId: observerId ?? this.observerId,
      selectedAvatarId: selectedAvatarId ?? this.selectedAvatarId,
      selectedFrameId: selectedFrameId ?? this.selectedFrameId,
      country: country ?? this.country,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      monoAudio: monoAudio ?? this.monoAudio,
      audioBalance: audioBalance ?? this.audioBalance,
      bassWarmth: bassWarmth ?? this.bassWarmth,
      sparkleSoftness: sparkleSoftness ?? this.sparkleSoftness,
    );
  }

  /// XP needed for a given level
  static int xpForLevel(int level) => 80 + (level * 20);

  @override
  List<Object?> get props => [
        displayName, level, xp, xpToNextLevel, gems, totalChallenges,
        correctAnswers, bestCombo, currentStreak, bestStreak,
        bestReactionTimeMs, lastPlayedDate, onboardingComplete,
        soundEnabled, musicEnabled, sfxEnabled, hapticEnabled, musicVolume,
        sfxVolume, worldLevel, observerId, selectedAvatarId, selectedFrameId,
        country, voiceEnabled, monoAudio, audioBalance, bassWarmth, sparkleSoftness,
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
