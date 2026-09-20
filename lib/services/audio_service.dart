/// Audio service stub — provides sound effect categories
/// Real audio files would be loaded in production; for now this provides
/// the interface and plays simple system feedback.
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  bool _initialized = false;
  bool _soundEnabled = true;
  double _musicVolume = 1.0;
  double _sfxVolume = 1.0;

  double get musicVolume => _musicVolume;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // Audio players would be initialized here with actual sound files
  }

  void setSoundEnabled(bool enabled) => _soundEnabled = enabled;
  void setMusicVolume(double vol) => _musicVolume = vol;
  void setSfxVolume(double vol) => _sfxVolume = vol;

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
    // In production, load and play from assets/sounds/$name.mp3
    // For now, the interface is ready for sound files to be dropped in
  }

  void dispose() {
    // Dispose audio players
  }
}
