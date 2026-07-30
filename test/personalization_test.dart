import 'package:diet_time/features/personalization/data/guest_recommendation_repository.dart';
import 'package:diet_time/features/personalization/domain/plan_recommendation.dart';
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

  testWidgets('guest recommendations render without authentication', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guestPlanRecommendationsProvider.overrideWith(
            (ref, language) async => const [
              PlanRecommendation(
                id: 'everyday-id',
                code: 'EVERYDAY',
                name: 'Everyday Balance',
                description: 'Balanced meals for everyday routines.',
                isRecommended: true,
              ),
            ],
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

    expect(find.text('Everyday Balance'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('selectPlan-everyday-id')),
      findsOneWidget,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('hasCompletedPersonalization'), isNull);
    expect(preferences.getBool('hasCompletedProfile'), isNull);
  });
}
