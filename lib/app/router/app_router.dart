import 'package:diet_time/features/authentication/presentation/login_screen.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_verification_page.dart';
import 'package:diet_time/features/authentication/presentation/phone_login_page.dart';
import 'package:diet_time/features/home/presentation/home_screen.dart';
import 'package:diet_time/features/home/presentation/route_placeholder_screen.dart';
import 'package:diet_time/features/language/presentation/language_selection_screen.dart';
import 'package:diet_time/features/menu/presentation/browse_menu_screen.dart';
import 'package:diet_time/features/onboarding/presentation/onboarding_carousel_screen.dart';
import 'package:diet_time/features/onboarding/presentation/onboarding_screen.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_screen.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_details_screen.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_start_date_screen.dart';
import 'package:diet_time/features/personalization/presentation/post_login_name_gate.dart';
import 'package:diet_time/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const landing = '/landing';
  static const onboarding = '/onboarding';
  static const personalization = '/personalization';
  static const menu = '/menu';
  static const language = '/language';
  static const login = '/login';
  static const phoneLogin = '/phone-login';
  static const otp = '/otp-verification';
  static const plans = '/plans';
  static const planDetails = '/plan-details';
  static const planStartDate = '/plan-start-date';
  static const postLogin = '/post-login';
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
            _slidePage(state: state, child: const OnboardingCarouselScreen()),
      ),
      GoRoute(
        path: AppRoutes.personalization,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: const PersonalizationScreen()),
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
        path: AppRoutes.phoneLogin,
        pageBuilder: (context, state) {
          final destination =
              state.extra as PendingAuthDestination? ??
              const PendingAuthDestination(route: AppRoutes.plans);
          return _slidePage(
            state: state,
            child: PhoneLoginPage(pendingDestination: destination),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.otp,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: const OtpVerificationPage()),
      ),
      GoRoute(
        path: AppRoutes.plans,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: const MealPlanScreen()),
      ),
      GoRoute(
        path: AppRoutes.planDetails,
        pageBuilder: (context, state) {
          final plan = state.extra;
          if (plan is! MealPlanOption) {
            return _slidePage(state: state, child: const MealPlanScreen());
          }
          return _slidePage(
            state: state,
            child: MealPlanDetailsScreen(plan: plan),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.planStartDate,
        pageBuilder: (context, state) {
          final selection = state.extra;
          if (selection is! MealPlanPurchaseSelection) {
            return _slidePage(state: state, child: const MealPlanScreen());
          }
          return _slidePage(
            state: state,
            child: MealPlanStartDateScreen(selection: selection),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.postLogin,
        pageBuilder: (context, state) {
          final nextRoute = state.extra as String? ?? AppRoutes.home;
          return _slidePage(
            state: state,
            child: PostLoginNameGate(onContinue: () => context.go(nextRoute)),
          );
        },
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
