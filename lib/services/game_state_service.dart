import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_state.dart';
import '../models/booster_model.dart';
import '../models/lucky_spin_model.dart';
import 'audio_service.dart';

/// Provider for SharedPreferences instance. Overridden in main.dart.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

/// Manages all persistent game state — XP, gems, streaks, progression
class GameStateNotifier extends StateNotifier<PlayerState> {
  final SharedPreferences? _prefs;
  bool _isSaving = false;
  bool _hasPendingSave = false;

  GameStateNotifier([this._prefs]) : super(_loadInitialState(_prefs)) {
    if (_prefs == null) {
      _loadStateAsyncFallback();
    } else {
      _syncAudioWithState();
    }
  }

  static double? _getDoubleSafe(SharedPreferences prefs, String key) {
    try {
      final val = prefs.get(key);
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is num) return val.toDouble();
      return null;
    } catch (_) {
      return null;
    }
  }

  static PlayerState _loadInitialState(SharedPreferences? prefs) {
    if (prefs == null) {
      return const PlayerState();
    }

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

    final lastDailyShiftStr = prefs.getString('lastDailyShiftCompletedDate');
    DateTime? lastDailyShiftDate;
    if (lastDailyShiftStr != null) {
      lastDailyShiftDate = DateTime.tryParse(lastDailyShiftStr);
    }

    final unlockedCollectibles = prefs.getStringList('unlockedCollectibleIds') ?? <String>['shift_gem'];
    final equippedCollectible = prefs.getString('equippedCollectibleId') ?? 'shift_gem';
    final unlockedWorldLevel = prefs.getInt('unlockedWorldLevel') ?? 1;
    final boosterInventory = BoosterInventory.decode(prefs.getString('boosterInventory'));

    final levelStars = <int, int>{};
    final levelStarsStr = prefs.getString('levelStars');
    if (levelStarsStr != null && levelStarsStr.isNotEmpty) {
      for (final part in levelStarsStr.split(',')) {
        final kv = part.split(':');
        if (kv.length == 2) {
          final k = int.tryParse(kv[0]);
          final v = int.tryParse(kv[1]);
          if (k != null && v != null) {
            levelStars[k] = v;
          }
        }
      }
    }

    final lastLuckySpinStr = prefs.getString('lastLuckySpinDate');
    final lastLuckySpinDate = lastLuckySpinStr != null ? DateTime.tryParse(lastLuckySpinStr) : null;

    final livesRaw = prefs.getInt('lives') ?? 5;
    final lastLifeLostStr = prefs.getString('lastLifeLostTime');
    final lastLifeLostTime = lastLifeLostStr != null ? DateTime.tryParse(lastLifeLostStr) : null;

    // Evaluate auto-regenerated hearts
    int computedLives = livesRaw;
    DateTime? adjustedLifeLostTime = lastLifeLostTime;
    if (computedLives < PlayerState.maxLives && lastLifeLostTime != null) {
      final elapsedMin = DateTime.now().difference(lastLifeLostTime).inMinutes;
      final regen = elapsedMin ~/ PlayerState.lifeRegenMinutes;
      if (regen > 0) {
        computedLives = (computedLives + regen).clamp(0, PlayerState.maxLives);
        if (computedLives >= PlayerState.maxLives) {
          adjustedLifeLostTime = null;
        } else {
          adjustedLifeLostTime = lastLifeLostTime.add(Duration(minutes: regen * PlayerState.lifeRegenMinutes));
        }
      }
    }

    return PlayerState(
      displayName: prefs.getString('displayName') ?? 'Observer',
      level: prefs.getInt('level') ?? 1,
      xp: prefs.getInt('xp') ?? 0,
      xpToNextLevel: prefs.getInt('xpToNextLevel') ?? 100,
      gems: prefs.getInt('gems') ?? 0,
      totalChallenges: prefs.getInt('totalChallenges') ?? 0,
      correctAnswers: prefs.getInt('correctAnswers') ?? 0,
      bestCombo: prefs.getInt('bestCombo') ?? 0,
      bestScore: prefs.getInt('bestScore') ?? 0,
      currentStreak: prefs.getInt('currentStreak') ?? 0,
      bestStreak: prefs.getInt('bestStreak') ?? 0,
      bestReactionTimeMs: prefs.getInt('bestReactionTimeMs') ?? 0,
      lastPlayedDate: lastPlayed,
      onboardingComplete: prefs.getBool('onboardingComplete') ?? false,
      soundEnabled: prefs.getBool('soundEnabled') ?? true,
      musicEnabled: prefs.getBool('musicEnabled') ?? true,
      sfxEnabled: prefs.getBool('sfxEnabled') ?? true,
      hapticEnabled: prefs.getBool('hapticEnabled') ?? true,
      musicVolume: _getDoubleSafe(prefs, 'musicVolume') ?? 0.5,
      sfxVolume: _getDoubleSafe(prefs, 'sfxVolume') ?? 0.8,
      worldLevel: prefs.getInt('worldLevel') ?? 1,
      observerId: prefs.getString('observerId') ?? '16710538479',
      selectedAvatarId: prefs.getString('selectedAvatarId') ?? 'nova_happy',
      selectedFrameId: prefs.getString('selectedFrameId') ?? 'frame_cyan',
      country: prefs.getString('country') ?? 'Cosmos',
      voiceEnabled: prefs.getBool('voiceEnabled') ?? true,
      monoAudio: prefs.getBool('monoAudio') ?? false,
      audioBalance: _getDoubleSafe(prefs, 'audioBalance') ?? 0.0,
      bassWarmth: _getDoubleSafe(prefs, 'bassWarmth') ?? 0.5,
      sparkleSoftness: _getDoubleSafe(prefs, 'sparkleSoftness') ?? 0.6,
      lastDailyRewardDate: lastDailyRewardDate,
      dailyRewardDay: dailyRewardDay,
      dailyQuestsClaimed: dailyQuestsClaimed,
      todayShiftsPlayed: todayShiftsPlayed,
      todayBestCombo: todayBestCombo,
      isCalmMode: prefs.getBool('isCalmMode') ?? false,
      unlockedCollectibleIds: unlockedCollectibles,
      equippedCollectibleId: equippedCollectible,
      unlockedWorldLevel: unlockedWorldLevel,
      levelStars: levelStars,
      lastDailyShiftCompletedDate: lastDailyShiftDate,
      boosterInventory: boosterInventory,
      lastLuckySpinDate: lastLuckySpinDate,
      lives: computedLives,
      lastLifeLostTime: adjustedLifeLostTime,
    );
  }

  void _syncAudioWithState() {
    AudioService().setSoundEnabled(state.soundEnabled);
    AudioService().setMusicEnabled(state.musicEnabled);
    AudioService().setSfxEnabled(state.sfxEnabled);
    AudioService().setMusicVolume(state.musicVolume);
    AudioService().setSfxVolume(state.sfxVolume);
    if (state.soundEnabled && state.musicEnabled && state.musicVolume > 0) {
      AudioService().startAmbientMusic();
    }
  }

  Future<void> _loadStateAsyncFallback() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = _loadInitialState(prefs);
    state = loaded.copyWith(
      onboardingComplete: state.onboardingComplete || loaded.onboardingComplete,
      displayName: state.displayName != 'Observer' ? state.displayName : loaded.displayName,
    );
    _syncAudioWithState();
  }

  Future<void> _saveState() async {
    if (_isSaving) {
      _hasPendingSave = true;
      return;
    }
    _isSaving = true;
    try {
      do {
        _hasPendingSave = false;
        final currentState = state;
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        final levelStarsEncoded = currentState.levelStars.entries.map((e) => '${e.key}:${e.value}').join(',');
        await Future.wait([
          prefs.setString('displayName', currentState.displayName),
          prefs.setInt('level', currentState.level),
          prefs.setInt('xp', currentState.xp),
          prefs.setInt('xpToNextLevel', currentState.xpToNextLevel),
          prefs.setInt('gems', currentState.gems),
          prefs.setInt('totalChallenges', currentState.totalChallenges),
          prefs.setInt('correctAnswers', currentState.correctAnswers),
          prefs.setInt('bestCombo', currentState.bestCombo),
          prefs.setInt('bestScore', currentState.bestScore),
          prefs.setInt('currentStreak', currentState.currentStreak),
          prefs.setInt('bestStreak', currentState.bestStreak),
          prefs.setInt('bestReactionTimeMs', currentState.bestReactionTimeMs),
          if (currentState.lastPlayedDate != null)
            prefs.setString('lastPlayedDate', currentState.lastPlayedDate!.toIso8601String()),
          prefs.setBool('onboardingComplete', currentState.onboardingComplete),
          prefs.setBool('soundEnabled', currentState.soundEnabled),
          prefs.setBool('musicEnabled', currentState.musicEnabled),
          prefs.setBool('sfxEnabled', currentState.sfxEnabled),
          prefs.setBool('hapticEnabled', currentState.hapticEnabled),
          prefs.setDouble('musicVolume', currentState.musicVolume),
          prefs.setDouble('sfxVolume', currentState.sfxVolume),
          prefs.setInt('worldLevel', currentState.worldLevel),
          prefs.setString('observerId', currentState.observerId),
          prefs.setString('selectedAvatarId', currentState.selectedAvatarId),
          prefs.setString('selectedFrameId', currentState.selectedFrameId),
          prefs.setString('country', currentState.country),
          prefs.setBool('voiceEnabled', currentState.voiceEnabled),
          prefs.setBool('monoAudio', currentState.monoAudio),
          prefs.setDouble('audioBalance', currentState.audioBalance),
          prefs.setDouble('bassWarmth', currentState.bassWarmth),
          prefs.setDouble('sparkleSoftness', currentState.sparkleSoftness),
          if (currentState.lastDailyRewardDate != null)
            prefs.setString('lastDailyRewardDate', currentState.lastDailyRewardDate!.toIso8601String()),
          prefs.setInt('dailyRewardDay', currentState.dailyRewardDay),
          prefs.setStringList('dailyQuestsClaimed', currentState.dailyQuestsClaimed),
          prefs.setInt('todayShiftsPlayed', currentState.todayShiftsPlayed),
          prefs.setInt('todayBestCombo', currentState.todayBestCombo),
          prefs.setBool('isCalmMode', currentState.isCalmMode),
          prefs.setStringList('unlockedCollectibleIds', currentState.unlockedCollectibleIds),
          prefs.setString('equippedCollectibleId', currentState.equippedCollectibleId),
          prefs.setInt('unlockedWorldLevel', currentState.unlockedWorldLevel),
          prefs.setString('levelStars', levelStarsEncoded),
          if (currentState.lastDailyShiftCompletedDate != null)
            prefs.setString('lastDailyShiftCompletedDate', currentState.lastDailyShiftCompletedDate!.toIso8601String()),
          prefs.setString('boosterInventory', currentState.boosterInventory.encode()),
          if (currentState.lastLuckySpinDate != null)
            prefs.setString('lastLuckySpinDate', currentState.lastLuckySpinDate!.toIso8601String()),
          prefs.setInt('lives', currentState.lives),
          if (currentState.lastLifeLostTime != null)
            prefs.setString('lastLifeLostTime', currentState.lastLifeLostTime!.toIso8601String())
          else
            prefs.remove('lastLifeLostTime'),
        ]);
      } while (_hasPendingSave);
    } catch (e, st) {
      debugPrint('Error saving game state to SharedPreferences: $e\n$st');
    } finally {
      _isSaving = false;
    }
  }

  Future<void> completeOnboarding(String name) async {
    state = state.copyWith(
      displayName: name.trim().isEmpty ? 'Observer' : name.trim(),
      onboardingComplete: true,
    );
    await _saveState();
  }

  /// Process a challenge result — update XP, gems, streak, level with relic perks
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

      // ── Relic Perk: Starlight Prism (Level 3+) gives +50% bonus Gems on combos ──
      if (state.level >= 3 && currentCombo >= 2) {
        gemsEarned = (gemsEarned * 1.5).round();
      }

      // ── Relic Perk: Eye of Chronos (Level 5+) doubles all earned XP (+100% XP) ──
      if (state.level >= 5) {
        xpEarned *= 2;
      }

      // Streak reward multiplier
      if (state.streakMultiplier > 1.0) {
        xpEarned = (xpEarned * state.streakMultiplier).round();
        gemsEarned = (gemsEarned * state.streakMultiplier).round();
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

  Future<void> addGems(int amount) async {
    state = state.copyWith(gems: state.gems + amount);
    await _saveState();
  }

  void addXp(int amount) {
    if (amount <= 0) return;
    int newXp = state.xp + amount;
    int newLevel = state.level;
    int newXpToNext = state.xpToNextLevel;
    int newWorldLevel = state.worldLevel;

    while (newXp >= newXpToNext) {
      newXp -= newXpToNext;
      newLevel++;
      newXpToNext = PlayerState.xpForLevel(newLevel);
      if (newLevel % 5 == 0) {
        newWorldLevel++;
      }
    }

    state = state.copyWith(
      xp: newXp,
      level: newLevel,
      xpToNextLevel: newXpToNext,
      worldLevel: newWorldLevel,
    );
    _saveState();
  }

  /// Unlock a collectible item by spending gems (or 0 for free/milestone unlock)
  Future<bool> unlockCollectible(String id, int costInGems) async {
    if (state.gems < costInGems) return false;
    final updatedUnlocked = List<String>.from(state.unlockedCollectibleIds);
    if (!updatedUnlocked.contains(id)) {
      updatedUnlocked.add(id);
    }
    state = state.copyWith(
      gems: state.gems - costInGems,
      unlockedCollectibleIds: updatedUnlocked,
      equippedCollectibleId: id,
    );
    await _saveState();
    return true;
  }

  /// Equip an unlocked collectible object into active arena gameplay
  Future<bool> equipCollectible(String id) async {
    if (!state.unlockedCollectibleIds.contains(id)) return false;
    state = state.copyWith(equippedCollectibleId: id);
    await _saveState();
    return true;
  }

  /// Complete a World Map level, record earned stars (1-3), and unlock next node
  Future<void> completeWorldLevel(int levelNum, int stars) async {
    final updatedStars = Map<int, int>.from(state.levelStars);
    final currentBest = updatedStars[levelNum] ?? 0;
    if (stars > currentBest) {
      updatedStars[levelNum] = stars;
    }
    int newUnlockedWorldLevel = state.unlockedWorldLevel;
    int gemBonus = 0;
    if (stars >= 1 && levelNum >= state.unlockedWorldLevel && state.unlockedWorldLevel < 20) {
      newUnlockedWorldLevel = levelNum + 1;
      gemBonus = stars * 10;
    }
    state = state.copyWith(
      unlockedWorldLevel: newUnlockedWorldLevel,
      levelStars: updatedStars,
      worldLevel: (newUnlockedWorldLevel - 1) ~/ 4 + 1,
      gems: state.gems + gemBonus,
    );
    await _saveState();
  }

  /// Mark today's Daily Shift challenge completed
  Future<void> completeDailyShift() async {
    state = state.copyWith(
      lastDailyShiftCompletedDate: DateTime.now(),
    );
    await _saveState();
  }


  /// Update best score and return true if this is a new personal record
  bool updateBestScore(int score) {
    if (score > state.bestScore) {
      state = state.copyWith(bestScore: score);
      _saveState();
      return true;
    }
    return false;
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

  // ──────────── BOOSTER SYSTEM ────────────

  /// Purchase a booster with gems
  Future<bool> purchaseBooster(BoosterType type) async {
    final booster = Booster.fromType(type);
    if (state.gems < booster.gemCost) return false;
    state = state.copyWith(
      gems: state.gems - booster.gemCost,
      boosterInventory: state.boosterInventory.add(type),
    );
    await _saveState();
    return true;
  }

  /// Consume one booster from inventory (called when a session starts with boosters)
  void consumeBooster(BoosterType type) {
    if (!state.boosterInventory.has(type)) return;
    state = state.copyWith(
      boosterInventory: state.boosterInventory.use(type),
    );
    _saveState();
  }

  /// Consume multiple boosters at once (called when starting a session with selected boosters)
  void consumeBoosters(Set<BoosterType> types) {
    var inventory = state.boosterInventory;
    for (final type in types) {
      if (inventory.has(type)) {
        inventory = inventory.use(type);
      }
    }
    state = state.copyWith(boosterInventory: inventory);
    _saveState();
  }

  /// Award free boosters (from chests, achievements, daily rewards)
  Future<void> awardBooster(BoosterType type, [int amount = 1]) async {
    state = state.copyWith(
      boosterInventory: state.boosterInventory.add(type, amount),
    );
    await _saveState();
  }

  // ──────────── LUCKY SPIN SYSTEM ────────────

  /// Spin the Lucky Wheel. Returns the selected prize.
  /// If [useGems] is true, checks for 30 gems and deducts them.
  /// Otherwise marks today's free spin as used.
  Future<LuckySpinPrize?> spinLuckyWheel({bool useGems = false}) async {
    if (useGems) {
      if (state.gems < 30) return null;
      state = state.copyWith(gems: state.gems - 30);
    } else {
      if (!state.isLuckySpinAvailable) return null;
      state = state.copyWith(lastLuckySpinDate: DateTime.now());
    }

    // Weighted random selection
    final totalWeight = LuckySpinPrize.prizes.fold<int>(0, (sum, p) => sum + p.weight);
    int randomWeight = Random().nextInt(totalWeight);
    LuckySpinPrize selected = LuckySpinPrize.prizes.first;
    for (final prize in LuckySpinPrize.prizes) {
      randomWeight -= prize.weight;
      if (randomWeight < 0) {
        selected = prize;
        break;
      }
    }

    // Grant prize
    if (selected.type == SpinPrizeType.gems) {
      state = state.copyWith(gems: state.gems + selected.amount);
    } else if (selected.type == SpinPrizeType.booster && selected.boosterType != null) {
      state = state.copyWith(
        boosterInventory: state.boosterInventory.add(selected.boosterType!, selected.amount),
      );
    }

    await _saveState();
    return selected;
  }

  // ──────────── LIVES / ENERGY SYSTEM ────────────

  /// Sync auto-regenerated lives based on elapsed time
  void syncLives() {
    final current = state.currentLives;
    if (current != state.lives) {
      DateTime? newLostTime = state.lastLifeLostTime;
      if (current >= PlayerState.maxLives) {
        newLostTime = null;
      }
      state = state.copyWith(lives: current, lastLifeLostTime: newLostTime);
      _saveState();
    }
  }

  /// Consume 1 heart upon session failure / wrong answer
  bool consumeLife() {
    syncLives();
    if (state.lives <= 0) return false;
    final newLives = state.lives - 1;
    final newLostTime = (state.lives == PlayerState.maxLives)
        ? DateTime.now()
        : (state.lastLifeLostTime ?? DateTime.now());
    state = state.copyWith(
      lives: newLives,
      lastLifeLostTime: newLostTime,
    );
    _saveState();
    return true;
  }

  /// Instant full refill with 50 gems
  Future<bool> refillLivesWithGems() async {
    const cost = 50;
    if (state.gems < cost) return false;
    state = state.copyWith(
      gems: state.gems - cost,
      lives: PlayerState.maxLives,
      lastLifeLostTime: null,
    );
    await _saveState();
    return true;
  }

  /// Add free lives (from rewards or ads)
  Future<void> addLives([int count = 1]) async {
    final newLives = (state.currentLives + count).clamp(0, PlayerState.maxLives);
    state = state.copyWith(
      lives: newLives,
      lastLifeLostTime: newLives >= PlayerState.maxLives ? null : state.lastLifeLostTime,
    );
    await _saveState();
  }
}

/// Global provider
final gameStateProvider = StateNotifierProvider<GameStateNotifier, PlayerState>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    // Graceful fallback for standalone tests where ProviderScope doesn't override sharedPreferencesProvider
  }
  return GameStateNotifier(prefs);
});
