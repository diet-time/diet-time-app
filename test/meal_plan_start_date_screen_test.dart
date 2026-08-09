import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_start_date_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('24 service days skip Friday and Saturday', () {
    final schedule = calculateMealPlanServiceSchedule(
      startDate: DateTime(2026, 8, 10),
      serviceDays: 24,
      nonDeliveryWeekdays: const {DateTime.friday, DateTime.saturday},
    );

    expect(schedule, isNotNull);
    expect(schedule!.serviceDates, hasLength(24));
    expect(schedule.startDate, DateTime(2026, 8, 10));
    expect(schedule.endDate, DateTime(2026, 9, 10));
    expect(
      schedule.serviceDates,
      everyElement(
        predicate<DateTime>(
          (date) =>
              date.weekday != DateTime.friday &&
              date.weekday != DateTime.saturday,
        ),
      ),
    );
  });

  test('one-off unavailable dates are skipped', () {
    final schedule = calculateMealPlanServiceSchedule(
      startDate: DateTime(2026, 8, 9),
      serviceDays: 3,
      nonDeliveryWeekdays: const {DateTime.friday, DateTime.saturday},
      unavailableDates: [DateTime(2026, 8, 10)],
    );

    expect(schedule!.serviceDates, [
      DateTime(2026, 8, 9),
      DateTime(2026, 8, 11),
      DateTime(2026, 8, 12),
    ]);
  });

  testWidgets('selection calculates fields and enables Continue', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MealPlanStartDateScreen(
            selection: _selection,
            today: DateTime(2026, 8, 8),
          ),
        ),
      ),
    );

    final continueButton = find.byKey(const ValueKey('startDateContinue'));
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: continueButton,
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('calendarDay-20260810')));
    await tester.pump();

    expect(find.text('10/08/2026'), findsOneWidget);
    expect(find.text('10/09/2026'), findsOneWidget);
    expect(
      find.text('Monthly Plan · 24 service days · 3 Meals + 1 Snack'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: continueButton,
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
  });
}

const _selection = MealPlanPurchaseSelection(
  mealPlan: MealPlanOption(
    id: 'plan-id',
    code: 'EVERYDAY',
    name: 'Everyday Choice',
  ),
  mealCombination: MealPlanConfiguration(
    id: '3-1',
    name: '3 Meals + 1 Snack',
    packages: [],
  ),
  pricingOption: MealPlanPackage(
    mealPlanPriceId: 'monthly-id',
    name: 'Monthly Plan',
    serviceDays: 24,
    totalPrice: 2800,
    dailyPrice: 116.67,
    currencyCode: 'QAR',
  ),
);
