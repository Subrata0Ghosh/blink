import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Audio service for BLINK
/// Handles synthesized cosmic sound effects and looped ambient space music
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  bool _initialized = false;
  bool _soundEnabled = true;
  double _musicVolume = 0.45; // Gentle, toe-tapping casual music level
  double _sfxVolume = 0.82;   // Crisp, juicy, non-piercing SFX level

  AudioPlayer? _musicPlayer;
  final List<AudioPlayer> _sfxPlayers = [];
  int _sfxIndex = 0;
  static const int _poolSize = 4;

  static AudioService get instance => _instance;
  bool get isSoundEnabled => _soundEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _musicPlayer = AudioPlayer(playerId: 'blink_music');
      await _musicPlayer?.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer?.setVolume(_soundEnabled ? _musicVolume : 0.0);

      for (int i = 0; i < _poolSize; i++) {
        final p = AudioPlayer(playerId: 'blink_sfx_$i');
        await p.setReleaseMode(ReleaseMode.stop);
        _sfxPlayers.add(p);
      }
    } catch (_) {
      // Audio fallback in non-supported / headless environments
    }
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    try {
      if (!enabled) {
        _musicPlayer?.pause();
      } else {
        _musicPlayer?.setVolume(_musicVolume);
        _musicPlayer?.resume();
      }
    } catch (_) {}
  }

  void setMusicVolume(double vol) {
    _musicVolume = vol.clamp(0.0, 1.0);
    try {
      if (_soundEnabled) {
        _musicPlayer?.setVolume(_musicVolume);
      }
    } catch (_) {}
  }

  void setSfxVolume(double vol) {
    _sfxVolume = vol.clamp(0.0, 1.0);
  }

  Future<void> startAmbientMusic() async {
    if (!_soundEnabled) return;
    try {
      if (_musicPlayer == null) await init();
      // If already playing smoothly, don't interrupt or restart
      if (_musicPlayer?.state == PlayerState.playing) return;
      await _musicPlayer?.setVolume(_musicVolume);
      await _musicPlayer?.play(AssetSource('audio/ambient_music.wav'));
    } catch (_) {}
  }

  Future<void> pauseMusic() async {
    try {
      await _musicPlayer?.pause();
    } catch (_) {}
  }

  Future<void> resumeMusic() async {
    if (!_soundEnabled) return;
    try {
      await _musicPlayer?.resume();
    } catch (_) {}
  }

  Future<void> playUiClick() async => _playSfx('ui_click');
  Future<void> playUiConfirm() async => _playSfx('ui_confirm');
  Future<void> playUiBack() async => _playSfx('ui_back');
  Future<void> playCountdown() async => _playSfx('countdown');
  Future<void> playCorrect() async => _playSfx('correct');
  Future<void> playWrong() async => _playSfx('wrong');
  Future<void> playPerfect() async => _playSfx('perfect');
  Future<void> playCombo() async => _playSfx('combo');
  Future<void> playGemPickup() async => _playSfx('gem_pickup');
  Future<void> playLevelUp() async => _playSfx('level_up');
  Future<void> playChestOpen() async => _playSfx('chest_open');

  Future<void> _playSfx(String name) async {
    if (!_soundEnabled || _sfxVolume <= 0) return;
    try {
      if (_sfxPlayers.isEmpty) await init();
      if (_sfxPlayers.isEmpty) return;

      final player = _sfxPlayers[_sfxIndex];
      _sfxIndex = (_sfxIndex + 1) % _sfxPlayers.length;

      await player.stop();
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource('audio/$name.wav'));
    } catch (_) {}
  }

  void dispose() {
    try {
      _musicPlayer?.dispose();
      for (final p in _sfxPlayers) {
        p.dispose();
      }
      _sfxPlayers.clear();
      _initialized = false;
    } catch (_) {}
  }
}
