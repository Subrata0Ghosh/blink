import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blink/models/solar_realm_model.dart';
import 'package:blink/widgets/world/solar_orrery_view.dart';
import 'package:blink/widgets/world/story_chronicle_banner.dart';
import 'package:blink/widgets/world/island_architectures.dart';
import 'package:blink/widgets/world/biome_bridge_painter.dart';
import 'package:blink/widgets/world/floating_island_painter.dart';
import 'package:blink/screens/world/world_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Solar Planetary Realms & Story Models', () {
    test('SolarRealm defines 5 unique planetary realms with aliens and chapters', () {
      expect(SolarRealm.realms.length, 5);

      final solaria = SolarRealm.realms[0];
      expect(solaria.id, 'solaria_prime');
      expect(solaria.alien.name, 'Zobi');
      expect(solaria.biome, IslandBiome.verdantAstral);
      expect(solaria.startLevel, 1);
      expect(solaria.endLevel, 4);

      final starforge = SolarRealm.realms[4];
      expect(starforge.id, 'starforge_omega');
      expect(starforge.alien.name, 'Volt');
      expect(starforge.biome, IslandBiome.cyberStarforge);
      expect(starforge.startLevel, 17);
      expect(starforge.endLevel, 20);
    });

    test('SolarRealm getRealmForLevel resolves correct realm for all levels 1-20', () {
      expect(SolarRealm.getRealmForLevel(1).name, 'Solaria Prime');
      expect(SolarRealm.getRealmForLevel(4).name, 'Solaria Prime');
      expect(SolarRealm.getRealmForLevel(5).name, 'Amethea IV');
      expect(SolarRealm.getRealmForLevel(8).name, 'Amethea IV');
      expect(SolarRealm.getRealmForLevel(9).name, 'Pyrocron Core');
      expect(SolarRealm.getRealmForLevel(12).name, 'Pyrocron Core');
      expect(SolarRealm.getRealmForLevel(13).name, 'Aetheria Clouds');
      expect(SolarRealm.getRealmForLevel(16).name, 'Aetheria Clouds');
      expect(SolarRealm.getRealmForLevel(17).name, 'Starforge Omega');
      expect(SolarRealm.getRealmForLevel(20).name, 'Starforge Omega');
    });

    test('SolarRealm getIslandRole assigns Citadel Castle to milestone level', () {
      expect(SolarRealm.getIslandRole(1), IslandRole.realmGateway);
      expect(SolarRealm.getIslandRole(2), IslandRole.alienSanctuary);
      expect(SolarRealm.getIslandRole(3), IslandRole.crystalSpire);
      expect(SolarRealm.getIslandRole(4), IslandRole.citadelCastle);
    });
  });

  group('Solar Orrery & Island Architecture Widgets', () {
    testWidgets('CitadelCastleStructure renders stone walls, turrets, and flag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CitadelCastleStructure(
                biome: IslandBiome.verdantAstral,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CitadelCastleStructure), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('AlienCompanionWidget renders companion and triggers tap dialogue', (tester) async {
      final alien = SolarRealm.realms[0].alien;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AlienCompanionWidget(alien: alien, bubbleOnLeft: true),
            ),
          ),
        ),
      );

      expect(find.byType(AlienCompanionWidget), findsOneWidget);
      await tester.tap(find.byType(AlienCompanionWidget));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(alien.greeting), findsOneWidget);
      // Wait for 8-second auto-dismiss and pop animation to complete
      await tester.pump(const Duration(seconds: 9));
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('CrystalSpireStructure and RealmGatewayStructure mount cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CrystalSpireStructure(biome: IslandBiome.cosmicCrystal),
                RealmGatewayStructure(biome: IslandBiome.solarMagma),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CrystalSpireStructure), findsOneWidget);
      expect(find.byType(RealmGatewayStructure), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('SolarOrreryView renders Solarium Sun and 5 planetary globes', (tester) async {
      SolarRealm? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SolarOrreryView(
              activeLevel: 1,
              levelStars: const {1: 3},
              onSelectRealm: (r) => selected = r,
              onZoomInToCurrent: () {},
            ),
          ),
        ),
      );

      expect(find.byType(SolarOrreryView), findsOneWidget);
      expect(find.text('SOLAR ORRERY SYSTEM'), findsOneWidget);
      expect(find.text('ENTER PLANET'), findsOneWidget);

      await tester.tap(find.text('ENTER PLANET'));
      await tester.pump();
      expect(selected, isNotNull);
      expect(selected?.id, 'solaria_prime');
    });

    testWidgets('StoryChronicleBanner expands Nova transmission and toggles Orrery', (tester) async {
      bool orreryToggled = false;
      final realm = SolarRealm.realms[0];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryChronicleBanner(
              currentRealm: realm,
              activeLevel: 1,
              onToggleOrrery: () => orreryToggled = true,
              isOrreryOpen: false,
            ),
          ),
        ),
      );

      expect(find.byType(StoryChronicleBanner), findsOneWidget);
      expect(find.text(realm.chapterTitle.toUpperCase()), findsOneWidget);
      expect(find.text(realm.missionObjective), findsOneWidget);
      expect(find.text('ORRERY'), findsOneWidget);

      // Tap ORRERY toggle
      await tester.tap(find.text('ORRERY'));
      await tester.pump();
      expect(orreryToggled, isTrue);

      // Tap Nova avatar to expand transmission log
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      expect(find.text('Nova: "${realm.storyTransmission}"'), findsOneWidget);
    });

    testWidgets('WorldScreen toggles between Archipelago and Solar Orrery View', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WorldScreen(),
          ),
        ),
      );

      expect(find.byType(WorldScreen), findsOneWidget);
      expect(find.byType(FloatingIslandWidget), findsWidgets);
      expect(find.text('ORRERY'), findsOneWidget);

      // Tap ORRERY toggle button in the banner
      await tester.tap(find.text('ORRERY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Now Solar Orrery View is displayed
      expect(find.byType(SolarOrreryView), findsOneWidget);
      expect(find.text('SURFACE'), findsOneWidget);

      // Tap SURFACE to zoom back into planet archipelago
      await tester.tap(find.text('SURFACE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(FloatingIslandWidget), findsWidgets);
    });

    testWidgets('BiomeBridgePainter mounts and paints all 5 biome bridge types without throwing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(400, 3000),
              painter: BiomeBridgePainter(
                waypoints: [
                  const Offset(200, 2900),
                  const Offset(100, 2800),
                  const Offset(300, 2800),
                  const Offset(200, 2700),
                  const Offset(200, 2300),
                ],
                activeLevel: 5,
                pulseValue: 0.5,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('StoryChronicleBanner renders on compact 320px screen without any overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryChronicleBanner(
              currentRealm: SolarRealm.realms[0],
              activeLevel: 1,
              onToggleOrrery: () {},
              isOrreryOpen: false,
            ),
          ),
        ),
      );

      expect(find.byType(StoryChronicleBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
