import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/player_state.dart';
import '../../services/game_state_service.dart';
import '../../services/audio_service.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/characters/observer_avatar_badge.dart';

/// Interactive Observer Customizer Modal
/// Recreates the rich, playful "Edit" avatar & frame customization sheet:
/// - Top avatar preview with live editable name field
/// - "Avatars" vs "Frames" tabbed switcher
/// - Grid of selectable avatars and 3D glowing frames with selection checkmarks
class ObserverEditModal extends ConsumerStatefulWidget {
  const ObserverEditModal({super.key});

  @override
  ConsumerState<ObserverEditModal> createState() => _ObserverEditModalState();
}

class _ObserverEditModalState extends ConsumerState<ObserverEditModal> {
  int _activeTab = 0; // 0 = Avatars, 1 = Frames
  late TextEditingController _nameController;

  final List<Map<String, String>> _avatars = [
    {'id': 'nova_happy', 'name': 'Nova Joy'},
    {'id': 'nova_idle', 'name': 'Nova Calm'},
    {'id': 'celestial_owl', 'name': 'Astral Owl'},
    {'id': 'cosmic_kitty', 'name': 'Cosmic Cat'},
    {'id': 'nebula_jelly', 'name': 'Nebula Jelly'},
    {'id': 'solar_fox', 'name': 'Solar Fox'},
    {'id': 'moon_sprite', 'name': 'Moon Sprite'},
    {'id': 'astral_slime', 'name': 'Astral Slime'},
    {'id': 'time_keeper', 'name': 'Time Keeper'},
    {'id': 'celestial_bear', 'name': 'Starlight Bear'},
    {'id': 'galaxy_pup', 'name': 'Galaxy Pup'},
  ];

  final List<Map<String, String>> _frames = [
    {'id': 'frame_cyan', 'name': 'Neon Cyan'},
    {'id': 'frame_gold', 'name': 'Solar Gold'},
    {'id': 'frame_amethyst', 'name': 'Amethyst'},
    {'id': 'frame_rose', 'name': 'Rose Quartz'},
    {'id': 'frame_emerald', 'name': 'Emerald'},
    {'id': 'frame_prismatic', 'name': 'Prismatic'},
  ];

  @override
  void initState() {
    super.initState();
    final currentName = ref.read(gameStateProvider).displayName;
    _nameController = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() {
    final text = _nameController.text.trim();
    if (text.isNotEmpty) {
      ref.read(gameStateProvider.notifier).setDisplayName(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF14192A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x66FF3D9A),
            blurRadius: 36,
            spreadRadius: -4,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  TactileButton.circle(
                    size: 42,
                    faceColorTop: const Color(0xFFFF6EB4),
                    faceColorBottom: const Color(0xFFD61876),
                    rimColor: const Color(0xFF8E0C4C),
                    onTap: () {
                      _saveName();
                      AudioService().playUiBack();
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Edit',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFFFF85C2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Top Live Preview Card with Editable Name Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B233A),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF33426A)),
                ),
                child: Row(
                  children: [
                    ObserverAvatarBadge(
                      avatarId: player.selectedAvatarId,
                      frameId: player.selectedFrameId,
                      size: 68,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1424),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
                            ),
                            child: TextField(
                              controller: _nameController,
                              maxLength: 16,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                contentPadding: EdgeInsets.only(bottom: 8),
                              ),
                              onChanged: (val) => _saveName(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_nameController.text.length}/16 chars',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                'No symbols',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: const Color(0xFF8A9BBF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tabs: Avatars vs Frames
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B233A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2E3B5E)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        label: 'Avatars',
                        index: 0,
                        isActive: _activeTab == 0,
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        label: 'Frames',
                        index: 1,
                        isActive: _activeTab == 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content Grid
            Expanded(
              child: _activeTab == 0
                  ? _buildAvatarsGrid(player, notifier)
                  : _buildFramesGrid(player, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        AudioService().playUiClick();
        HapticFeedback.lightImpact();
        setState(() => _activeTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFFFF7BB9), Color(0xFFFF2E88)],
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF2E88).withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              color: isActive ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarsGrid(PlayerState player, GameStateNotifier notifier) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: _avatars.length,
      itemBuilder: (context, index) {
        final item = _avatars[index];
        final isSelected = player.selectedAvatarId == item['id'];

        return GestureDetector(
          onTap: () {
            AudioService().playUiClick();
            HapticFeedback.selectionClick();
            notifier.setAvatar(item['id']!);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2238),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF69F0AE)
                    : const Color(0xFF2C395B),
                width: isSelected ? 2.5 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF69F0AE).withValues(alpha: 0.35),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ObserverAvatarBadge(
                      avatarId: item['id']!,
                      frameId: player.selectedFrameId,
                      size: 52,
                      showShadow: false,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['name']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),

                // Selected Checkmark Badge (matching reference screenshot 5)
                if (isSelected)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFramesGrid(PlayerState player, GameStateNotifier notifier) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: 1.15,
      ),
      itemCount: _frames.length,
      itemBuilder: (context, index) {
        final frame = _frames[index];
        final isSelected = player.selectedFrameId == frame['id'];

        return GestureDetector(
          onTap: () {
            AudioService().playGemPickup();
            HapticFeedback.selectionClick();
            notifier.setFrame(frame['id']!);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2238),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF69F0AE)
                    : const Color(0xFF2C395B),
                width: isSelected ? 2.5 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF69F0AE).withValues(alpha: 0.35),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ObserverAvatarBadge(
                      avatarId: player.selectedAvatarId,
                      frameId: frame['id']!,
                      size: 58,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      frame['name']!,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
