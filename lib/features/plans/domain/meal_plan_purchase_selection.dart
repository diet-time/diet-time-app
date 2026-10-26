import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';

class MealPlanPurchaseSelection {
  const MealPlanPurchaseSelection({
    required this.mealPlan,
    required this.mealCombination,
    required this.pricingOption,
    this.deliveryDaysPerWeek,
    this.selectedWeekdays,
  });

  final MealPlanOption mealPlan;
  final MealPlanConfiguration mealCombination;
  final MealPlanPackage pricingOption;
  final int? deliveryDaysPerWeek;
  final Set<int>? selectedWeekdays;

  int get serviceDays => pricingOption.serviceDays;
  double get totalPrice => pricingOption.totalPrice;
  Set<int> get deliveryWeekdays =>
      selectedWeekdays ??
      {
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          if (day != DateTime.friday &&
              !pricingOption.nonDeliveryWeekdays.contains(day))
            day,
      };
  int get deliveriesPerWeek => deliveryDaysPerWeek ?? deliveryWeekdays.length;
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
  for (
    var attempts = 0;
    dates.length < serviceDays && attempts < maximumIterations;
    attempts++
  ) {
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

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int dateKey(DateTime value) =>
    value.year * 10000 + value.month * 100 + value.day;

// Qatar uses UTC+03 throughout the year. Advance a server clock from receipt
// so a selection made across midnight must be reviewed again.
DateTime qatarToday({DateTime? now, MealPlanPackage? package}) {
  var instant = now?.toUtc() ?? DateTime.now().toUtc();
  if (now == null &&
      package?.serverNow != null &&
      package?.serverReceivedAt != null) {
    final elapsed = instant.difference(package!.serverReceivedAt!);
    instant = package.serverNow!.toUtc().add(
      elapsed.isNegative ? Duration.zero : elapsed,
    );
  }
  return dateOnly(instant.add(const Duration(hours: 3)));
}

DateTime minimumDeliveryStart(MealPlanPackage package, {DateTime? today}) {
  final current = today == null
      ? qatarToday(package: package)
      : dateOnly(today);
  final lead = current.add(
    Duration(
      days: package.startDateLeadTimeDays < 1
          ? 1
          : package.startDateLeadTimeDays,
    ),
  );
  final configured = package.earliestStartDate;
  return configured != null && dateOnly(configured).isAfter(lead)
      ? dateOnly(configured)
      : lead;
}

bool eligibleDeliveryStart(
  DateTime date,
  MealPlanPackage package, {
  DateTime? today,
}) =>
    !dateOnly(date).isBefore(minimumDeliveryStart(package, today: today)) &&
    date.weekday != DateTime.friday &&
    !package.nonDeliveryWeekdays.contains(date.weekday) &&
    !package.unavailableDates.any((day) => dateKey(day) == dateKey(date));
