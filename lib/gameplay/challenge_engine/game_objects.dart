import 'dart:ui';

/// Represents a visual game object on the scene
class GameObject {
  final String id;
  final GameObjectType type;
  final Offset position; // 0.0-1.0 normalized
  final Color color;
  final double size; // relative scale 0.5-1.5
  final double rotation; // radians

  const GameObject({
    required this.id,
    required this.type,
    required this.position,
    required this.color,
    this.size = 1.0,
    this.rotation = 0.0,
  });

  GameObject copyWith({
    String? id,
    GameObjectType? type,
    Offset? position,
    Color? color,
    double? size,
    double? rotation,
  }) {
    return GameObject(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      color: color ?? this.color,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
    );
  }

  @override
  String toString() => '${type.label} (${color.toARGB32().toRadixString(16)})';
}

enum GameObjectType {
  orb('Orb', '⬤'),
  crystal('Crystal', '◆'),
  moon('Moon', '☽'),
  cube('Cube', '■'),
  leaf('Leaf', '🍃'),
  star('Star', '★'),
  triangle('Triangle', '▲'),
  ring('Ring', '◯'),
  bolt('Bolt', '⚡'),
  gem('Gem', '💎');

  final String label;
  final String emoji;
  const GameObjectType(this.label, this.emoji);
}

/// Named colors for the game — easily identifiable
class GameColors {
  static const List<NamedColor> all = [
    NamedColor('Blue', Color(0xFF2979FF)),
    NamedColor('Red', Color(0xFFFF5252)),
    NamedColor('Green', Color(0xFF69F0AE)),
    NamedColor('Purple', Color(0xFFAA00FF)),
    NamedColor('Cyan', Color(0xFF00E5FF)),
    NamedColor('Gold', Color(0xFFFFD740)),
    NamedColor('Orange', Color(0xFFFF9100)),
    NamedColor('Pink', Color(0xFFFF6EE6)),
    NamedColor('Teal', Color(0xFF64FFDA)),
    NamedColor('White', Color(0xFFEEEEEE)),
  ];
}

class NamedColor {
  final String name;
  final Color color;
  const NamedColor(this.name, this.color);
}
