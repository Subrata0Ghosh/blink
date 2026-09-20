import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'services/audio_service.dart';

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

  // Check onboarding status
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;

  runApp(
    ProviderScope(
      child: BlinkApp(onboardingComplete: onboardingComplete),
    ),
  );
}

class BlinkApp extends StatelessWidget {
  final bool onboardingComplete;

  const BlinkApp({super.key, required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    final router = createRouter(onboardingComplete: onboardingComplete);

    return MaterialApp.router(
      title: 'BLINK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
