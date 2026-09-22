import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/game_state_service.dart';
import '../../services/audio_service.dart';
import '../../widgets/buttons/tactile_button.dart';
import '../../widgets/sliders/tactile_jelly_slider.dart';
import '../../widgets/sliders/tactile_jelly_switch.dart';

/// Cosmic Audio Tuning Modal — "More Audio"
/// Matches the deep audio customization features from user's reference:
/// - Voice over / Companion reactions toggle
/// - Mono audio accessibility toggle
/// - Stereo balance slider (L --- R)
/// - Bass warmth slider (Low --- High)
/// - High-pitched / Sparkle softness slider (Low --- High)
class MoreAudioModal extends ConsumerWidget {
  const MoreAudioModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.76,
      decoration: const BoxDecoration(
        color: Color(0xFF131828),
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
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Header Bar with Back Button & Cute Title
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
                        'More Audio',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFFFF85C2),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 42), // Balance layout
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Controls List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // 1. Voice over / Nova reactions
                  _buildToggleRow(
                    title: 'Voice over',
                    subtitle: 'Nova companion celestial reactions',
                    value: player.voiceEnabled,
                    onChanged: (val) => notifier.setAudioTuning(voiceEnabled: val),
                  ),

                  const SizedBox(height: 14),

                  // 2. Mono audio toggle
                  _buildToggleRow(
                    title: 'Mono audio',
                    subtitle: 'Combine stereo channels into single channel',
                    value: player.monoAudio,
                    onChanged: (val) => notifier.setAudioTuning(monoAudio: val),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFF263050), height: 1),
                  const SizedBox(height: 20),

                  // 3. Balance Slider
                  _buildSliderSection(
                    title: 'Balance',
                    leftLabel: 'L',
                    rightLabel: 'R',
                    value: (player.audioBalance + 1.0) / 2.0, // map -1..1 to 0..1
                    onChanged: (val) {
                      final balance = (val * 2.0) - 1.0;
                      notifier.setAudioTuning(audioBalance: balance);
                    },
                  ),

                  const SizedBox(height: 24),

                  // 4. Bass Warmth Slider
                  _buildSliderSection(
                    title: 'Bass',
                    leftLabel: 'Low',
                    rightLabel: 'High',
                    value: player.bassWarmth,
                    onChanged: (val) => notifier.setAudioTuning(bassWarmth: val),
                  ),

                  const SizedBox(height: 24),

                  // 5. High-pitched sounds Slider
                  _buildSliderSection(
                    title: 'High-pitched sounds',
                    leftLabel: 'Low',
                    rightLabel: 'High',
                    value: player.sparkleSoftness,
                    onChanged: (val) => notifier.setAudioTuning(sparkleSoftness: val),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2238),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2F3B60)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          TactileJellySwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection({
    required String title,
    required String leftLabel,
    required String rightLabel,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFE2E8F8),
          ),
        ),
        const SizedBox(height: 8),
        TactileJellySlider(
          value: value,
          onChanged: onChanged,
          activeColorStart: const Color(0xFFFF7BB9),
          activeColorEnd: const Color(0xFF00B0FF),
          thumbColor: const Color(0xFF00A2FF),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leftLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8B9BBF),
                ),
              ),
              Text(
                rightLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8B9BBF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
