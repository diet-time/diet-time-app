import 'dart:async';

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/authentication/data/mock_authentication_service.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/personalization/data/guest_recommendation_repository.dart';
import 'package:diet_time/features/personalization/domain/plan_recommendation.dart';
import 'package:diet_time/features/personalization/presentation/plan_selection_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MealPlanRecommendationScreen extends ConsumerWidget {
  const MealPlanRecommendationScreen({super.key});

  Future<void> _selectPlan(
    BuildContext context,
    WidgetRef ref,
    PlanRecommendation plan,
  ) async {
    ref
        .read(planSelectionControllerProvider.notifier)
        .select(plan, postLoginRoute: AppRoutes.plans);
    final authenticated = await ref
        .read(authenticationServiceProvider)
        .isLoggedIn();
    if (!context.mounted) return;
    if (authenticated) {
      await context.push<void>(AppRoutes.plans);
      return;
    }
    await context.push<void>(
      AppRoutes.phoneLogin,
      extra: PendingAuthDestination(
        route: AppRoutes.plans,
        planCode: plan.code,
        planName: plan.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = Localizations.localeOf(context).languageCode;
    final recommendations = ref.watch(
      guestPlanRecommendationsProvider(language),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      body: SafeArea(
        child: recommendations.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.emeraldGreen),
          ),
          error: (error, stackTrace) => _RecommendationError(
            onRetry: () =>
                ref.invalidate(guestPlanRecommendationsProvider(language)),
          ),
          data: (plans) {
            if (plans.isEmpty) {
              return _RecommendationError(
                empty: true,
                onRetry: () =>
                    ref.invalidate(guestPlanRecommendationsProvider(language)),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              children: [
                Text(
                  AppLocalizations.of(context).recommendationTitle,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 30,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  language == 'ar'
                      ? 'خطط مختارة بناءً على ملفك الغذائي.'
                      : 'Plans selected from your nutrition profile.',
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .62),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                for (final plan in plans) ...[
                  _RecommendationCard(
                    plan: plan,
                    onSelect: () => unawaited(_selectPlan(context, ref, plan)),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.plan, required this.onSelect});

  final PlanRecommendation plan;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return Container(
      key: ValueKey('recommendedPlan-${plan.id}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: .09),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 185,
            width: double.infinity,
            child: plan.imageUrl == null
                ? Image.asset(
                    'assets/images/onboarding_2.png',
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    plan.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Image.asset(
                      'assets/images/onboarding_2.png',
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (plan.isRecommended)
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.emeraldGreen,
                      ),
                  ],
                ),
                if (plan.description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    plan.description!,
                    style: TextStyle(
                      color: AppColors.darkGreen.withValues(alpha: .64),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (plan.mainBenefit != null)
                      _PlanFact(
                        icon: Icons.eco_rounded,
                        label: plan.mainBenefit!,
                      ),
                    if (plan.mealCount != null)
                      _PlanFact(
                        icon: Icons.restaurant_rounded,
                        label: '${plan.mealCount} meals',
                      ),
                    if (plan.durationDays != null)
                      _PlanFact(
                        icon: Icons.calendar_month_rounded,
                        label: '${plan.durationDays} days',
                      ),
                    if (plan.isAllergenCompatible)
                      _PlanFact(
                        icon: Icons.health_and_safety_rounded,
                        label: language == 'ar'
                            ? 'متوافق مع حساسيتك'
                            : 'Allergen compatible',
                      ),
                  ],
                ),
                if (plan.price != null) ...[
                  const SizedBox(height: 13),
                  Text(
                    '${plan.price!.toStringAsFixed(2)} ${plan.currency ?? ''}',
                    style: const TextStyle(
                      color: AppColors.emeraldGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                AppButton(
                  key: ValueKey('selectPlan-${plan.id}'),
                  label: language == 'ar'
                      ? 'اختر هذه الخطة'
                      : 'Select this plan',
                  onPressed: onSelect,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanFact extends StatelessWidget {
  const _PlanFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6ED),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.emeraldGreen, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationError extends StatelessWidget {
  const _RecommendationError({required this.onRetry, this.empty = false});

  final VoidCallback onRetry;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.emeraldGreen,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              empty
                  ? (arabic
                        ? 'لا توجد خطط متاحة حاليًا.'
                        : 'No plans available yet.')
                  : (arabic
                        ? 'تعذر تحميل الخطط المقترحة.'
                        : 'Unable to load recommended plans.'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextButton(
              key: const ValueKey('retryRecommendations'),
              onPressed: onRetry,
              child: Text(arabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
