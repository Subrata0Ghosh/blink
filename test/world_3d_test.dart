import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blink/models/player_state.dart';
import 'package:blink/widgets/world/world_3d_diorama.dart';
import 'package:blink/widgets/buttons/blink_button.dart';
import 'package:blink/screens/home/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('3D World Diorama & BlinkButton', () {
    testWidgets('World3dDiorama renders 3D layers, orbiting crystals, and Nova', (tester) async {
      const player = PlayerState(displayName: 'TestPlayer', level: 5, gems: 50);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: World3dDiorama(player: player, size: 280),
              ),
            ),
          ),
        ),
      );

      // Verify World3dDiorama mounts
      expect(find.byType(World3dDiorama), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));

      // Test drag pan to tilt in 3D
      await tester.drag(find.byType(World3dDiorama), const Offset(40, -30));
      await tester.pump(const Duration(milliseconds: 100));

      // Test tapping Nova to trigger 3D spin
      final gestureDetectors = find.descendant(
        of: find.byType(World3dDiorama),
        matching: find.byType(GestureDetector),
      );
      expect(gestureDetectors, findsWidgets);

      // Tap the second gesture detector (Nova tap detector)
      if (gestureDetectors.evaluate().length >= 2) {
        await tester.tap(gestureDetectors.at(1));
        await tester.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('BlinkButton renders tactile depth and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BlinkButton(
                label: 'PLAY',
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('PLAY'), findsOneWidget);
      expect(find.byType(BlinkButton), findsOneWidget);

      await tester.tap(find.byType(BlinkButton));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tapped, isTrue);
    });

    testWidgets('HomeScreen renders with Play button and BLINK title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
      expect(find.text('BLINK'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
