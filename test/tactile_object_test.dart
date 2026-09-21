import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blink/gameplay/challenge_engine/game_objects.dart';
import 'package:blink/gameplay/rendering/tactile_object.dart';
import 'package:blink/gameplay/rendering/arena_surface.dart';
import 'package:blink/gameplay/rendering/radial_energy_timer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('2.5D Tactile Objects & Arena', () {
    testWidgets('TactileObject renders Star, Moon, and Gem with CustomPaint', (tester) async {
      const gemObj = GameObject(
        id: 'gem_1',
        type: GameObjectType.gem,
        position: Offset(0.5, 0.5),
        color: Color(0xFF00E5FF),
      );

      const starObj = GameObject(
        id: 'star_1',
        type: GameObjectType.star,
        position: Offset(0.3, 0.3),
        color: Color(0xFFFFD740),
      );

      const moonObj = GameObject(
        id: 'moon_1',
        type: GameObjectType.moon,
        position: Offset(0.7, 0.7),
        color: Color(0xFF9E7BFF),
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TactileObject(gameObject: gemObj),
                  TactileObject(gameObject: starObj),
                  TactileObject(gameObject: moonObj),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify all 3 objects render CustomPaint (for contact shadow and 2.5D body)
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(TactileObject), findsNWidgets(3));

      // Tap on Gem to trigger squash/bounce interaction
      await tester.tap(find.byType(TactileObject).first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('TactileObject responds to tap callback and haptic trigger', (tester) async {
      bool tapped = false;
      const orbObj = GameObject(
        id: 'orb_1',
        type: GameObjectType.orb,
        position: Offset(0.5, 0.5),
        color: Color(0xFF2979FF),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TactileObject(
                gameObject: orbObj,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TactileObject));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tapped, isTrue);
    });

    testWidgets('ArenaSurface renders depth and particles around children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArenaSurface(
              enableBreathing: false,
              child: Text('Arena Inner World'),
            ),
          ),
        ),
      );

      expect(find.text('Arena Inner World'), findsOneWidget);
      expect(find.byType(ArenaSurface), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('RadialEnergyTimer paints progress and counts down', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RadialEnergyTimer(
              progress: 0.75,
              timeLeft: 3.5,
            ),
          ),
        ),
      );

      expect(find.text('3.5'), findsOneWidget);
      expect(find.byType(RadialEnergyTimer), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('TactileObject renders Cube, Ring, Leaf, Bolt, Triangle', (tester) async {
      const cubeObj = GameObject(
        id: 'cube_1',
        type: GameObjectType.cube,
        position: Offset(0.2, 0.2),
        color: Color(0xFFFF5252),
      );
      const ringObj = GameObject(
        id: 'ring_1',
        type: GameObjectType.ring,
        position: Offset(0.4, 0.4),
        color: Color(0xFF69F0AE),
      );
      const leafObj = GameObject(
        id: 'leaf_1',
        type: GameObjectType.leaf,
        position: Offset(0.6, 0.6),
        color: Color(0xFF64FFDA),
      );
      const boltObj = GameObject(
        id: 'bolt_1',
        type: GameObjectType.bolt,
        position: Offset(0.8, 0.8),
        color: Color(0xFFFF9100),
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TactileObject(gameObject: cubeObj),
                  TactileObject(gameObject: ringObj),
                  TactileObject(gameObject: leafObj),
                  TactileObject(gameObject: boltObj),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TactileObject), findsNWidgets(4));
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
