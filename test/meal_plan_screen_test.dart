import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meal plan parses API image, calories, and pricing', () {
    final plan = MealPlanOption.fromJson(const {
      'id': 'plan-id',
      'code': 'CLASSIC',
      'name': 'Classic',
      'description': 'Everyday balanced meals.',
      'imageUrl': '/media/classic.jpg',
      'dailyCaloriesKcal': 1840,
      'startingPrice': 349.5,
      'currencyCode': 'QAR',
      'priceDurationDays': 7,
    });

    expect(plan.imageUrl, '/media/classic.jpg');
    expect(plan.dailyCaloriesKcal, 1840);
    expect(plan.startingPrice, 349.5);
    expect(plan.currencyCode, 'QAR');
    expect(plan.priceDurationDays, 7);
  });

  testWidgets('meal plan screen lists every API plan with calories and price', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealPlansProvider.overrideWith(
            (ref, language) async => const [
              MealPlanOption(
                id: 'classic-id',
                code: 'CLASSIC',
                name: 'Classic',
                description: 'Everyday balanced meals.',
                dailyCaloriesKcal: 1840,
                startingPrice: 349,
                currencyCode: 'QAR',
                priceDurationDays: 7,
              ),
              MealPlanOption(
                id: 'protein-id',
                code: 'HIGH_PROTEIN',
                name: 'High Protein',
                description: 'Protein-forward meals.',
                dailyCaloriesKcal: 2210,
                startingPrice: 429,
                currencyCode: 'QAR',
                priceDurationDays: 7,
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
          home: MealPlanScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('High Protein'), findsOneWidget);
    expect(find.text('1840 kcal / day'), findsOneWidget);
    expect(find.text('2210 kcal / day'), findsOneWidget);
    expect(find.text('QAR 349 / 7 days'), findsOneWidget);
    expect(find.text('QAR 429 / 7 days'), findsOneWidget);
  });
}
