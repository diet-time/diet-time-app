import 'package:diet_time/features/menu/domain/meal_nutrition.dart';
import 'package:diet_time/features/menu/domain/guest_home_models.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/features/menu/presentation/meal_nutrition_view.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'nutrition totals use configured serving quantities and retain genuine zero',
    () {
      final value = MealNutrition.total([
        (
          nutrition: const MealNutrition(
            calories: 300,
            protein: 20,
            carbs: 30,
            fat: 0,
          ),
          quantity: 2,
        ),
        (
          nutrition: const MealNutrition(
            calories: 100,
            protein: 5,
            carbs: 10,
            fat: 2,
          ),
          quantity: 1,
        ),
      ]);
      expect(value.calories, 700);
      expect(value.protein, 45);
      expect(value.carbs, 70);
      expect(value.fat, 2);
      expect(value.complete, isTrue);
    },
  );
  test('a missing nutrient never becomes zero or an understated total', () {
    final value = MealNutrition.total([
      (nutrition: const MealNutrition(calories: 300, protein: 20), quantity: 1),
      (nutrition: const MealNutrition(calories: 100), quantity: 1),
    ]);
    expect(value.calories, 400);
    expect(value.protein, isNull);
    expect(value.complete, isFalse);
    expect(MealNutrition.total([]).calories, isNull);
    final guest = GuestMealNutrition.fromJson({});
    expect(guest.calories, isNull);
    expect(guest.protein, isNull);
  });
  test('legacy calories remain available without inventing macros', () {
    const meal = DailyMealItem(
      id: 'one',
      optionId: 'option',
      name: 'Dish',
      category: 'meal',
      calories: 250,
    );
    expect(meal.nutrition.calories, 250);
    expect(meal.nutrition.protein, isNull);
  });
  test(
    'nutrition parsing preserves reference serving rather than assuming 100 g',
    () {
      final meal = DailyMealItem.fromJson({
        'mealItemId': 'one',
        'slotOptionId': 'option',
        'mealName': 'Dish',
        'category': 'meal',
        'quantity': 2,
        'nutrition': {
          'caloriesKcal': 320,
          'proteinGrams': 24,
          'carbohydratesGrams': 40,
          'fatGrams': 8,
          'servingQuantity': 250,
          'servingUnit': 'g',
        },
      });
      expect(meal.nutrition.servingQuantity, 250);
      expect(meal.quantity, 2);
      expect(
        MealNutrition.total([
          (nutrition: meal.nutrition, quantity: meal.quantity),
        ]).calories,
        640,
      );
    },
  );
  testWidgets('missing nutrition is readable in Arabic and RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(
          body: MealNutritionView(nutrition: MealNutrition()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('المعلومات الغذائية غير متاحة'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(MealNutritionView))),
      TextDirection.rtl,
    );
    expect(find.textContaining('0 kcal'), findsNothing);
  });
}
