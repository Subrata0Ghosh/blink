import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/game_state_service.dart';
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
import '../../screens/multiplayer/multiplayer_hub_screen.dart';
import '../../screens/multiplayer/local_duel_screen.dart';
import '../../screens/multiplayer/p2p_room_screen.dart';
import '../../screens/leaderboard/leaderboard_screen.dart';

/// App navigation using GoRouter
GoRouter createRouter({bool? onboardingComplete}) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 500),
          child: Consumer(
            builder: (context, ref, _) {
              return SplashScreen(
                onComplete: () {
                  final isComplete = onboardingComplete ??
                      ref.read(gameStateProvider).onboardingComplete;
                  if (isComplete) {
                    context.go('/home');
                  } else {
                    context.go('/onboarding');
                  }
                },
              );
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
          reverseTransitionDuration: const Duration(milliseconds: 400),
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
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
        path: '/play',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          child: const PlayScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Zoom-in with slight scale for "entering the arena" feel
            final scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            final fadeAnim = CurvedAnimation(parent: animation, curve: Curves.easeIn);
            return FadeTransition(
              opacity: fadeAnim,
              child: ScaleTransition(scale: scaleAnim, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/world',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 450),
          child: const WorldScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Horizontal slide for world map
            final slideAnim = Tween<Offset>(
              begin: const Offset(0.15, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slideAnim, child: child),
            );
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
            // Slide from right for profile/settings
            final slideAnim = Tween<Offset>(
              begin: const Offset(0.2, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
            final scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: slideAnim,
                child: ScaleTransition(scale: scaleAnim, child: child),
              ),
            );
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
            transitionDuration: const Duration(milliseconds: 600),
            child: ResultScreen(results: results),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Scale up from center for dramatic reveal
              final scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              );
              final slideAnim = Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: slideAnim,
                  child: ScaleTransition(scale: scaleAnim, child: child),
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/multiplayer',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 450),
          child: const MultiplayerHubScreen(),
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
        path: '/local-duel',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          child: const LocalDuelScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/p2p-room',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          child: const P2pRoomScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/leaderboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 450),
          child: const LeaderboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnim = Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slideAnim, child: child),
            );
          },
        ),
      ),
    ],
  );
}
