import 'package:diet_time/features/authentication/presentation/login_screen.dart';
import 'package:diet_time/features/home/presentation/home_screen.dart';
import 'package:diet_time/features/home/presentation/route_placeholder_screen.dart';
import 'package:diet_time/features/language/presentation/language_selection_screen.dart';
import 'package:diet_time/features/menu/presentation/browse_menu_screen.dart';
import 'package:diet_time/features/onboarding/presentation/onboarding_screen.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_screen.dart';
import 'package:diet_time/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const landing = '/landing';
  static const onboarding = '/onboarding';
  static const menu = '/menu';
  static const language = '/language';
  static const login = '/login';
  static const plans = '/plans';
  static const register = '/register';
  static const home = '/home';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.language,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 300),
          child: const LanguageSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.menu,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: const BrowseMenuScreen()),
      ),
      GoRoute(
        path: AppRoutes.landing,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 300),
          child: const LoginScreen(showLoginInitially: true),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offset =
                Tween<Offset>(
                  begin: const Offset(0, 0.035),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                );
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.plans,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: const MealPlanScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) =>
            const RoutePlaceholderScreen(title: 'Register'),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});

CustomTransitionPage<void> _slidePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(.06, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
