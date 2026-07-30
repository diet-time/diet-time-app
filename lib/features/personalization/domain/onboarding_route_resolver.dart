import 'package:diet_time/app/router/app_router.dart';

abstract final class OnboardingStepCode {
  static const basicDetails = 'BASIC_DETAILS';
  static const bodyMeasurements = 'BODY_MEASUREMENTS';
  static const goal = 'GOAL';
  static const dailyRoutine = 'DAILY_ROUTINE';
  static const activityLevel = 'ACTIVITY_LEVEL';
  static const allergens = 'ALLERGENS';
  static const preferences = 'PREFERENCES';
  static const profileCompleted = 'PROFILE_COMPLETED';
}

abstract final class OnboardingRouteResolver {
  static const _pageByStep = <String, int>{
    OnboardingStepCode.basicDetails: 2,
    OnboardingStepCode.bodyMeasurements: 2,
    OnboardingStepCode.goal: 1,
    OnboardingStepCode.dailyRoutine: 3,
    OnboardingStepCode.activityLevel: 4,
    OnboardingStepCode.allergens: 6,
    OnboardingStepCode.preferences: 5,
    OnboardingStepCode.profileCompleted: 8,
  };

  static int pageFor(String? stepCode) =>
      _pageByStep[stepCode] ?? _pageByStep[OnboardingStepCode.basicDetails]!;

  static String routeFor({
    required String? stepCode,
    required bool shouldShowOnboarding,
  }) {
    if (!shouldShowOnboarding ||
        stepCode == OnboardingStepCode.profileCompleted) {
      return AppRoutes.recommendation;
    }
    return AppRoutes.personalization;
  }
}
