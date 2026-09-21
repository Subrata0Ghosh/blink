import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blink/screens/home/home_screen.dart';
import 'package:blink/screens/world/world_screen.dart';
import 'package:blink/screens/collect/collect_screen.dart';
import 'package:blink/screens/profile/profile_screen.dart';
import 'package:blink/screens/daily/daily_shift_screen.dart';
import 'package:blink/screens/mystery/mystery_screen.dart';
import 'package:blink/widgets/navigation/game_bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('All Navigation & Game Screens Test Suite', () {
    testWidgets('HomeScreen renders with quick option shortcuts and GameBottomNav', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('DAILY\nSHIFT'), findsOneWidget);
      expect(find.text('MYSTERY'), findsOneWidget);
      expect(find.text('WORLD'), findsWidgets); // quick button & bottom nav
      expect(find.byType(GameBottomNav), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('WorldScreen mounts with InteractiveViewer, structures, and pan gesture', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WorldScreen(),
          ),
        ),
      );

      expect(find.byType(WorldScreen), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.textContaining('WORLD MAP'), findsOneWidget);

      // Pan the world map
      await tester.drag(find.byType(InteractiveViewer), const Offset(-50, -50));
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
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));
      await tester.tap(switches.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('DailyShiftScreen mounts and initializes portal sequence', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DailyShiftScreen(),
          ),
        ),
      );

      expect(find.byType(DailyShiftScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
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
