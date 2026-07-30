import 'package:diet_time/features/personalization/data/personalization_services.dart';
import 'package:diet_time/features/personalization/domain/personalization_draft.dart';
import 'package:diet_time/features/personalization/presentation/meal_plan_recommendation_screen.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Riverpod profile preserves answers without calculating BMI', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      personalizationControllerProvider.notifier,
    );

    controller.setGoal('LOSE_WEIGHT');
    controller.setHeight(176);
    controller.setWeight(80);
    controller.setRoutine('SHIFT_WORKER');
    controller.setActivity('ACTIVE_LIFESTYLE');

    final draft = container.read(personalizationControllerProvider);
    expect(draft.primaryGoal, 'LOSE_WEIGHT');
    expect(draft.dailyRoutine, 'SHIFT_WORKER');
    expect(draft.activityLevel, 'ACTIVE_LIFESTYLE');
    expect(draft.heightCm, 176);
    expect(draft.weightKg, 80);
    expect(draft.bmi, isNull);
  });

  testWidgets('recommendation submits draft and renders returned plan', (
    tester,
  ) async {
    final recommendationService = _FakeRecommendationService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealPlanRecommendationServiceProvider.overrideWithValue(
            recommendationService,
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MealPlanRecommendationScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(recommendationService.calls, 1);
    expect(find.text('Everyday Balance'), findsOneWidget);
    expect(find.byKey(const ValueKey('viewRecommendedPlan')), findsOneWidget);
    expect(find.byKey(const ValueKey('compareAllPlans')), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('hasCompletedPersonalization'), isNull);
    expect(preferences.getBool('hasCompletedProfile'), isNull);
  });
}

class _FakeRecommendationService implements MealPlanRecommendationService {
  int calls = 0;

  @override
  Future<MealPlanRecommendation> recommend(PersonalizationDraft draft) async {
    calls++;
    return const MealPlanRecommendation(
      planCode: 'EVERYDAY',
      planName: 'Everyday Balance',
      description: 'Balanced meals for everyday routines.',
      reasonCodes: ['PRIMARY_GOAL'],
      imageAsset: 'assets/images/onboarding_2.png',
    );
  }
}
