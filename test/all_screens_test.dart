import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blink/screens/home/home_screen.dart';
import 'package:blink/screens/world/world_screen.dart';
import 'package:blink/screens/collect/collect_screen.dart';
import 'package:blink/screens/profile/profile_screen.dart';
import 'package:blink/screens/daily/daily_shift_screen.dart';
import 'package:blink/screens/mystery/mystery_screen.dart';
import 'package:blink/widgets/navigation/game_bottom_nav.dart';
import 'package:blink/widgets/sliders/tactile_jelly_switch.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('All Navigation & Game Screens Test Suite', () {
    testWidgets('HomeScreen renders with Play button, Level Map, and Title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
      expect(find.text('LEVEL MAP'), findsOneWidget);
      expect(find.text('BLINK'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('WorldScreen mounts with CandyTopBar, Level Road, and GameBottomNav', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WorldScreen(),
          ),
        ),
      );

      expect(find.byType(WorldScreen), findsOneWidget);
      expect(find.byType(GameBottomNav), findsOneWidget);
      expect(find.text('MAP'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('CollectScreen mounts, displays rarity tabs and filters items', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CollectScreen(),
          ),
        ),
      );

      expect(find.byType(CollectScreen), findsOneWidget);
      expect(find.text('COLLECTIBLES'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('COMMON'), findsWidgets);

      // Tap 'RARE' tab
      await tester.tap(find.text('RARE'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Lunar Crescent'), findsOneWidget);
    });

    testWidgets('ProfileScreen mounts, displays player stats and toggles settings', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('OBSERVER PROFILE'), findsOneWidget);
      expect(find.text('PERFORMANCE STATS'), findsOneWidget);
      expect(find.text('SETTINGS & ACCESSIBILITY'), findsOneWidget);

      // Toggle sound switch
      final switches = find.byType(TactileJellySwitch);
      expect(switches, findsAtLeastNWidgets(2));
      await tester.tap(switches.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('DailyShiftScreen mounts and close button navigates to world', (tester) async {
      final router = GoRouter(
        initialLocation: '/daily-shift',
        routes: [
          GoRoute(path: '/world', builder: (context, state) => const Scaffold(body: Text('World Screen'))),
          GoRoute(path: '/daily-shift', builder: (context, state) => const DailyShiftScreen()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(find.byType(DailyShiftScreen), findsOneWidget);
      // Complete portal animation (1300ms)
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pump(const Duration(milliseconds: 100));

      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.text('World Screen'), findsOneWidget);
    });

    testWidgets('MysteryScreen mounts and displays cryptic mystery challenge', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MysteryScreen(),
          ),
        ),
      );

      expect(find.byType(MysteryScreen), findsOneWidget);
      expect(find.textContaining('MYSTERY SHIFT'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
