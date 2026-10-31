import 'package:diet_time/features/menu/domain/meal_nutrition.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/features/menu/domain/guest_home_models.dart';
import 'package:diet_time/features/menu/presentation/meal_detail_viewer.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class MealNutritionView extends StatelessWidget {
  const MealNutritionView({
    super.key,
    required this.nutrition,
    this.total = false,
    this.compact = false,
  });
  final MealNutrition nutrition;
  final bool total;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    String number(double value) => value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    final metrics = [
      if (nutrition.calories != null) copy.kcal(nutrition.calories!.round()),
      if (nutrition.protein != null)
        '${copy.proteinLabel} ${copy.gramsValue(number(nutrition.protein!))}',
      if (!compact && nutrition.carbs != null)
        '${copy.carbsLabel} ${copy.gramsValue(number(nutrition.carbs!))}',
      if (!compact && nutrition.fat != null)
        '${copy.fatLabel} ${copy.gramsValue(number(nutrition.fat!))}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (total)
          Text(
            copy.dailyNutritionTotal,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        if (metrics.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: metrics
                .map(
                  (label) => Text(label, style: const TextStyle(fontSize: 12)),
                )
                .toList(),
          ),
        if (compact ? !nutrition.hasValues : !nutrition.complete)
          Text(
            total ? copy.nutritionTotalsIncomplete : copy.nutritionUnavailable,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class MealNutritionDetails extends StatelessWidget {
  const MealNutritionDetails({
    super.key,
    required this.meal,
    this.compact = false,
  });
  final DailyMealItem meal;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MealNutritionView(
          compact: compact,
          nutrition: MealNutrition.total([
            (nutrition: meal.nutrition, quantity: meal.quantity),
          ]),
        ),
        TextButton(
          onPressed: () => showMealDetailViewer(
            context: context,
            initialIndex: 0,
            meals: [
              GuestMeal(
                id: meal.id,
                code: '',
                name: meal.name,
                description: meal.description,
                imageUrl: meal.imageUrl,
                mealTime: GuestMealTime(
                  code: meal.category,
                  name: meal.category == 'snack'
                      ? copy.deliveriesSnack
                      : copy.deliveriesMeal,
                ),
                nutrition: GuestMealNutrition(
                  calories: meal.nutrition.calories,
                  protein: meal.nutrition.protein,
                  carbs: meal.nutrition.carbs,
                  fat: meal.nutrition.fat,
                  fiber: meal.nutrition.fiber,
                ),
                tags: const [],
                allergens: const [],
                isAvailable: true,
                displayOrder: 0,
              ),
            ],
          ),
          child: Text(copy.deliveriesViewDetails),
        ),
      ],
    );
  }
}
