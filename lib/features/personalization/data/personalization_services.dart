import 'package:diet_time/features/personalization/domain/personalization_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const useMockMealPlanRecommendation = true;

final mealPlanRecommendationServiceProvider =
    Provider<MealPlanRecommendationService>((ref) {
      assert(
        useMockMealPlanRecommendation,
        'Provide the production recommendation service.',
      );
      return const MockMealPlanRecommendationService();
    });

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
