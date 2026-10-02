import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_state.dart';

class LeaderboardEntry {
  final int rank;
  final String displayName;
  final int score;
  final int streak;
  final int level;
  final String avatarId;
  final String frameId;
  final bool isCurrentUser;
  final String region;

  const LeaderboardEntry({
    required this.rank,
    required this.displayName,
    required this.score,
    required this.streak,
    required this.level,
    required this.avatarId,
    required this.frameId,
    this.isCurrentUser = false,
    this.region = 'Cosmos',
  });
}

class DuelRecord {
  final String winner;
  final String loser;
  final int scoreWinner;
  final int scoreLoser;
  final DateTime timestamp;

  const DuelRecord({
    required this.winner,
    required this.loser,
    required this.scoreWinner,
    required this.scoreLoser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'winner': winner,
        'loser': loser,
        'scoreWinner': scoreWinner,
        'scoreLoser': scoreLoser,
        'timestamp': timestamp.toIso8601String(),
      };

  factory DuelRecord.fromJson(Map<String, dynamic> json) => DuelRecord(
        winner: json['winner'] as String? ?? 'Player 1',
        loser: json['loser'] as String? ?? 'Player 2',
        scoreWinner: json['scoreWinner'] as int? ?? 0,
        scoreLoser: json['scoreLoser'] as int? ?? 0,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

class LeaderboardService {
  static const String _keyDuelRecords = 'blink_offline_duel_records';

  /// Predefined cosmic observers for the galactic global leaderboard
  static final List<LeaderboardEntry> _baseGalacticObservers = [
    const LeaderboardEntry(
      rank: 1,
      displayName: 'AstralVanguard',
      score: 18450,
      streak: 42,
      level: 28,
      avatarId: 'nova_starlight',
      frameId: 'solar_halo',
      region: 'Andromeda',
    ),
    const LeaderboardEntry(
      rank: 2,
      displayName: 'NebulaEcho',
      score: 16200,
      streak: 35,
      level: 24,
      avatarId: 'zenith_gazer',
      frameId: 'prism_aurora',
      region: 'Orion',
    ),
    const LeaderboardEntry(
      rank: 3,
      displayName: 'QuantumShift',
      score: 14900,
      streak: 29,
      level: 22,
      avatarId: 'solar_seeker',
      frameId: 'nebula_rift',
      region: 'Centauri',
    ),
    const LeaderboardEntry(
      rank: 4,
      displayName: 'ChronoBlink',
      score: 12800,
      streak: 24,
      level: 19,
      avatarId: 'abyssal_eye',
      frameId: 'celestial_ring',
      region: 'Cygnus',
    ),
    const LeaderboardEntry(
      rank: 5,
      displayName: 'SolarisZen',
      score: 11450,
      streak: 21,
      level: 17,
      avatarId: 'prism_warden',
      frameId: 'solar_halo',
      region: 'Cassiopeia',
    ),
    const LeaderboardEntry(
      rank: 6,
      displayName: 'VoidObserver',
      score: 9800,
      streak: 18,
      level: 15,
      avatarId: 'cosmic_scout',
      frameId: 'abyssal_crown',
      region: 'Pegasus',
    ),
    const LeaderboardEntry(
      rank: 7,
      displayName: 'AetherKnight',
      score: 8650,
      streak: 14,
      level: 13,
      avatarId: 'nova_starlight',
      frameId: 'celestial_ring',
      region: 'Draco',
    ),
    const LeaderboardEntry(
      rank: 8,
      displayName: 'LuminaDrift',
      score: 7400,
      streak: 12,
      level: 11,
      avatarId: 'solar_seeker',
      frameId: 'prism_aurora',
      region: 'Lyra',
    ),
    const LeaderboardEntry(
      rank: 9,
      displayName: 'StardustMaven',
      score: 6300,
      streak: 10,
      level: 9,
      avatarId: 'zenith_gazer',
      frameId: 'nebula_rift',
      region: 'Aquila',
    ),
    const LeaderboardEntry(
      rank: 10,
      displayName: 'EclipseWanderer',
      score: 5200,
      streak: 8,
      level: 8,
      avatarId: 'cosmic_scout',
      frameId: 'celestial_ring',
      region: 'Vela',
    ),
  ];

  /// Get global galactic rankings dynamically incorporating current player's stats
  static List<LeaderboardEntry> getGlobalRankings(PlayerState player) {
    // Current player's computed score: level * 250 + xp + totalChallenges * 40
    final playerScore = (player.level * 250) + player.xp + (player.totalChallenges * 40);

    final playerEntry = LeaderboardEntry(
      rank: 0,
      displayName: player.displayName,
      score: playerScore,
      streak: player.currentStreak,
      level: player.level,
      avatarId: player.selectedAvatarId,
      frameId: player.selectedFrameId,
      isCurrentUser: true,
      region: player.country,
    );

    final list = List<LeaderboardEntry>.from(_baseGalacticObservers);
    list.add(playerEntry);
    list.sort((a, b) => b.score.compareTo(a.score));

    // Re-rank items
    final ranked = <LeaderboardEntry>[];
    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      ranked.add(LeaderboardEntry(
        rank: i + 1,
        displayName: item.displayName,
        score: item.score,
        streak: item.streak,
        level: item.level,
        avatarId: item.avatarId,
        frameId: item.frameId,
        isCurrentUser: item.isCurrentUser,
        region: item.region,
      ));
    }
    return ranked;
  }

  /// Record an offline duel match result
  static Future<void> recordDuelResult({
    required String winner,
    required String loser,
    required int scoreWinner,
    required int scoreLoser,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getDuelRecords();
    records.insert(
      0,
      DuelRecord(
        winner: winner,
        loser: loser,
        scoreWinner: scoreWinner,
        scoreLoser: scoreLoser,
        timestamp: DateTime.now(),
      ),
    );

    // Keep up to 50 latest duels
    if (records.length > 50) {
      records.removeRange(50, records.length);
    }

    final jsonList = records.map((r) => r.toJson()).toList();
    await prefs.setString(_keyDuelRecords, jsonEncode(jsonList));
  }

  /// Load all recorded local offline duels
  static Future<List<DuelRecord>> getDuelRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyDuelRecords);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => DuelRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
