import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for managing local re-engagement and atmospheric notifications in BLINK
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Atmospheric notification messages pool to remind user when inactive
  static const List<Map<String, String>> _cosmicReminders = [
    {
      'title': 'The Cosmic World is waiting for you! 🌌',
      'body': 'Nova detected a celestial shift. Jump in and test your observation skills!',
    },
    {
      'title': 'Energy fully restored! ⚡',
      'body': 'Your cosmic energy is at maximum. Return now to conquer the next shift!',
    },
    {
      'title': 'Your Daily Gift is ready to open! 🎁',
      'body': 'Don\'t let your streak break. Free cosmic gems are waiting for you!',
    },
    {
      'title': 'The stars have shifted... 🔮',
      'body': 'A rare mystery portal has opened. Can your memory conquer the new realm?',
    },
    {
      'title': 'The Cosmos misses your keen eye! ✨',
      'body': 'Reality changed while you were away. Come blink and discover what shifted.',
    },
    {
      'title': 'Shift Gems are accumulating! 💎',
      'body': 'Claim your cosmic bounty today and unlock exclusive relics.',
    },
  ];

  /// Initialize notifications plugin and setup channels
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      // Create notification channel for Android 8+
      const androidChannel = AndroidNotificationChannel(
        'blink_cosmic_reminders',
        'Cosmic Shifts & Reminders',
        description: 'Atmospheric alerts when new portals open and energy recharges in BLINK.',
        importance: Importance.high,
        enableLights: true,
        ledColor: Color(0xFF00E5FF),
        enableVibration: true,
      );

      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(androidChannel);
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully.');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Request permissions (Required for Android 13+)
  Future<bool> requestPermissions() async {
    try {
      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final notifGranted = await androidImpl.requestNotificationsPermission() ?? false;
        final exactGranted = await androidImpl.requestExactAlarmsPermission() ?? false;
        debugPrint('Notification permissions - notifications: $notifGranted, exact alarms: $exactGranted');
        return notifGranted;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Show an instant test notification (e.g. for testing or welcome back)
  Future<void> showInstantNotification({
    String? title,
    String? body,
    String? payload,
  }) async {
    if (!_isInitialized) await init();

    final randomIndex = Random().nextInt(_cosmicReminders.length);
    final selected = _cosmicReminders[randomIndex];

    final notifTitle = title ?? selected['title']!;
    final notifBody = body ?? selected['body']!;

    final androidDetails = AndroidNotificationDetails(
      'blink_cosmic_reminders',
      'Cosmic Shifts & Reminders',
      channelDescription: 'Atmospheric alerts when new portals open in BLINK.',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF00E5FF),
      styleInformation: BigTextStyleInformation(notifBody),
      icon: '@mipmap/ic_launcher',
    );

    final notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        id: 0,
        title: notifTitle,
        body: notifBody,
        notificationDetails: notifDetails,
        payload: payload ?? 'cosmic_instant',
      );
      debugPrint('Instant notification sent: $notifTitle');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Schedule re-engagement reminders when user exits the app
  /// Scheduled at:
  /// - 10 minutes after exit (prompt atmospheric nudge, easily testable)
  /// - 1 hour after exit (energy restored)
  /// - 6 hours after exit (mystery portal ready)
  /// - 24 hours after exit (streak protector)
  /// - 48 hours after exit (cosmic return bounty)
  Future<void> scheduleInactivityReminders() async {
    if (!_isInitialized) await init();

    try {
      // Cancel previous scheduled reminders before rescheduling new ones
      await cancelAllReminders();

      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      bool canExact = false;
      try {
        canExact = await androidImpl?.canScheduleExactNotifications() ?? false;
      } catch (_) {}

      final scheduleMode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      final offsets = [
        const Duration(minutes: 10),
        const Duration(hours: 1),
        const Duration(hours: 6),
        const Duration(hours: 24),
        const Duration(hours: 48),
      ];

      for (int i = 0; i < offsets.length; i++) {
        final reminder = _cosmicReminders[i % _cosmicReminders.length];
        final scheduledTime = tz.TZDateTime.now(tz.local).add(offsets[i]);

        final androidDetails = AndroidNotificationDetails(
          'blink_cosmic_reminders',
          'Cosmic Shifts & Reminders',
          channelDescription: 'Atmospheric alerts when new portals open in BLINK.',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF00E5FF),
          styleInformation: BigTextStyleInformation(reminder['body']!),
          icon: '@mipmap/ic_launcher',
        );

        final notifDetails = NotificationDetails(
          android: androidDetails,
          iOS: const DarwinNotificationDetails(),
        );

        await _notificationsPlugin.zonedSchedule(
          id: 100 + i,
          title: reminder['title'],
          body: reminder['body'],
          scheduledDate: scheduledTime,
          notificationDetails: notifDetails,
          androidScheduleMode: scheduleMode,
        );
      }
      debugPrint('Scheduled ${offsets.length} cosmic inactivity reminders (exact: $canExact).');
    } catch (e) {
      debugPrint('Error scheduling inactivity reminders: $e');
    }
  }

  /// Schedule a quick test notification for immediate validation (e.g. 15 seconds after exit)
  Future<void> scheduleTestReminder({Duration delay = const Duration(seconds: 15)}) async {
    if (!_isInitialized) await init();

    try {
      final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);
      const androidDetails = AndroidNotificationDetails(
        'blink_cosmic_reminders',
        'Cosmic Shifts & Reminders',
        channelDescription: 'Atmospheric alerts when new portals open in BLINK.',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF00E5FF),
        icon: '@mipmap/ic_launcher',
      );

      const notifDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      bool canExact = false;
      try {
        canExact = await androidImpl?.canScheduleExactNotifications() ?? false;
      } catch (_) {}

      await _notificationsPlugin.zonedSchedule(
        id: 999,
        title: 'The Cosmos misses your keen eye! ✨',
        body: 'Reality changed while you were away. Come blink and discover what shifted.',
        scheduledDate: scheduledTime,
        notificationDetails: notifDetails,
        androidScheduleMode: canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('Test reminder scheduled for ${delay.inSeconds} seconds from now.');
    } catch (e) {
      debugPrint('Error scheduling test reminder: $e');
    }
  }

  /// Trigger an in-app atmospheric nudge when user has been idle/inactive
  Future<void> triggerInAppInactivityNudge() async {
    await showInstantNotification(
      title: 'Are you still observing? 🌌',
      body: 'Reality shifts constantly in BLINK. Tap or look around to resume your cosmic journey!',
      payload: 'in_app_inactivity',
    );
  }

  /// Cancel scheduled reminders (called when user opens or resumes the app)
  Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('Cancelled scheduled pending reminders.');
    } catch (e) {
      debugPrint('Error cancelling reminders: $e');
    }
  }
}
