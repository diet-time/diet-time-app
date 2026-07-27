import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/onboarding/data/journey_state_repository.dart';
import 'package:diet_time/features/personalization/data/personalization_services.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MealPlanRecommendationScreen extends ConsumerStatefulWidget {
  const MealPlanRecommendationScreen({super.key});

  @override
  ConsumerState<MealPlanRecommendationScreen> createState() =>
      _MealPlanRecommendationScreenState();
}

class _MealPlanRecommendationScreenState
    extends ConsumerState<MealPlanRecommendationScreen> {
  late final Future<MealPlanRecommendation> _result = _submitAndRecommend();

  Future<MealPlanRecommendation> _submitAndRecommend() async {
    final draft = ref.read(personalizationControllerProvider);
    await ref.read(personalizationProfileServiceProvider).submit(draft);
    final result = await ref
        .read(mealPlanRecommendationServiceProvider)
        .recommend(draft);
    await ref
        .read(journeyStateRepositoryProvider)
        .markPersonalizationComplete();
    await ref.read(journeyStateRepositoryProvider).markProfileComplete();
    ref.read(personalizationControllerProvider.notifier).clear();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      body: SafeArea(
        child: FutureBuilder<MealPlanRecommendation>(
          future: _result,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.emeraldGreen),
              );
            }
            final recommendation = snapshot.data!;
            final reasonLabels = <String, String>{
              'PRIMARY_GOAL': l10n.recommendationReasonGoal,
              'ACTIVITY': l10n.recommendationReasonActivity,
              'PREFERENCES': l10n.recommendationReasonPreferences,
              'ALLERGENS': l10n.recommendationReasonAllergens,
            };
            final reasons = recommendation.reasonCodes
                .map((code) => reasonLabels[code])
                .whereType<String>();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.recommendationTitle,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 31,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    key: const ValueKey('recommendedPlanCard'),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkGreen.withValues(alpha: .10),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          recommendation.imageAsset,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recommendation.planName,
                                style: const TextStyle(
                                  color: AppColors.darkGreen,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                recommendation.description,
                                style: TextStyle(
                                  color: AppColors.darkGreen.withValues(
                                    alpha: .64,
                                  ),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              for (final reason in reasons)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 18,
                                        color: AppColors.emeraldGreen,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(reason)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    key: const ValueKey('viewRecommendedPlan'),
                    label: l10n.viewRecommendedPlan,
                    onPressed: () => context.push(AppRoutes.plans),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: AppButton.height,
                    child: OutlinedButton(
                      key: const ValueKey('compareAllPlans'),
                      onPressed: () => context.push(AppRoutes.plans),
                      child: Text(l10n.compareAllPlans),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
