import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';

class MealPlanPurchaseSelection {
  const MealPlanPurchaseSelection({
    required this.mealPlan,
    required this.mealCombination,
    required this.pricingOption,
  });

  final MealPlanOption mealPlan;
  final MealPlanConfiguration mealCombination;
  final MealPlanPackage pricingOption;

  int get serviceDays => pricingOption.serviceDays;
  double get totalPrice => pricingOption.totalPrice;
}

class MealPlanServiceSchedule {
  const MealPlanServiceSchedule({required this.serviceDates});

  final List<DateTime> serviceDates;

  DateTime get startDate => serviceDates.first;
  DateTime get endDate => serviceDates.last;
}

MealPlanServiceSchedule? calculateMealPlanServiceSchedule({
  required DateTime startDate,
  required int serviceDays,
  required Set<int> nonDeliveryWeekdays,
  Iterable<DateTime> unavailableDates = const [],
}) {
  if (serviceDays <= 0) return null;
  final start = dateOnly(startDate);
  final unavailable = unavailableDates.map(dateKey).toSet();
  if (nonDeliveryWeekdays.contains(start.weekday) ||
      unavailable.contains(dateKey(start))) {
    return null;
  }

  final dates = <DateTime>[];
  var candidate = start;
  // The upper bound prevents malformed configuration from causing an endless
  // loop (for example, all seven weekdays marked as unavailable).
  final maximumIterations = serviceDays * 14 + 366;
  for (var attempts = 0;
      dates.length < serviceDays && attempts < maximumIterations;
      attempts++) {
    if (!nonDeliveryWeekdays.contains(candidate.weekday) &&
        !unavailable.contains(dateKey(candidate))) {
      dates.add(candidate);
    }
    candidate = candidate.add(const Duration(days: 1));
  }
  return dates.length == serviceDays
      ? MealPlanServiceSchedule(serviceDates: List.unmodifiable(dates))
      : null;
}

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

int dateKey(DateTime value) => value.year * 10000 + value.month * 100 + value.day;
