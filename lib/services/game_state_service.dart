import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_state.dart';

/// Manages all persistent game state — XP, gems, streaks, progression
class GameStateNotifier extends StateNotifier<PlayerState> {
  GameStateNotifier() : super(const PlayerState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlayedStr = prefs.getString('lastPlayedDate');
    DateTime? lastPlayed;
    if (lastPlayedStr != null) {
      lastPlayed = DateTime.tryParse(lastPlayedStr);
    }

    state = PlayerState(
      displayName: prefs.getString('displayName') ?? 'Observer',
      level: prefs.getInt('level') ?? 1,
      xp: prefs.getInt('xp') ?? 0,
      xpToNextLevel: prefs.getInt('xpToNextLevel') ?? 100,
      gems: prefs.getInt('gems') ?? 0,
      totalChallenges: prefs.getInt('totalChallenges') ?? 0,
      correctAnswers: prefs.getInt('correctAnswers') ?? 0,
      bestCombo: prefs.getInt('bestCombo') ?? 0,
      currentStreak: prefs.getInt('currentStreak') ?? 0,
      bestStreak: prefs.getInt('bestStreak') ?? 0,
      bestReactionTimeMs: prefs.getInt('bestReactionTimeMs') ?? 0,
      lastPlayedDate: lastPlayed,
      onboardingComplete: prefs.getBool('onboardingComplete') ?? false,
      soundEnabled: prefs.getBool('soundEnabled') ?? true,
      hapticEnabled: prefs.getBool('hapticEnabled') ?? true,
      musicVolume: prefs.getDouble('musicVolume') ?? 1.0,
      sfxVolume: prefs.getDouble('sfxVolume') ?? 1.0,
      worldLevel: prefs.getInt('worldLevel') ?? 1,
    );
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('displayName', state.displayName);
    await prefs.setInt('level', state.level);
    await prefs.setInt('xp', state.xp);
    await prefs.setInt('xpToNextLevel', state.xpToNextLevel);
    await prefs.setInt('gems', state.gems);
    await prefs.setInt('totalChallenges', state.totalChallenges);
    await prefs.setInt('correctAnswers', state.correctAnswers);
    await prefs.setInt('bestCombo', state.bestCombo);
    await prefs.setInt('currentStreak', state.currentStreak);
    await prefs.setInt('bestStreak', state.bestStreak);
    await prefs.setInt('bestReactionTimeMs', state.bestReactionTimeMs);
    if (state.lastPlayedDate != null) {
      await prefs.setString('lastPlayedDate', state.lastPlayedDate!.toIso8601String());
    }
    await prefs.setBool('onboardingComplete', state.onboardingComplete);
    await prefs.setBool('soundEnabled', state.soundEnabled);
    await prefs.setBool('hapticEnabled', state.hapticEnabled);
    await prefs.setDouble('musicVolume', state.musicVolume);
    await prefs.setDouble('sfxVolume', state.sfxVolume);
    await prefs.setInt('worldLevel', state.worldLevel);
  }

  void completeOnboarding(String name) {
    state = state.copyWith(
      displayName: name.isEmpty ? 'Observer' : name,
      onboardingComplete: true,
    );
    _saveState();
  }

  /// Process a challenge result — update XP, gems, streak, level
  ChallengeResult processChallengeResult({
    required bool correct,
    required int reactionTimeMs,
    required int currentCombo,
    required String challengeType,
  }) {
    final isPerfect = correct && reactionTimeMs < 2000;
    int xpEarned = 0;
    int gemsEarned = 0;

    if (correct) {
      xpEarned = 10;
      gemsEarned = 5;

      if (isPerfect) {
        xpEarned += 10;
        gemsEarned += 5;
      }

      // Combo bonus
      if (currentCombo >= 10) {
        xpEarned += 15;
        gemsEarned += 10;
      } else if (currentCombo >= 5) {
        xpEarned += 10;
        gemsEarned += 5;
      } else if (currentCombo >= 3) {
        xpEarned += 5;
        gemsEarned += 3;
      }
    }

    int newXp = state.xp + xpEarned;
    int newLevel = state.level;
    int newXpToNext = state.xpToNextLevel;
    int newWorldLevel = state.worldLevel;

    // Level up check
    while (newXp >= newXpToNext) {
      newXp -= newXpToNext;
      newLevel++;
      newXpToNext = PlayerState.xpForLevel(newLevel);

      // World progression
      if (newLevel % 5 == 0) {
        newWorldLevel++;
      }
    }

    final newBestCombo = currentCombo > state.bestCombo ? currentCombo : state.bestCombo;
    final newBestReaction = (correct && (state.bestReactionTimeMs == 0 || reactionTimeMs < state.bestReactionTimeMs))
        ? reactionTimeMs
        : state.bestReactionTimeMs;

    state = state.copyWith(
      level: newLevel,
      xp: newXp,
      xpToNextLevel: newXpToNext,
      gems: state.gems + gemsEarned,
      totalChallenges: state.totalChallenges + 1,
      correctAnswers: correct ? state.correctAnswers + 1 : state.correctAnswers,
      bestCombo: newBestCombo,
      bestReactionTimeMs: newBestReaction,
      lastPlayedDate: DateTime.now(),
      worldLevel: newWorldLevel,
    );
    _saveState();

    return ChallengeResult(
      correct: correct,
      reactionTimeMs: reactionTimeMs,
      isPerfect: isPerfect,
      xpEarned: xpEarned,
      gemsEarned: gemsEarned,
      combo: currentCombo,
      challengeType: challengeType,
    );
  }

  void updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (state.lastPlayedDate != null) {
      final lastDate = DateTime(
        state.lastPlayedDate!.year,
        state.lastPlayedDate!.month,
        state.lastPlayedDate!.day,
      );
      final diff = today.difference(lastDate).inDays;
      
      if (diff == 1) {
        // Consecutive day
        final newStreak = state.currentStreak + 1;
        state = state.copyWith(
          currentStreak: newStreak,
          bestStreak: newStreak > state.bestStreak ? newStreak : state.bestStreak,
        );
      } else if (diff > 1) {
        // Streak broken
        state = state.copyWith(currentStreak: 1);
      }
      // diff == 0 means same day, no change
    } else {
      state = state.copyWith(currentStreak: 1);
    }
    _saveState();
  }

  void toggleSound() {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
    _saveState();
  }

  void toggleHaptic() {
    state = state.copyWith(hapticEnabled: !state.hapticEnabled);
    _saveState();
  }
}

/// Global provider
final gameStateProvider = StateNotifierProvider<GameStateNotifier, PlayerState>((ref) {
  return GameStateNotifier();
});
