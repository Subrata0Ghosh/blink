import 'package:flutter_test/flutter_test.dart';
import 'package:blink/gameplay/challenge_engine/challenge_engine.dart';

void main() {
  group('ChallengeEngine', () {
    late ChallengeEngine engine;

    setUp(() {
      engine = ChallengeEngine();
    });

    test('generates a valid CHANGE challenge', () {
      final challenge = engine.generateChallenge(
        mode: ChallengeMode.change,
        difficulty: 5,
      );

      expect(challenge.mode, ChallengeMode.change);
      expect(challenge.originalScene.isNotEmpty, true);
      expect(challenge.modifiedScene, isNotNull);
      expect(challenge.answers.length, 4);
      expect(challenge.correctAnswerIndex, greaterThanOrEqualTo(0));
      expect(challenge.correctAnswerIndex, lessThan(challenge.answers.length));
    });

    test('generates a valid REMEMBER challenge', () {
      final challenge = engine.generateChallenge(
        mode: ChallengeMode.remember,
        difficulty: 10,
      );

      expect(challenge.mode, ChallengeMode.remember);
      expect(challenge.originalScene.isNotEmpty, true);
      expect(challenge.answers.length, greaterThanOrEqualTo(2));
    });

    test('generates a valid SWAP challenge', () {
      final challenge = engine.generateChallenge(
        mode: ChallengeMode.swap,
        difficulty: 20,
      );

      expect(challenge.mode, ChallengeMode.swap);
      expect(challenge.originalScene.length, greaterThanOrEqualTo(4));
      expect(challenge.modifiedScene, isNotNull);
    });

    test('correct answer is always in answers list', () {
      for (final mode in ChallengeMode.values) {
        final challenge = engine.generateChallenge(mode: mode, difficulty: 10);
        expect(
          challenge.answers.contains(challenge.correctAnswer),
          true,
          reason: 'Mode ${mode.name} did not have correct answer in answers list',
        );
      }
    });

    test('difficulty scales object count', () {
      final easy = engine.generateChallenge(mode: ChallengeMode.change, difficulty: 3);
      final hard = engine.generateChallenge(mode: ChallengeMode.change, difficulty: 60);

      expect(hard.originalScene.length, greaterThanOrEqualTo(easy.originalScene.length));
    });

    test('mode unlocking respects level', () {
      // Level 1 should only return change mode
      for (int i = 0; i < 20; i++) {
        final mode = engine.getRandomUnlockedMode(1);
        expect(mode, ChallengeMode.change);
      }
    });
  });
}
