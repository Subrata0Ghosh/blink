import 'package:flutter_test/flutter_test.dart';
import 'package:blink/services/audio_service.dart';
import 'package:blink/services/game_state_service.dart';
import 'package:blink/models/player_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Persistent Music & Audio Controls Test Suite', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'soundEnabled': true,
        'musicEnabled': true,
        'sfxEnabled': true,
        'musicVolume': 0.6,
        'sfxVolume': 0.8,
      });
    });

    test('AudioService handles musicEnabled state correctly', () {
      final audio = AudioService.instance;

      audio.setMusicEnabled(true);
      expect(audio.isMusicEnabled, isTrue);

      audio.setMusicEnabled(false);
      expect(audio.isMusicEnabled, isFalse);

      // Re-enable
      audio.setMusicEnabled(true);
      expect(audio.isMusicEnabled, isTrue);
    });

    test('AudioService handles sfxEnabled state correctly', () {
      final audio = AudioService.instance;

      audio.setSfxEnabled(true);
      expect(audio.isSfxEnabled, isTrue);

      audio.setSfxEnabled(false);
      expect(audio.isSfxEnabled, isFalse);

      audio.setSfxEnabled(true);
      expect(audio.isSfxEnabled, isTrue);
    });

    test('GameStateNotifier toggles musicEnabled and synchronizes with AudioService', () {
      final notifier = GameStateNotifier();

      // Initial state is musicEnabled == true
      expect(notifier.state.musicEnabled, isTrue);
      expect(AudioService.instance.isMusicEnabled, isTrue);

      // Toggle music OFF
      notifier.toggleMusic();
      expect(notifier.state.musicEnabled, isFalse);
      expect(AudioService.instance.isMusicEnabled, isFalse);

      // Toggle music ON
      notifier.toggleMusic();
      expect(notifier.state.musicEnabled, isTrue);
      expect(AudioService.instance.isMusicEnabled, isTrue);
    });

    test('GameStateNotifier toggles sfxEnabled and synchronizes with AudioService', () {
      final notifier = GameStateNotifier();

      // Initial state is sfxEnabled == true
      expect(notifier.state.sfxEnabled, isTrue);
      expect(AudioService.instance.isSfxEnabled, isTrue);

      // Toggle SFX OFF
      notifier.toggleSfx();
      expect(notifier.state.sfxEnabled, isFalse);
      expect(AudioService.instance.isSfxEnabled, isFalse);

      // Toggle SFX ON
      notifier.toggleSfx();
      expect(notifier.state.sfxEnabled, isTrue);
      expect(AudioService.instance.isSfxEnabled, isTrue);
    });

    test('PlayerState copyWith retains musicEnabled and sfxEnabled', () {
      const state = PlayerState(
        musicEnabled: true,
        sfxEnabled: true,
        musicVolume: 0.5,
      );

      final modified = state.copyWith(musicEnabled: false, sfxEnabled: false);
      expect(modified.musicEnabled, isFalse);
      expect(modified.sfxEnabled, isFalse);
      expect(modified.musicVolume, 0.5);
    });
  });
}
