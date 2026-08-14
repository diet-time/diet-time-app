import 'package:diet_time/features/authentication/presentation/login_screen.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_verification_page.dart';
import 'package:diet_time/features/authentication/presentation/phone_login_page.dart';
import 'package:diet_time/features/checkout/presentation/customer_address_screen.dart';
import 'package:diet_time/features/checkout/presentation/plan_summary_screen.dart';
import 'package:diet_time/features/checkout/presentation/order_placed_screen.dart';
import 'package:diet_time/features/dashboard/presentation/order_details_screen.dart';
import 'package:diet_time/features/dashboard/domain/customer_account_profile.dart';
import 'package:diet_time/features/dashboard/presentation/edit_customer_profile_page.dart';
import 'package:diet_time/features/dashboard/presentation/upcoming_deliveries_screen.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
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
import 'package:diet_time/features/personalization/presentation/authenticated_landing_screen.dart';
import 'package:diet_time/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const landing = '/landing';
  static const onboarding = '/onboarding';
  static const personalization = '/personalization';
  static const customerQuestionnaire = '/customer-questionnaire';
  static const menu = '/menu';
  static const language = '/language';
  static const phoneLogin = '/phone-login';
  static const otp = '/otp-verification';
  static const plans = '/plans';
  static const planDetails = '/plan-details';
  static const planStartDate = '/plan-start-date';
  static const planSummary = '/plan-summary';
  static const customerAddress = '/customer-address';
  static const planCheckoutReady = '/plan-checkout-ready';
  static const orderPlaced = '/order-placed';
  static const postLogin = '/post-login';
  static const authenticatedLanding = '/authenticated-landing';
  static const register = '/register';
  static const home = '/home';
  static const orderDetails = '/order-details';
  static const upcomingDeliveries = '/upcoming-deliveries';
  static const editCustomerProfile = '/edit-customer-profile';
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
        path: AppRoutes.customerQuestionnaire,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const PersonalizationScreen(customerProfileMode: true),
        ),
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
        path: AppRoutes.planSummary,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: const PlanSummaryScreen()),
      ),
      GoRoute(
        path: AppRoutes.customerAddress,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: const CustomerAddressScreen()),
      ),
      GoRoute(
        path: AppRoutes.planCheckoutReady,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const RoutePlaceholderScreen(title: 'Plan details are ready'),
        ),
      ),
      GoRoute(
        path: AppRoutes.orderPlaced,
        pageBuilder: (context, state) =>
            _slidePage(state: state, child: const OrderPlacedScreen()),
      ),
      GoRoute(
        path: AppRoutes.postLogin,
        pageBuilder: (context, state) {
          final nextRoute =
              state.extra as String? ?? AppRoutes.authenticatedLanding;
          return _slidePage(
            state: state,
            child: PostLoginNameGate(onContinue: () => context.go(nextRoute)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.authenticatedLanding,
        builder: (context, state) => const AuthenticatedLandingScreen(),
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
      GoRoute(
        path: AppRoutes.orderDetails,
        pageBuilder: (context, state) {
          final orderId = state.extra as String?;
          return _slidePage(
            state: state,
            child: orderId == null || orderId.isEmpty
                ? const HomeScreen()
                : OrderDetailsScreen(orderId: orderId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.upcomingDeliveries,
        pageBuilder: (context, state) {
          final order = state.extra;
          return _slidePage(
            state: state,
            child: order is OrderConfirmation
                ? UpcomingDeliveriesScreen(order: order)
                : const HomeScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editCustomerProfile,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: EditCustomerProfilePage(
            profile: state.extra is CustomerAccountProfile
                ? state.extra! as CustomerAccountProfile
                : null,
          ),
        ),
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
