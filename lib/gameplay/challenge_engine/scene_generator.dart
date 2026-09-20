import 'dart:math';
import 'dart:ui';
import 'game_objects.dart';

/// Scene generator — creates random scenes with controlled difficulty
class SceneGenerator {
  final Random _random = Random();

  /// Generate a scene with [objectCount] objects placed in non-overlapping positions
  List<GameObject> generateScene({
    required int objectCount,
    int? seed,
  }) {
    final rng = seed != null ? Random(seed) : _random;
    final objects = <GameObject>[];
    final usedPositions = <Offset>[];
    final types = List<GameObjectType>.from(GameObjectType.values)..shuffle(rng);
    final colors = List<NamedColor>.from(GameColors.all)..shuffle(rng);

    for (int i = 0; i < objectCount; i++) {
      final type = types[i % types.length];
      final color = colors[i % colors.length];
      final position = _findNonOverlappingPosition(usedPositions, rng);
      usedPositions.add(position);

      objects.add(GameObject(
        id: 'obj_$i',
        type: type,
        position: position,
        color: color.color,
        size: 0.8 + rng.nextDouble() * 0.4,
        rotation: rng.nextDouble() * 0.5,
      ));
    }

    return objects;
  }

  /// Find a position that doesn't overlap with existing ones
  Offset _findNonOverlappingPosition(List<Offset> existing, Random rng) {
    const double minDistance = 0.18;
    const double padding = 0.08;

    for (int attempt = 0; attempt < 100; attempt++) {
      final x = padding + rng.nextDouble() * (1.0 - 2 * padding);
      final y = padding + rng.nextDouble() * (1.0 - 2 * padding);
      final candidate = Offset(x, y);

      bool tooClose = false;
      for (final pos in existing) {
        if ((candidate - pos).distance < minDistance) {
          tooClose = true;
          break;
        }
      }

      if (!tooClose) return candidate;
    }

    // Fallback
    return Offset(
      padding + rng.nextDouble() * (1.0 - 2 * padding),
      padding + rng.nextDouble() * (1.0 - 2 * padding),
    );
  }
}
