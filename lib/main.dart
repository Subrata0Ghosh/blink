import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'services/game_state_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Immersive system UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0E1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize audio
  await AudioService().init();

  // Initialize notifications
  final notifService = NotificationService();
  await notifService.init();

  // Initialize local persistent storage
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BlinkApp(),
    ),
  );
}

class BlinkApp extends StatefulWidget {
  final bool? onboardingComplete;

  const BlinkApp({super.key, this.onboardingComplete});

  @override
  State<BlinkApp> createState() => _BlinkAppState();
}

class _BlinkAppState extends State<BlinkApp> with WidgetsBindingObserver {
  late final GoRouter _router;
  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(minutes: 3);

  @override
  void initState() {
    super.initState();
    _router = createRouter(onboardingComplete: widget.onboardingComplete);
    WidgetsBinding.instance.addObserver(this);
    // User is currently active in the app, cancel pending reminders
    NotificationService().cancelAllReminders();
    _resetInactivityTimer();

    // Request permissions once activity is actively displaying first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().requestPermissions();
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      NotificationService().triggerInAppInactivityNudge();
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle state changed: $state');
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _inactivityTimer?.cancel();
      // User left or backgrounded the game -> schedule atmospheric reminders
      NotificationService().scheduleInactivityReminders();
    } else if (state == AppLifecycleState.resumed) {
      // User came back -> cancel reminders & restart in-app idle timer
      NotificationService().cancelAllReminders();
      _resetInactivityTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      behavior: HitTestBehavior.translucent,
      child: MaterialApp.router(
        title: 'BLINK',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}

