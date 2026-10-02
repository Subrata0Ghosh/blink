import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/player_state.dart';
import '../widgets/modals/rate_app_modal.dart';

/// Service managing App Sharing and Store Rating with reward incentives
class AppReviewShareService {
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.blink.cosmic';
  static const String _marketUrl = 'market://details?id=com.blink.cosmic';
  static const String keyHasRated = 'has_rated_app';
  static const String keyRatingValue = 'user_rating_value';

  /// Share the game with friends via native share sheet
  static Future<void> shareApp({PlayerState? player}) async {
    final String message;
    if (player != null && player.level > 1) {
      message = '🚀 I reached Level ${player.level} with a ${player.currentStreak}-day streak on BLINK! '
          'Can you spot what changes in reality when you look away? '
          'Challenge me in offline multiplayer! Download BLINK: $_playStoreUrl';
    } else {
      message = '✨ Play BLINK — The Cosmic Observation Odyssey! '
          'Test your perception, spot hidden shifts in reality, and duel friends offline! '
          'Download free: $_playStoreUrl';
    }

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: 'Play BLINK with me — The World Shifts When You Look Away!',
      ),
    );
  }

  /// Share a specific challenge result or duel victory
  static Future<void> shareScore({
    required int score,
    int? combo,
    int? accuracy,
    int? level,
    String? opponentName,
    bool isDuelVictory = false,
  }) async {
    final String message;
    if (isDuelVictory && opponentName != null) {
      message = '⚔️ I just defeated $opponentName in an offline BLINK Duel with a score of $score! '
          'Think you have sharper eyes? Download BLINK and challenge me: $_playStoreUrl';
    } else if (accuracy != null) {
      message = '⚡ I just scored $score points with $accuracy% accuracy on BLINK! '
          'Can your eyes track the cosmic shift faster? Try it here: $_playStoreUrl';
    } else {
      message = '⚡ I just scored $score points${combo != null ? ' with a x$combo combo' : ''} on BLINK! '
          'Can your eyes track the cosmic shift faster? Try it here: $_playStoreUrl';
    }

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: 'My BLINK High Score!',
      ),
    );
  }

  /// Open the Rate Us 3D dialog
  static Future<void> showRateDialog(BuildContext context, {VoidCallback? onRewardClaimed}) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => RateAppModal(onRewardClaimed: onRewardClaimed),
    );
  }

  /// Launch store rating page
  static Future<bool> openStorePage() async {
    final marketUri = Uri.parse(_marketUrl);
    final webUri = Uri.parse(_playStoreUrl);

    try {
      if (await canLaunchUrl(marketUri)) {
        return await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Fallback
      if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
    return false;
  }

  /// Check if the user has already rated
  static Future<bool> hasUserRated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyHasRated) ?? false;
  }
}
