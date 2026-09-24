import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';

/// Renders an Observer Avatar inside a 3D glowing celestial frame
class ObserverAvatarBadge extends StatelessWidget {
  final String avatarId;
  final String frameId;
  final double size;
  final bool showShadow;
  final bool isCircle;

  const ObserverAvatarBadge({
    super.key,
    required this.avatarId,
    required this.frameId,
    this.size = 64,
    this.showShadow = true,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    final frameData = _getFrameData(frameId);
    final borderRadius = isCircle ? null : BorderRadius.circular(size * 0.28);
    final innerRadius = isCircle ? null : BorderRadius.circular(size * 0.24);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: frameData.colors,
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: frameData.glowColor.withValues(alpha: 0.5),
                  blurRadius: size * 0.25,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: Colors.black45,
                  offset: Offset(0, 3),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.all(size * 0.07), // Frame thickness
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131828),
          borderRadius: innerRadius,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildAvatarContent(),
      ),
    );
  }

  Widget _buildAvatarContent() {
    switch (avatarId) {
      case 'nova_happy':
        return OverflowBox(
          maxWidth: size * 1.55,
          maxHeight: size * 1.55,
          alignment: const Alignment(0.0, -0.45),
          child: Image.asset(AppAssets.novaHappy, fit: BoxFit.contain),
        );
      case 'nova_idle':
        return OverflowBox(
          maxWidth: size * 1.55,
          maxHeight: size * 1.55,
          alignment: const Alignment(0.0, -0.45),
          child: Image.asset(AppAssets.novaIdle, fit: BoxFit.contain),
        );
      case 'celestial_owl':
        return _buildIconAvatar(
          Icons.visibility_rounded,
          const Color(0xFF6C5CE7),
          const Color(0xFFA29BFE),
        );
      case 'cosmic_kitty':
        return _buildIconAvatar(
          Icons.pets_rounded,
          const Color(0xFFFF7675),
          const Color(0xFFFAB1A0),
        );
      case 'nebula_jelly':
        return _buildIconAvatar(
          Icons.bubble_chart_rounded,
          const Color(0xFF0984E3),
          const Color(0xFF74B9FF),
        );
      case 'solar_fox':
        return _buildIconAvatar(
          Icons.wb_sunny_rounded,
          const Color(0xFFE17055),
          const Color(0xFFFFEAA7),
        );
      case 'moon_sprite':
        return _buildIconAvatar(
          Icons.nightlight_round,
          const Color(0xFF00CEC9),
          const Color(0xFF81ECEC),
        );
      case 'astral_slime':
        return _buildIconAvatar(
          Icons.sentiment_very_satisfied_rounded,
          const Color(0xFF00B894),
          const Color(0xFF55EFC4),
        );
      case 'time_keeper':
        return _buildIconAvatar(
          Icons.hourglass_top_rounded,
          const Color(0xFFFD79A8),
          const Color(0xFFFFB8B8),
        );
      case 'celestial_bear':
        return _buildIconAvatar(
          Icons.cruelty_free_rounded,
          const Color(0xFFB2BEC3),
          const Color(0xFFDFE6E9),
        );
      case 'galaxy_pup':
        return _buildIconAvatar(
          Icons.favorite_rounded,
          const Color(0xFFE84393),
          const Color(0xFFFF7675),
        );
      default:
        return Image.asset(AppAssets.novaHappy, fit: BoxFit.cover);
    }
  }

  Widget _buildIconAvatar(IconData icon, Color topColor, Color bottomColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: size * 0.52,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Colors.black45,
              offset: Offset(0, 1.5),
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }

  _FrameData _getFrameData(String id) {
    switch (id) {
      case 'frame_gold':
        return _FrameData(
          colors: [const Color(0xFFFFE066), const Color(0xFFFF9500), const Color(0xFFD46B08)],
          glowColor: const Color(0xFFFFB300),
        );
      case 'frame_amethyst':
        return _FrameData(
          colors: [const Color(0xFFE056FD), const Color(0xFFBE2EDD), const Color(0xFF68009E)],
          glowColor: const Color(0xFFBE2EDD),
        );
      case 'frame_rose':
        return _FrameData(
          colors: [const Color(0xFFFF7BB9), const Color(0xFFFF3377), const Color(0xFFBA0549)],
          glowColor: const Color(0xFFFF3377),
        );
      case 'frame_emerald':
        return _FrameData(
          colors: [const Color(0xFF55EFC4), const Color(0xFF00B894), const Color(0xFF00624A)],
          glowColor: const Color(0xFF00B894),
        );
      case 'frame_prismatic':
        return _FrameData(
          colors: [
            const Color(0xFFFF7675),
            const Color(0xFFFFEAA7),
            const Color(0xFF55EFC4),
            const Color(0xFF74B9FF),
            const Color(0xFFA29BFE),
          ],
          glowColor: const Color(0xFF74B9FF),
        );
      case 'frame_cyan':
      default:
        return _FrameData(
          colors: [const Color(0xFF00F0FF), const Color(0xFF0072FF), const Color(0xFF003882)],
          glowColor: const Color(0xFF00E5FF),
        );
    }
  }
}

class _FrameData {
  final List<Color> colors;
  final Color glowColor;

  _FrameData({required this.colors, required this.glowColor});
}
