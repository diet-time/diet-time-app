import 'package:diet_time/features/personalization/domain/personalization_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const useMockMealPlanRecommendation = true;

final personalizationProfileServiceProvider =
    Provider<PersonalizationProfileService>(
      (ref) => const DeferredPersonalizationProfileService(),
    );

final mealPlanRecommendationServiceProvider =
    Provider<MealPlanRecommendationService>((ref) {
      assert(
        useMockMealPlanRecommendation,
        'Provide the production recommendation service.',
      );
      return const MockMealPlanRecommendationService();
    });

abstract interface class PersonalizationProfileService {
  Future<void> submit(PersonalizationDraft draft);
}

/// Isolates the profile handoff until the production profile endpoint is
/// available. Replacing this implementation does not affect the UI or OTP.
class DeferredPersonalizationProfileService
    implements PersonalizationProfileService {
  const DeferredPersonalizationProfileService();

  @override
  Future<void> submit(PersonalizationDraft draft) async {
    // The draft remains in memory and is considered submitted by this
    // development adapter. Production must replace this provider.
  }
}

class MealPlanRecommendation {
  const MealPlanRecommendation({
    required this.planCode,
    required this.planName,
    required this.description,
    required this.reasonCodes,
    required this.imageAsset,
  });

  final String planCode;
  final String planName;
  final String description;
  final List<String> reasonCodes;
  final String imageAsset;
}

abstract interface class MealPlanRecommendationService {
  Future<MealPlanRecommendation> recommend(PersonalizationDraft draft);
}

/// Temporary feature-flagged fallback. Recommendation rules never live in UI.
class MockMealPlanRecommendationService
    implements MealPlanRecommendationService {
  const MockMealPlanRecommendationService();

  @override
  Future<MealPlanRecommendation> recommend(PersonalizationDraft draft) async {
    return const MealPlanRecommendation(
      planCode: 'BALANCED',
      planName: 'Balanced Living',
      description: 'A flexible selection of balanced everyday meals.',
      reasonCodes: ['PRIMARY_GOAL', 'ACTIVITY', 'PREFERENCES', 'ALLERGENS'],
      imageAsset: 'assets/images/onboarding_2.png',
    );
  }
}
