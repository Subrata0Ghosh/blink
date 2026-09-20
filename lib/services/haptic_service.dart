import 'package:vibration/vibration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_state_service.dart';

/// Haptic feedback service — different intensities for different events
class HapticService {
  static Future<bool> _hasVibrator() async {
    try {
      final result = await Vibration.hasVibrator();
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> lightTap() async {
    if (await _hasVibrator()) {
      Vibration.vibrate(duration: 10, amplitude: 40);
    }
  }

  static Future<void> mediumTap() async {
    if (await _hasVibrator()) {
      Vibration.vibrate(duration: 20, amplitude: 80);
    }
  }

  static Future<void> correctAnswer() async {
    if (await _hasVibrator()) {
      Vibration.vibrate(duration: 30, amplitude: 100);
    }
  }

  static Future<void> perfectAnswer() async {
    if (await _hasVibrator()) {
      Vibration.vibrate(pattern: [0, 20, 50, 30], intensities: [0, 80, 0, 120]);
    }
  }

  static Future<void> wrongAnswer() async {
    if (await _hasVibrator()) {
      Vibration.vibrate(duration: 50, amplitude: 60);
    }
  }

  static Future<void> gemPickup() async {
    if (await _hasVibrator()) {
      Vibration.vibrate(pattern: [0, 5, 30, 5, 30, 5], intensities: [0, 40, 0, 50, 0, 60]);
    }
  }

  static Future<void> levelUp() async {
    if (await _hasVibrator()) {
      Vibration.vibrate(pattern: [0, 30, 80, 50, 80, 80], intensities: [0, 60, 0, 100, 0, 128]);
    }
  }
}

/// Provider-aware haptic helper
void triggerHaptic(WidgetRef ref, Future<void> Function() hapticFn) {
  final state = ref.read(gameStateProvider);
  if (state.hapticEnabled) {
    hapticFn();
  }
}
