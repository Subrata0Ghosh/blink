import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blink/services/game_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Local Data Storage & Onboarding Persistence Test Suite', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('GameStateNotifier synchronously initializes from preferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete', true);
      await prefs.setString('displayName', 'Commander Nova');
      await prefs.setInt('level', 5);
      await prefs.setInt('gems', 250);
      await prefs.setDouble('musicVolume', 0.7);

      final notifier = GameStateNotifier(prefs);

      // Verify that state was loaded synchronously during construction
      expect(notifier.state.onboardingComplete, isTrue);
      expect(notifier.state.displayName, 'Commander Nova');
      expect(notifier.state.level, 5);
      expect(notifier.state.gems, 250);
      expect(notifier.state.musicVolume, 0.7);
    });

    test('completeOnboarding immediately saves onboardingComplete and name without race conditions', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = GameStateNotifier(prefs);

      expect(notifier.state.onboardingComplete, isFalse);

      await notifier.completeOnboarding('Starlight Explorer');

      // Verify immediate in-memory state
      expect(notifier.state.onboardingComplete, isTrue);
      expect(notifier.state.displayName, 'Starlight Explorer');

      // Verify persisted state in SharedPreferences
      expect(prefs.getBool('onboardingComplete'), isTrue);
      expect(prefs.getString('displayName'), 'Starlight Explorer');

      // Simulate app restart by re-reading SharedPreferences with a new notifier
      final restartedNotifier = GameStateNotifier(prefs);
      expect(restartedNotifier.state.onboardingComplete, isTrue);
      expect(restartedNotifier.state.displayName, 'Starlight Explorer');
    });

    test('Game actions persist XP, gems, streak, and level correctly across restarts', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = GameStateNotifier(prefs);

      await notifier.completeOnboarding('Cosmic Scout');

      // Play challenges
      notifier.processChallengeResult(
        correct: true,
        reactionTimeMs: 450,
        currentCombo: 3,
        challengeType: 'change',
      );

      // Wait a tick for async lock queue to flush
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.gems, greaterThan(0));
      expect(notifier.state.xp, greaterThan(0));
      expect(notifier.state.totalChallenges, 1);
      expect(notifier.state.correctAnswers, 1);

      // Verify persisted in SharedPreferences
      expect(prefs.getInt('gems'), notifier.state.gems);
      expect(prefs.getInt('xp'), notifier.state.xp);
      expect(prefs.getInt('totalChallenges'), 1);

      // Simulate next launch
      final newLaunchNotifier = GameStateNotifier(prefs);
      expect(newLaunchNotifier.state.onboardingComplete, isTrue);
      expect(newLaunchNotifier.state.gems, notifier.state.gems);
      expect(newLaunchNotifier.state.xp, notifier.state.xp);
      expect(newLaunchNotifier.state.displayName, 'Cosmic Scout');
    });

    test('Riverpod ProviderScope correctly injects sharedPreferencesProvider', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete', true);
      await prefs.setString('displayName', 'AstroPilot');

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(gameStateProvider);
      expect(state.onboardingComplete, isTrue);
      expect(state.displayName, 'AstroPilot');
    });
  });
}
