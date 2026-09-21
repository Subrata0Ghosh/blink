import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/play/play_screen.dart';
import '../../screens/result/result_screen.dart';
import '../../screens/world/world_screen.dart';
import '../../screens/collect/collect_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/daily/daily_shift_screen.dart';
import '../../screens/mystery/mystery_screen.dart';

/// App navigation using GoRouter
GoRouter createRouter({required bool onboardingComplete}) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 500),
          child: SplashScreen(
            onComplete: () {
              if (onboardingComplete) {
                context.go('/home');
              } else {
                context.go('/onboarding');
              }
            },
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 600),
          child: OnboardingScreen(
            onComplete: () => context.go('/home'),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 500),
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/play',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          child: const PlayScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: scaleAnim, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/world',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          child: const WorldScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/collect',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          child: const CollectScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          child: const ProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/daily-shift',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 500),
          child: const DailyShiftScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: scaleAnim, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/mystery',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 500),
          child: const MysteryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: scaleAnim, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/result',
        pageBuilder: (context, state) {
          final results = state.extra as Map<String, dynamic>? ?? {};
          return CustomTransitionPage(
            key: state.pageKey,
            transitionDuration: const Duration(milliseconds: 500),
            child: ResultScreen(results: results),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final slideAnim = Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slideAnim, child: child),
              );
            },
          );
        },
      ),
    ],
  );
}
