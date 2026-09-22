import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blink/widgets/buttons/tactile_button.dart';
import 'package:blink/widgets/buttons/tactile_option_button.dart';
import 'package:blink/widgets/navigation/candy_top_bar.dart';
import 'package:blink/widgets/navigation/game_bottom_nav.dart';
import 'package:blink/widgets/world/floating_island_painter.dart';
import 'package:blink/widgets/characters/tactile_nova_companion.dart';
import 'package:blink/screens/world/world_screen.dart';
import 'package:blink/screens/splash/splash_screen.dart';
import 'package:blink/screens/onboarding/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('3D Tactile Buttons & Navigation Suite', () {
    testWidgets('TactileButton.close renders circular 3D close button and handles tap', (tester) async {
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TactileButton.close(
                size: 44,
                onTap: () => closed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TactileButton), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byType(TactileButton));
      await tester.pump(const Duration(milliseconds: 100));
      expect(closed, isTrue);
    });

    testWidgets('TactileButton.dark and cosmic render with 3D bevel and label', (tester) async {
      bool tappedDark = false;
      bool tappedCosmic = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TactileButton.dark(
                  label: 'RETURN HOME',
                  onTap: () => tappedDark = true,
                ),
                TactileButton.cosmic(
                  label: 'NEXT CHALLENGE',
                  onTap: () => tappedCosmic = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('RETURN HOME'), findsOneWidget);
      expect(find.text('NEXT CHALLENGE'), findsOneWidget);

      await tester.tap(find.text('RETURN HOME'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tappedDark, isTrue);

      await tester.tap(find.text('NEXT CHALLENGE'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tappedCosmic, isTrue);
    });

    testWidgets('CandyTopBar renders 3D pills, avatar medallion, and settings button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CandyTopBar(),
            ),
          ),
        ),
      );

      expect(find.byType(CandyTopBar), findsOneWidget);
      expect(find.byIcon(Icons.mail_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.diamond_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      expect(find.text('Full'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('GameBottomNav renders 3D tactile dock tabs with MAP active', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GameBottomNav(currentIndex: 0),
          ),
        ),
      );

      expect(find.byType(GameBottomNav), findsOneWidget);
      expect(find.text('MAP'), findsOneWidget);
      expect(find.text('EVENTS'), findsOneWidget);
      expect(find.text('SHOP'), findsOneWidget);
      expect(find.text('PROFILE'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('FloatingIslandWidget renders with biome and child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingIslandWidget(
                biome: IslandBiome.verdantAstral,
                child: Text('Island 1'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingIslandWidget), findsOneWidget);
      expect(find.text('Island 1'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('WorldScreen mounts with 3D floating island nodes', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WorldScreen(),
          ),
        ),
      );

      expect(find.byType(WorldScreen), findsOneWidget);
      expect(find.byType(FloatingIslandWidget), findsWidgets);
      expect(find.byType(CandyTopBar), findsOneWidget);
      expect(find.byType(GameBottomNav), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('TactileOptionButton renders 4 pill options (A, B, C, D) with badges, text, and tap', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TactileOptionButton(
                  index: 0,
                  text: 'Ring',
                  onTap: () => tappedIndex = 0,
                ),
                TactileOptionButton(
                  index: 1,
                  text: 'Cube',
                  onTap: () => tappedIndex = 1,
                ),
                TactileOptionButton(
                  index: 2,
                  text: 'Star',
                  onTap: () => tappedIndex = 2,
                ),
                TactileOptionButton(
                  index: 3,
                  text: 'Triangle',
                  onTap: () => tappedIndex = 3,
                ),
              ],
            ),
          ),
        ),
      );

      // Verify badges A, B, C, D and option labels exist
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Ring'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('Cube'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('Star'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(find.text('Triangle'), findsOneWidget);

      // Tap Option B
      await tester.tap(find.text('Cube'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tappedIndex, equals(1));
    });

    testWidgets('TactileOptionButton shows result feedback badges on correct/incorrect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TactileOptionButton(
                  index: 0,
                  text: 'Correct Option',
                  showResult: true,
                  isCorrect: true,
                  isSelected: true,
                  onTap: () {},
                ),
                TactileOptionButton(
                  index: 1,
                  text: 'Wrong Option',
                  showResult: true,
                  isCorrect: false,
                  isSelected: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('TactileNovaCompanion renders with holographic emitter and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TactileNovaCompanion(
                size: 90,
                showHologramRing: true,
                enableDialogue: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TactileNovaCompanion), findsOneWidget);
      expect(find.byType(Image), findsWidgets);

      await tester.tap(find.byType(TactileNovaCompanion));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tapped, isTrue);
    });

    testWidgets('SplashScreen renders with 3D crystal dome and embossed BLINK title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(onComplete: () {}),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('BLINK'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('OnboardingScreen renders with 3D pedestals, 3D pill dots, and NEXT button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(onComplete: () {}),
          ),
        ),
      );

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
