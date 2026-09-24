import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_state.dart';
import 'audio_service.dart';

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

    final lastDailyRewardStr = prefs.getString('lastDailyRewardDate');
    DateTime? lastDailyRewardDate;
    if (lastDailyRewardStr != null) {
      lastDailyRewardDate = DateTime.tryParse(lastDailyRewardStr);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if new day for today's quest metrics
    bool isNewDay = true;
    if (lastPlayed != null) {
      final lastDay = DateTime(lastPlayed.year, lastPlayed.month, lastPlayed.day);
      if (today.isAtSameMomentAs(lastDay)) {
        isNewDay = false;
      }
    }

    // Check 7-day streak broken condition
    int dailyRewardDay = prefs.getInt('dailyRewardDay') ?? 1;
    if (lastDailyRewardDate != null) {
      final lastRewardDay = DateTime(
        lastDailyRewardDate.year,
        lastDailyRewardDate.month,
        lastDailyRewardDate.day,
      );
      final daysDiff = today.difference(lastRewardDay).inDays;
      if (daysDiff > 1) {
        // Missed a day -> reset to Day 1
        dailyRewardDay = 1;
      }
    }

    final todayShiftsPlayed = isNewDay ? 0 : (prefs.getInt('todayShiftsPlayed') ?? 0);
    final todayBestCombo = isNewDay ? 0 : (prefs.getInt('todayBestCombo') ?? 0);
    final dailyQuestsClaimed = isNewDay ? <String>[] : (prefs.getStringList('dailyQuestsClaimed') ?? <String>[]);

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
      musicEnabled: prefs.getBool('musicEnabled') ?? true,
      sfxEnabled: prefs.getBool('sfxEnabled') ?? true,
      hapticEnabled: prefs.getBool('hapticEnabled') ?? true,
      musicVolume: prefs.getDouble('musicVolume') ?? 0.5,
      sfxVolume: prefs.getDouble('sfxVolume') ?? 0.8,
      worldLevel: prefs.getInt('worldLevel') ?? 1,
      observerId: prefs.getString('observerId') ?? '16710538479',
      selectedAvatarId: prefs.getString('selectedAvatarId') ?? 'nova_happy',
      selectedFrameId: prefs.getString('selectedFrameId') ?? 'frame_cyan',
      country: prefs.getString('country') ?? 'Cosmos',
      voiceEnabled: prefs.getBool('voiceEnabled') ?? true,
      monoAudio: prefs.getBool('monoAudio') ?? false,
      audioBalance: prefs.getDouble('audioBalance') ?? 0.0,
      bassWarmth: prefs.getDouble('bassWarmth') ?? 0.5,
      sparkleSoftness: prefs.getDouble('sparkleSoftness') ?? 0.6,
      lastDailyRewardDate: lastDailyRewardDate,
      dailyRewardDay: dailyRewardDay,
      dailyQuestsClaimed: dailyQuestsClaimed,
      todayShiftsPlayed: todayShiftsPlayed,
      todayBestCombo: todayBestCombo,
      isCalmMode: prefs.getBool('isCalmMode') ?? false,
    );

    AudioService().setSoundEnabled(state.soundEnabled);
    AudioService().setMusicEnabled(state.musicEnabled);
    AudioService().setSfxEnabled(state.sfxEnabled);
    AudioService().setMusicVolume(state.musicVolume);
    AudioService().setSfxVolume(state.sfxVolume);
    if (state.soundEnabled && state.musicEnabled && state.musicVolume > 0) {
      AudioService().startAmbientMusic();
    }
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
    await prefs.setBool('musicEnabled', state.musicEnabled);
    await prefs.setBool('sfxEnabled', state.sfxEnabled);
    await prefs.setBool('hapticEnabled', state.hapticEnabled);
    await prefs.setDouble('musicVolume', state.musicVolume);
    await prefs.setDouble('sfxVolume', state.sfxVolume);
    await prefs.setInt('worldLevel', state.worldLevel);
    await prefs.setString('observerId', state.observerId);
    await prefs.setString('selectedAvatarId', state.selectedAvatarId);
    await prefs.setString('selectedFrameId', state.selectedFrameId);
    await prefs.setString('country', state.country);
    await prefs.setBool('voiceEnabled', state.voiceEnabled);
    await prefs.setBool('monoAudio', state.monoAudio);
    await prefs.setDouble('audioBalance', state.audioBalance);
    await prefs.setDouble('bassWarmth', state.bassWarmth);
    await prefs.setDouble('sparkleSoftness', state.sparkleSoftness);
    if (state.lastDailyRewardDate != null) {
      await prefs.setString('lastDailyRewardDate', state.lastDailyRewardDate!.toIso8601String());
    }
    await prefs.setInt('dailyRewardDay', state.dailyRewardDay);
    await prefs.setStringList('dailyQuestsClaimed', state.dailyQuestsClaimed);
    await prefs.setInt('todayShiftsPlayed', state.todayShiftsPlayed);
    await prefs.setInt('todayBestCombo', state.todayBestCombo);
    await prefs.setBool('isCalmMode', state.isCalmMode);
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

    final newTodayShifts = state.todayShiftsPlayed + 1;
    final newTodayBestCombo = currentCombo > state.todayBestCombo ? currentCombo : state.todayBestCombo;

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
      todayShiftsPlayed: newTodayShifts,
      todayBestCombo: newTodayBestCombo,
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
    final next = !state.soundEnabled;
    state = state.copyWith(soundEnabled: next);
    AudioService().setSoundEnabled(next);
    _saveState();
  }

  void toggleMusic() {
    final next = !state.musicEnabled;
    state = state.copyWith(musicEnabled: next);
    AudioService().setMusicEnabled(next);
    _saveState();
  }

  void toggleSfx() {
    final next = !state.sfxEnabled;
    state = state.copyWith(sfxEnabled: next);
    AudioService().setSfxEnabled(next);
    _saveState();
  }

  void toggleHaptic() {
    state = state.copyWith(hapticEnabled: !state.hapticEnabled);
    _saveState();
  }

  void setMusicVolume(double vol) {
    state = state.copyWith(musicVolume: vol);
    AudioService().setMusicVolume(vol);
    _saveState();
  }

  void setSfxVolume(double vol) {
    state = state.copyWith(sfxVolume: vol);
    AudioService().setSfxVolume(vol);
    _saveState();
  }

  void setAvatar(String avatarId) {
    state = state.copyWith(selectedAvatarId: avatarId);
    _saveState();
  }

  void setFrame(String frameId) {
    state = state.copyWith(selectedFrameId: frameId);
    _saveState();
  }

  void setDisplayName(String name) {
    if (name.trim().isNotEmpty) {
      state = state.copyWith(displayName: name.trim());
      _saveState();
    }
  }

  void setAudioTuning({
    bool? voiceEnabled,
    bool? monoAudio,
    double? audioBalance,
    double? bassWarmth,
    double? sparkleSoftness,
  }) {
    state = state.copyWith(
      voiceEnabled: voiceEnabled ?? state.voiceEnabled,
      monoAudio: monoAudio ?? state.monoAudio,
      audioBalance: audioBalance ?? state.audioBalance,
      bassWarmth: bassWarmth ?? state.bassWarmth,
      sparkleSoftness: sparkleSoftness ?? state.sparkleSoftness,
    );
    _saveState();
  }

  /// Claim the 7-day cosmic streak reward
  Map<String, int> claimDailyReward() {
    final day = state.dailyRewardDay;
    // Rewards per day:
    // Day 1: 50 gems, 25 XP
    // Day 2: 75 gems, 40 XP
    // Day 3: 100 gems, 60 XP
    // Day 4: 150 gems, 80 XP
    // Day 5: 200 gems, 100 XP
    // Day 6: 250 gems, 120 XP
    // Day 7: 500 gems, 250 XP (Grand Cosmic Starlight Chest!)
    const rewardsTable = [
      {'gems': 50, 'xp': 25},
      {'gems': 75, 'xp': 40},
      {'gems': 100, 'xp': 60},
      {'gems': 150, 'xp': 80},
      {'gems': 200, 'xp': 100},
      {'gems': 250, 'xp': 120},
      {'gems': 500, 'xp': 250},
    ];

    final reward = rewardsTable[(day - 1).clamp(0, 6)];
    final gemsGained = reward['gems']!;
    final xpGained = reward['xp']!;

    int newXp = state.xp + xpGained;
    int newLevel = state.level;
    int newXpToNext = state.xpToNextLevel;
    int newWorldLevel = state.worldLevel;

    while (newXp >= newXpToNext) {
      newXp -= newXpToNext;
      newLevel++;
      newXpToNext = PlayerState.xpForLevel(newLevel);
      if (newLevel % 5 == 0) newWorldLevel++;
    }

    final nextDay = day >= 7 ? 1 : day + 1;

    state = state.copyWith(
      gems: state.gems + gemsGained,
      xp: newXp,
      level: newLevel,
      xpToNextLevel: newXpToNext,
      worldLevel: newWorldLevel,
      lastDailyRewardDate: DateTime.now(),
      dailyRewardDay: nextDay,
    );
    _saveState();

    return {'gems': gemsGained, 'xp': xpGained, 'dayClaimed': day};
  }

  /// Claim a daily quest reward
  void claimDailyQuest(String questId, int gems, int xp) {
    if (state.dailyQuestsClaimed.contains(questId)) return;

    final updatedClaimed = List<String>.from(state.dailyQuestsClaimed)..add(questId);

    int newXp = state.xp + xp;
    int newLevel = state.level;
    int newXpToNext = state.xpToNextLevel;
    int newWorldLevel = state.worldLevel;

    while (newXp >= newXpToNext) {
      newXp -= newXpToNext;
      newLevel++;
      newXpToNext = PlayerState.xpForLevel(newLevel);
      if (newLevel % 5 == 0) newWorldLevel++;
    }

    state = state.copyWith(
      gems: state.gems + gems,
      xp: newXp,
      level: newLevel,
      xpToNextLevel: newXpToNext,
      worldLevel: newWorldLevel,
      dailyQuestsClaimed: updatedClaimed,
    );
    _saveState();
  }

  void setCalmMode(bool enabled) {
    state = state.copyWith(isCalmMode: enabled);
    _saveState();
  }
}

/// Global provider
final gameStateProvider = StateNotifierProvider<GameStateNotifier, PlayerState>((ref) {
  return GameStateNotifier();
});
