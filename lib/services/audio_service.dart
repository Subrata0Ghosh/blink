import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

/// Audio service for BLINK
/// Handles synthesized cosmic sound effects and looped ambient space music
/// with periodic ambient rest intervals and global cross-screen persistence.
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  bool _initialized = false;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.45; // Gentle, toe-tapping casual music level
  double _sfxVolume = 0.82;   // Crisp, juicy, non-piercing SFX level

  AudioPlayer? _musicPlayer;
  final List<AudioPlayer> _sfxPlayers = [];
  int _sfxIndex = 0;
  static const int _poolSize = 4;

  // Periodic ambient rest/play cycle
  Timer? _musicCycleTimer;
  bool _isInPausePhase = false;
  static const Duration playDuration = Duration(seconds: 45);
  static const Duration pauseDuration = Duration(seconds: 12);

  static AudioService get instance => _instance;
  bool get isSoundEnabled => _soundEnabled;
  bool get isMusicEnabled => _musicEnabled;
  bool get isSfxEnabled => _sfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Configure global audio context so SFX never steals focus or interrupts background music
      final audioContext = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();
      await AudioPlayer.global.setAudioContext(audioContext);

      _musicPlayer = AudioPlayer(playerId: 'blink_music');
      await _musicPlayer?.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer?.setVolume((_soundEnabled && _musicEnabled) ? _musicVolume : 0.0);

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
        _musicCycleTimer?.cancel();
        _isInPausePhase = false;
        _musicPlayer?.pause();
      } else {
        if (_musicEnabled && _musicVolume > 0) {
          startAmbientMusic();
        }
      }
    } catch (_) {}
  }

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    try {
      if (!enabled) {
        _musicCycleTimer?.cancel();
        _isInPausePhase = false;
        _musicPlayer?.pause();
      } else {
        if (_soundEnabled && _musicVolume > 0) {
          _isInPausePhase = false;
          startAmbientMusic();
        }
      }
    } catch (_) {}
  }

  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
  }

  void setMusicVolume(double vol) {
    _musicVolume = vol.clamp(0.0, 1.0);
    try {
      if (_musicVolume <= 0.0) {
        _musicCycleTimer?.cancel();
        _isInPausePhase = false;
        _musicPlayer?.setVolume(0.0);
        _musicPlayer?.pause();
      } else {
        if (_soundEnabled && _musicEnabled) {
          _musicPlayer?.setVolume(_musicVolume);
          if (_musicPlayer?.state != PlayerState.playing && !_isInPausePhase) {
            startAmbientMusic();
          }
        }
      }
    } catch (_) {}
  }

  void setSfxVolume(double vol) {
    _sfxVolume = vol.clamp(0.0, 1.0);
  }

  Future<void> startAmbientMusic() async {
    if (!_soundEnabled || !_musicEnabled || _musicVolume <= 0) return;
    try {
      if (_musicPlayer == null) await init();
      // If currently resting in the scheduled ambient pause phase, keep resting
      if (_isInPausePhase) return;

      // If already playing smoothly, ensure cycle timer is running and don't interrupt
      if (_musicPlayer?.state == PlayerState.playing) {
        _ensureCycleTimerRunning();
        return;
      }

      await _musicPlayer?.setVolume(_musicVolume);
      await _musicPlayer?.play(AssetSource('audio/ambient_music.wav'));
      _scheduleMusicCycle();
    } catch (_) {}
  }

  void _ensureCycleTimerRunning() {
    if (_musicCycleTimer == null || !_musicCycleTimer!.isActive) {
      _scheduleMusicCycle();
    }
  }

  bool get _isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  void _scheduleMusicCycle() {
    _musicCycleTimer?.cancel();
    _isInPausePhase = false;
    if (_isTestEnvironment) return;

    // After playDuration, briefly pause to give a gentle cosmic ambient breather
    _musicCycleTimer = Timer(playDuration, () async {
      if (!_soundEnabled || !_musicEnabled || _musicVolume <= 0) return;
      _isInPausePhase = true;
      try {
        await _musicPlayer?.pause();
      } catch (_) {}

      // After pauseDuration, start playing again
      _musicCycleTimer = Timer(pauseDuration, () async {
        if (!_soundEnabled || !_musicEnabled || _musicVolume <= 0) return;
        _isInPausePhase = false;
        try {
          await _musicPlayer?.setVolume(_musicVolume);
          await _musicPlayer?.resume();
          _scheduleMusicCycle();
        } catch (_) {
          startAmbientMusic();
        }
      });
    });
  }

  Future<void> pauseMusic() async {
    try {
      _musicCycleTimer?.cancel();
      _isInPausePhase = false;
      await _musicPlayer?.pause();
    } catch (_) {}
  }

  Future<void> resumeMusic() async {
    if (!_soundEnabled || !_musicEnabled || _musicVolume <= 0) return;
    try {
      _isInPausePhase = false;
      await _musicPlayer?.resume();
      _scheduleMusicCycle();
    } catch (_) {
      startAmbientMusic();
    }
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
    if (!_soundEnabled || !_sfxEnabled || _sfxVolume <= 0) return;
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
      _musicCycleTimer?.cancel();
      _musicPlayer?.dispose();
      for (final p in _sfxPlayers) {
        p.dispose();
      }
      _sfxPlayers.clear();
      _initialized = false;
    } catch (_) {}
  }
}
