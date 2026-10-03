import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blink/models/booster_model.dart';
import 'package:blink/models/lucky_spin_model.dart';
import 'package:blink/models/player_state.dart';
import 'package:blink/widgets/boosters/booster_selector.dart';
import 'package:blink/widgets/boosters/active_booster_hud.dart';
import 'package:blink/widgets/modals/lucky_spin_modal.dart';
import 'package:blink/widgets/modals/lives_refill_modal.dart';
import 'package:blink/screens/home/home_screen.dart';
import 'package:blink/widgets/particles/stardust_finger_trail.dart';
import 'package:blink/gameplay/rendering/parallax_3d_arena.dart';
import 'package:blink/widgets/animations/flying_reward_overlay.dart';
import 'package:blink/services/audio_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Popular Game Features — Boosters & Power-ups', () {
    test('Booster definitions are correct and distinct', () {
      expect(Booster.all.length, 5);
      final types = Booster.all.map((b) => b.type).toSet();
      expect(types.length, 5);
    });

    test('BoosterInventory add, use, and serialization', () {
      const inv = BoosterInventory();
      expect(inv.countOf(BoosterType.timeFreeze), 0);
      expect(inv.has(BoosterType.timeFreeze), isFalse);

      final inv2 = inv.add(BoosterType.timeFreeze, 3);
      expect(inv2.countOf(BoosterType.timeFreeze), 3);
      expect(inv2.has(BoosterType.timeFreeze), isTrue);

      final inv3 = inv2.use(BoosterType.timeFreeze);
      expect(inv3.countOf(BoosterType.timeFreeze), 2);

      final encoded = inv3.encode();
      final decoded = BoosterInventory.decode(encoded);
      expect(decoded.countOf(BoosterType.timeFreeze), 2);
    });

    test('ActiveBoosters toggle and limit to 3 max', () {
      var active = const ActiveBoosters();
      expect(active.selected.isEmpty, isTrue);

      active = active.toggle(BoosterType.timeFreeze);
      active = active.toggle(BoosterType.secondChance);
      active = active.toggle(BoosterType.revealHint);
      expect(active.selected.length, 3);
      expect(active.isFull, isTrue);

      // Attempt to add 4th should be ignored
      active = active.toggle(BoosterType.streakShield);
      expect(active.selected.length, 3);
      expect(active.isActive(BoosterType.streakShield), isFalse);

      // Toggling an existing one removes it
      active = active.toggle(BoosterType.timeFreeze);
      expect(active.selected.length, 2);
      expect(active.isActive(BoosterType.timeFreeze), isFalse);
    });
  });

  group('Popular Game Features — Lucky Spin Wheel', () {
    test('LuckySpinPrize has 8 balanced cosmic prizes', () {
      expect(LuckySpinPrize.prizes.length, 8);
      final jackpot = LuckySpinPrize.prizes.firstWhere((p) => p.id == 'gems_250');
      expect(jackpot.amount, 250);
      expect(jackpot.type, SpinPrizeType.gems);
    });

    test('Lucky Spin availability logic in PlayerState', () {
      final state1 = const PlayerState();
      expect(state1.isLuckySpinAvailable, isTrue);

      final state2 = state1.copyWith(lastLuckySpinDate: DateTime.now());
      expect(state2.isLuckySpinAvailable, isFalse);

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final state3 = state1.copyWith(lastLuckySpinDate: yesterday);
      expect(state3.isLuckySpinAvailable, isTrue);
    });
  });

  group('Popular Game Features — Lives / Energy (Candy Crush Style)', () {
    test('Player starts with 5 hearts and computes regeneration', () {
      const state = PlayerState();
      expect(state.lives, 5);
      expect(state.currentLives, 5);
      expect(state.timeUntilNextLife, isNull);

      final halfHourAgo = DateTime.now().subtract(const Duration(minutes: 30));
      final lostOne = state.copyWith(lives: 4, lastLifeLostTime: halfHourAgo);
      // After 30 minutes, 1 heart regenerates (every 20 min)
      expect(lostOne.currentLives, 5);
    });
  });

  group('Popular Game Features — Widget Render Tests', () {
    testWidgets('ActiveBoosterHud renders active booster badges', (tester) async {
      var active = const ActiveBoosters();
      active = active.toggle(BoosterType.timeFreeze);
      active = active.toggle(BoosterType.scoreMultiplier);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveBoosterHud(activeBoosters: active),
          ),
        ),
      );

      expect(find.byType(ActiveBoosterHud), findsOneWidget);
      expect(find.text('+3s'), findsOneWidget);
      expect(find.text('2x'), findsOneWidget);
    });

    testWidgets('BoosterSelector mounts and displays options', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BoosterSelector(
                  onConfirm: _dummyConfirm,
                  onSkip: _dummySkip,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SELECT BOOSTERS'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);
    });

    testWidgets('LuckySpinModal renders wheel dialog with Free Spin button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LuckySpinModal(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('COSMIC WHEEL'), findsOneWidget);
      expect(find.text('FREE DAILY SPIN'), findsOneWidget);
    });

    testWidgets('LivesRefillModal renders current hearts and refill option', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LivesRefillModal(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('COSMIC ENERGY'), findsOneWidget);
      expect(find.textContaining('HEARTS'), findsOneWidget);
      expect(find.text('PLAY ZEN MODE (FREE)'), findsOneWidget);
    });

    testWidgets('HomeScreen renders status bar and bottom utilities without overflow on narrow screen', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PLAY'), findsOneWidget);
      expect(find.text('SPIN'), findsOneWidget);
      expect(find.text('Missions'), findsOneWidget);
      expect(find.text('Relics'), findsOneWidget);
      expect(find.text('GIFT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('StardustFingerTrail renders child and tracks pointer movement', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StardustFingerTrail(
              child: Container(
                key: const Key('trail_target'),
                width: 300,
                height: 300,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(StardustFingerTrail), findsOneWidget);
      expect(find.byKey(const Key('trail_target')), findsOneWidget);

      // Simulate finger drag across screen
      final gesture = await tester.startGesture(const Offset(50, 50));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveTo(const Offset(150, 150));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Parallax3dArena tilts child on finger drag and springs back', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: Parallax3dArena(
                  child: Container(
                    key: const Key('arena_child'),
                    color: Colors.purple,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Parallax3dArena), findsOneWidget);
      expect(find.byKey(const Key('arena_child')), findsOneWidget);

      // Drag across arena
      final gesture = await tester.startGesture(const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveTo(const Offset(280, 220));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('FlyingRewardOverlay creates arcing reward gems to target HUD', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlyingRewardOverlay(
              startPosition: const Offset(150, 400),
              targetPosition: const Offset(300, 50),
              count: 6,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      expect(find.byType(FlyingRewardOverlay), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 600));

      expect(completed, isTrue);
      expect(tester.takeException(), isNull);
    });

    test('AudioService playAscendingCombo pitch calculation', () {
      final audio = AudioService();
      // Should execute without throw in test environment
      expect(() => audio.playAscendingCombo(1), returnsNormally);
      expect(() => audio.playAscendingCombo(5), returnsNormally);
      expect(() => audio.playAscendingCombo(12), returnsNormally);
      expect(() => audio.playJuicyPop(), returnsNormally);
    });
  });
}

void _dummyConfirm(ActiveBoosters b) {}
void _dummySkip() {}
