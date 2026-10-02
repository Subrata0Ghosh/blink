import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blink/models/player_state.dart';
import 'package:blink/services/game_state_service.dart';
import 'package:blink/widgets/achievements/achievements_showcase_section.dart';
import 'package:blink/widgets/animations/achievement_popup.dart';
import 'package:blink/widgets/animations/feedback_overlays.dart';
import 'package:blink/widgets/buttons/tactile_button.dart';
import 'package:blink/gameplay/rendering/tactile_object.dart';
import 'package:blink/gameplay/challenge_engine/game_objects.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Retention & Polish Widget Tests', () {
    testWidgets('AchievementPopup renders icon, title, subtitle, and gem reward', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AchievementPopup(
                  achievement: Achievements.firstPerfect,
                  onComplete: () => completed = true,
                ),
              ],
            ),
          ),
        ),
      );

      // Check content is rendered
      expect(find.text('First Perfect!'), findsOneWidget);
      expect(find.text('Scored a perfect round'), findsOneWidget);
      expect(find.text('⭐'), findsOneWidget);
      expect(find.text('+25 💎'), findsOneWidget);
      expect(find.text('🏆 ACHIEVEMENT UNLOCKED'), findsOneWidget);

      // Pump through animation (3000ms duration)
      await tester.pump(const Duration(milliseconds: 1500));
      expect(completed, isFalse);

      await tester.pump(const Duration(milliseconds: 1600));
      expect(completed, isTrue);
    });

    testWidgets('ScreenFlash renders and triggers callback', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScreenFlash(
              duration: const Duration(milliseconds: 200),
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      expect(find.byType(ScreenFlash), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      expect(completed, isTrue);
    });

    testWidgets('RedVignette renders and triggers callback', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RedVignette(
              duration: const Duration(milliseconds: 300),
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      expect(find.byType(RedVignette), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 350));
      expect(completed, isTrue);
    });

    testWidgets('CorrectEdgeGlow renders and triggers callback', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CorrectEdgeGlow(
              duration: const Duration(milliseconds: 300),
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      expect(find.byType(CorrectEdgeGlow), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 350));
      expect(completed, isTrue);
    });

    testWidgets('ComboPopup renders combo count', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComboPopup(
              combo: 4,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      expect(find.text('x4 COMBO!'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1300));
      expect(completed, isTrue);
    });

    testWidgets('NewBestBanner renders and triggers onComplete', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewBestBanner(
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      expect(find.text('NEW BEST!'), findsOneWidget);
      expect(find.text('⭐'), findsNWidgets(2));

      await tester.pump(const Duration(milliseconds: 2600));
      expect(completed, isTrue);
    });

    testWidgets('AnimatedCounter counts up to target value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 500,
              duration: Duration(milliseconds: 500),
            ),
          ),
        ),
      );

      // Initially at 0
      expect(find.text('0'), findsOneWidget);

      // Halfway
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('0'), findsNothing);

      // Completed
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('TactileButton renders with idle glow and handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TactileButton.cosmic(
                label: 'START QUEST',
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('START QUEST'), findsOneWidget);
      await tester.tap(find.text('START QUEST'));
      expect(tapped, isTrue);
    });

    test('All predefined Achievements have valid metadata', () {
      final allAchievements = [
        Achievements.firstPerfect,
        Achievements.combo3,
        Achievements.combo5,
        Achievements.combo10,
        Achievements.sharpEyes,
        Achievements.speedDemon,
        Achievements.tenGames,
        Achievements.level5,
        Achievements.level10,
      ];

      for (final a in allAchievements) {
        expect(a.id, isNotEmpty);
        expect(a.icon, isNotEmpty);
        expect(a.title, isNotEmpty);
        expect(a.gemReward, isPositive);
      }
    });

    testWidgets('AchievementsShowcaseSection renders badge grid and responds to tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'achievement_first_perfect': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AchievementsShowcaseSection(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('ACHIEVEMENTS & TROPHIES'), findsOneWidget);
      expect(find.text('First Perfect!'), findsOneWidget);
      expect(find.text('UNLOCKED'), findsAtLeastNWidgets(1));

      // Tap on a badge to trigger details sheet
      await tester.tap(find.text('First Perfect!'));
      await tester.pumpAndSettle();

      expect(find.text('Scored a perfect round'), findsOneWidget);
    });

    test('AchievementsShowcaseSection.isUnlocked correctly determines unlock status', () {
      const playerWithHighLevel = PlayerState(
        level: 10,
        totalChallenges: 15,
        bestCombo: 5,
        bestReactionTimeMs: 800,
      );

      expect(
        AchievementsShowcaseSection.isUnlocked(Achievements.level5, playerWithHighLevel, null),
        isTrue,
      );
      expect(
        AchievementsShowcaseSection.isUnlocked(Achievements.level10, playerWithHighLevel, null),
        isTrue,
      );
      expect(
        AchievementsShowcaseSection.isUnlocked(Achievements.combo5, playerWithHighLevel, null),
        isTrue,
      );
      expect(
        AchievementsShowcaseSection.isUnlocked(Achievements.combo10, playerWithHighLevel, null),
        isFalse,
      );
      expect(
        AchievementsShowcaseSection.isUnlocked(Achievements.tenGames, playerWithHighLevel, null),
        isTrue,
      );
      expect(
        AchievementsShowcaseSection.isUnlocked(Achievements.speedDemon, playerWithHighLevel, null),
        isTrue,
      );
    });

    testWidgets('GemRainShower renders and triggers onComplete', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GemRainShower(
              gemCount: 15,
              duration: const Duration(milliseconds: 500),
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      expect(find.byType(GemRainShower), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      expect(completed, isTrue);
    });

    test('PlayerState.streakMultiplier returns correct progressive tiers', () {
      const p0 = PlayerState(currentStreak: 0);
      const p1 = PlayerState(currentStreak: 1);
      const p3 = PlayerState(currentStreak: 3);
      const p7 = PlayerState(currentStreak: 7);
      const p15 = PlayerState(currentStreak: 15);

      expect(p0.streakMultiplier, equals(1.0));
      expect(p1.streakMultiplier, equals(1.2));
      expect(p3.streakMultiplier, equals(1.5));
      expect(p7.streakMultiplier, equals(2.0));
      expect(p15.streakMultiplier, equals(2.0));
    });

    testWidgets('TactileObject renders with isVictory and isWrong states', (tester) async {
      const star = GameObject(
        id: 'star_1',
        type: GameObjectType.star,
        color: Color(0xFFFFD700),
        position: Offset(0.5, 0.5),
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: TactileObject(
                  gameObject: star,
                  isVictory: true,
                  isWrong: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TactileObject), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));

      // Rebuild with isWrong: true
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: TactileObject(
                  gameObject: star,
                  isVictory: false,
                  isWrong: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TactileObject), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
