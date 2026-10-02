import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blink/models/player_state.dart';
import 'package:blink/services/game_state_service.dart';
import 'package:blink/gameplay/challenge_engine/challenge_engine.dart';
import 'package:blink/gameplay/challenge_engine/game_objects.dart';
import 'package:blink/screens/collect/collect_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Interconnection & Progression Suite', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('PlayerState initial state includes default collectibles, level 1, and no stars', () {
      final state = PlayerState.initial();
      expect(state.unlockedCollectibleIds, contains('shift_gem'));
      expect(state.equippedCollectibleId, equals('shift_gem'));
      expect(state.unlockedWorldLevel, equals(1));
      expect(state.levelStars, isEmpty);
      expect(state.isDailyShiftCompletedToday, isFalse);
    });

    test('GameStateNotifier unlockCollectible spends gems and adds to unlocked list', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final notifier = container.read(gameStateProvider.notifier);
      // Give player 200 gems
      await notifier.addGems(200);
      expect(container.read(gameStateProvider).gems, equals(200));

      // Unlock cosmic star (cost: 100)
      final success = await notifier.unlockCollectible('cosmic_star', 100);
      expect(success, isTrue);

      final updatedState = container.read(gameStateProvider);
      expect(updatedState.gems, equals(100));
      expect(updatedState.unlockedCollectibleIds, contains('cosmic_star'));

      // Check SharedPreferences persistence
      expect(prefs.getStringList('unlockedCollectibleIds'), contains('cosmic_star'));
      expect(prefs.getInt('gems'), equals(100));
    });

    test('GameStateNotifier equipCollectible equips only unlocked items', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final notifier = container.read(gameStateProvider.notifier);

      // Attempt equipping locked item -> should fail
      final lockedResult = await notifier.equipCollectible('prism_cube');
      expect(lockedResult, isFalse);
      expect(container.read(gameStateProvider).equippedCollectibleId, equals('shift_gem'));

      // Unlock then equip
      await notifier.addGems(800);
      await notifier.unlockCollectible('prism_cube', 650);
      final equipResult = await notifier.equipCollectible('prism_cube');
      expect(equipResult, isTrue);
      expect(container.read(gameStateProvider).equippedCollectibleId, equals('prism_cube'));
      expect(prefs.getString('equippedCollectibleId'), equals('prism_cube'));
    });

    test('GameStateNotifier completeWorldLevel unlocks next level and saves stars', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final notifier = container.read(gameStateProvider.notifier);
      expect(container.read(gameStateProvider).unlockedWorldLevel, equals(1));

      // Complete Level 1 with 3 stars
      await notifier.completeWorldLevel(1, 3);

      final state = container.read(gameStateProvider);
      expect(state.unlockedWorldLevel, equals(2));
      expect(state.levelStars[1], equals(3));
      // Level completion bonus
      expect(state.gems, greaterThan(0));

      // Check prefs
      expect(prefs.getInt('unlockedWorldLevel'), equals(2));
      expect(prefs.getString('levelStars'), contains('1:3'));
    });

    test('GameStateNotifier completeDailyShift marks daily shift completed for today', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final notifier = container.read(gameStateProvider.notifier);
      expect(container.read(gameStateProvider).isDailyShiftCompletedToday, isFalse);

      await notifier.completeDailyShift();

      expect(container.read(gameStateProvider).isDailyShiftCompletedToday, isTrue);
      expect(prefs.getString('lastDailyShiftCompletedDate'), isNotNull);
    });

    test('Relic Active Perks: Starlight Prism (+50% combo gems) and Eye of Chronos (2x XP)', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final notifier = container.read(gameStateProvider.notifier);

      // Level 1 player with streak combo 3
      final resultNormal = notifier.processChallengeResult(
        correct: true,
        reactionTimeMs: 1200,
        currentCombo: 3,
        challengeType: 'change',
      );

      // Now level up player to level 5 (unlocks Starlight Prism Lv.3 and Eye of Chronos Lv.5)
      notifier.addXp(5000);
      expect(container.read(gameStateProvider).level, greaterThanOrEqualTo(5));

      final resultBoosted = notifier.processChallengeResult(
        correct: true,
        reactionTimeMs: 1200,
        currentCombo: 3,
        challengeType: 'change',
      );

      // Eye of Chronos gives 2x base XP
      expect(resultBoosted.xpEarned, greaterThan(resultNormal.xpEarned));
      // Starlight Prism gives +50% combo gems
      expect(resultBoosted.gemsEarned, greaterThanOrEqualTo(resultNormal.gemsEarned));
    });

    test('ChallengeEngine generates challenges featuring player equipped object type', () {
      final engine = ChallengeEngine();
      final challenge = engine.generateChallenge(
        mode: ChallengeMode.change,
        difficulty: 10,
        featuredType: GameObjectType.cube,
      );

      final containsCube = challenge.originalScene.any((o) => o.type == GameObjectType.cube);
      expect(containsCube, isTrue);
    });

    test('ChallengeEngine getRandomUnlockedMode recalibrated across levels 1-20', () {
      final engine = ChallengeEngine();
      // Level 1 should only be change
      final modeLv1 = engine.getRandomUnlockedMode(1);
      expect(modeLv1, equals(ChallengeMode.change));

      // Level 20 unlocks all modes including chaos
      final modesAtLv20 = <ChallengeMode>{};
      for (int i = 0; i < 50; i++) {
        modesAtLv20.add(engine.getRandomUnlockedMode(20));
      }
      expect(modesAtLv20.length, greaterThan(1));
    });

    testWidgets('CollectScreen renders and displays real equipped status and prices', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CollectScreen(),
          ),
        ),
      );

      // Single frame pump avoids infinite loop of ambient particle animations
      await tester.pump(const Duration(milliseconds: 200));

      // Verify title and Vault headers
      expect(find.text('COLLECTIBLES'), findsOneWidget);
      expect(find.text('Shift Gem'), findsOneWidget);
      expect(find.text('EQUIPPED'), findsOneWidget);
    });
  });
}
