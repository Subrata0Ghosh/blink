import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';

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
  await notifService.requestPermissions();

  // Check onboarding status
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;

  runApp(
    ProviderScope(
      child: BlinkApp(onboardingComplete: onboardingComplete),
    ),
  );
}

class BlinkApp extends StatefulWidget {
  final bool onboardingComplete;

  const BlinkApp({super.key, required this.onboardingComplete});

  @override
  State<BlinkApp> createState() => _BlinkAppState();
}

class _BlinkAppState extends State<BlinkApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // User is currently active in the app, cancel pending reminders
    NotificationService().cancelAllReminders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // User left or backgrounded the game -> schedule atmospheric reminders
      NotificationService().scheduleInactivityReminders();
    } else if (state == AppLifecycleState.resumed) {
      // User came back -> cancel reminders
      NotificationService().cancelAllReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = createRouter(onboardingComplete: widget.onboardingComplete);

    return MaterialApp.router(
      title: 'BLINK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
