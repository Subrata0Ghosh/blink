import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blink/models/player_state.dart';
import 'package:blink/services/app_review_share_service.dart';
import 'package:blink/services/game_state_service.dart';
import 'package:blink/services/leaderboard_service.dart';
import 'package:blink/screens/leaderboard/leaderboard_screen.dart';
import 'package:blink/screens/multiplayer/multiplayer_hub_screen.dart';
import 'package:blink/screens/multiplayer/local_duel_screen.dart';
import 'package:blink/widgets/modals/rate_app_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LeaderboardService Tests', () {
    test('getGlobalRankings places player in ranking list based on score and stats', () {
      const player = PlayerState(
        displayName: 'AstroPlayer',
        level: 5,
        totalChallenges: 50,
        correctAnswers: 48,
        bestCombo: 15,
        country: 'Mars Base',
      );

      final rankings = LeaderboardService.getGlobalRankings(player);

      expect(rankings, isNotEmpty);
      expect(rankings.length, greaterThanOrEqualTo(10));

      final playerEntry = rankings.firstWhere((r) => r.isCurrentUser);
      expect(playerEntry.displayName, equals('AstroPlayer'));
      expect(playerEntry.isCurrentUser, isTrue);
      expect(playerEntry.rank, greaterThan(0));
    });

    test('recordDuelResult saves and retrieves offline duel history', () async {
      SharedPreferences.setMockInitialValues({});

      await LeaderboardService.recordDuelResult(
        winner: 'Cosmo',
        loser: 'Nova',
        scoreWinner: 3,
        scoreLoser: 1,
      );

      final records = await LeaderboardService.getDuelRecords();
      expect(records.length, equals(1));
      expect(records.first.winner, equals('Cosmo'));
      expect(records.first.loser, equals('Nova'));
      expect(records.first.scoreWinner, equals(3));
      expect(records.first.scoreLoser, equals(1));
    });
  });

  group('AppReviewShareService Tests', () {
    test('hasUserRated returns false initially and true once saved', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AppReviewShareService.hasUserRated(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppReviewShareService.keyHasRated, true);
      expect(await AppReviewShareService.hasUserRated(), isTrue);
    });
  });

  group('RateAppModal Widget Tests', () {
    testWidgets('RateAppModal displays 5 stars and handles rating submission', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            gameStateProvider.overrideWith((ref) => GameStateNotifier(prefs)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RateAppModal(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verify Rate modal elements
      expect(find.text('Enjoying BLINK?'), findsOneWidget);
      expect(find.text('SUBMIT & GET +50 GEMS'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));

      // Tap 5th star
      final stars = find.byIcon(Icons.star_rounded);
      await tester.tap(stars.last);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Astronomical! 🌟'), findsOneWidget);

      // Tap submit button
      await tester.tap(find.text('SUBMIT & GET +50 GEMS'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('CLAIMED +50 GEMS! ✨'), findsOneWidget);
    });
  });

  group('MultiplayerHubScreen Widget Tests', () {
    testWidgets('MultiplayerHubScreen renders Both Same-Device and Wi-Fi options', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            gameStateProvider.overrideWith((ref) => GameStateNotifier(prefs)),
          ],
          child: const MaterialApp(
            home: MultiplayerHubScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Check header and options
      expect(find.text('OFFLINE MULTIPLAYER'), findsOneWidget);
      expect(find.text('SAME-DEVICE DUEL'), findsOneWidget);
      expect(find.text('LOCAL WI-FI / HOTSPOT'), findsOneWidget);
      expect(find.text('START DUEL'), findsOneWidget);
      expect(find.text('HOST OR JOIN ROOM'), findsOneWidget);
    });
  });

  group('LocalDuelScreen Widget Tests', () {
    testWidgets('LocalDuelScreen renders setup phase with player inputs and start button', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            gameStateProvider.overrideWith((ref) => GameStateNotifier(prefs)),
          ],
          child: const MaterialApp(
            home: LocalDuelScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('DUEL SETUP'), findsOneWidget);
      expect(find.text('PLAYER 1 (Cyan)'), findsOneWidget);
      expect(find.text('PLAYER 2 (Magenta)'), findsOneWidget);
      expect(find.text('START DUEL ⚔️'), findsOneWidget);
      expect(find.text('Best of 3'), findsOneWidget);
      expect(find.text('Best of 5'), findsOneWidget);
    });
  });

  group('LeaderboardScreen Widget Tests', () {
    testWidgets('LeaderboardScreen renders Top 3 podium, rankings, and tab bar', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            gameStateProvider.overrideWith((ref) => GameStateNotifier(prefs)),
          ],
          child: const MaterialApp(
            home: LeaderboardScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('LEADERBOARD'), findsOneWidget);
      expect(find.text('COSMIC ARENA'), findsOneWidget);
      expect(find.text('OFFLINE DUELS'), findsOneWidget);
      expect(find.text('AstralVanguard'), findsOneWidget);
      // Sticky User Rank Card at bottom
      expect(find.textContaining('YOU #'), findsOneWidget);
      expect(find.text('SHARE'), findsOneWidget);
    });
  });
}
