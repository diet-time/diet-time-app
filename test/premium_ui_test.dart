import 'package:diet_time/core/widgets/bmi_overview.dart';
import 'package:diet_time/features/dashboard/presentation/service_date_cell.dart';
import 'package:diet_time/features/plans/domain/meal_entitlement.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'meal quantities aggregate across regular slots with correct plurals',
    () {
      expect(
        MealEntitlement.fromRows([
          (name: 'Meal 1', quantity: 1),
          (name: 'Meal 2', quantity: 2),
          (name: 'Snack', quantity: 1),
        ]).label(),
        '3 Meals + 1 Snack',
      );
      expect(const MealEntitlement(1, 0).label(), '1 Meal');
      expect(const MealEntitlement(1, 2).label(), '1 Meal + 2 Snacks');
      expect(
        MealEntitlement.fromRows([
          (name: 'وجبة خفيفة', quantity: 1),
          (name: 'وجبة', quantity: 2),
        ]).label(),
        '2 Meals + 1 Snack',
      );
      final order = OrderConfirmation.fromJson({
        'mealCount': 3,
        'snackCount': 1,
        'meals': [
          {'name': 'Localized label', 'quantity': 4},
        ],
      });
      expect(order.entitlement.label(), '3 Meals + 1 Snack');
    },
  );

  for (final value in [12.0, 14.0, 18.5, 25.0, 30.0, 45.0]) {
    testWidgets('BMI marker uses the same linear scale for value $value', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BmiOverview(
                bmi: value,
                age: 30,
                category: 'Configured category',
              ),
            ),
          ),
        ),
      );
      final bar = tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('bmiRange')),
          matching: find.byType(Stack),
        ),
      );
      final dot = tester.getRect(
        find.byKey(const ValueKey('bmiScaleIndicatorDot')),
      );
      expect(
        dot.center.dx,
        closeTo(
          bar.left + 12 + BmiOverview.position(value) * (bar.width - 24),
          .01,
        ),
      );
      expect(find.text('Configured category'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final age in [null, 12]) {
    testWidgets('no adult interpretation without adult age: $age', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BmiOverview(bmi: 24, age: age, category: 'Adult category'),
        ),
      );
      expect(find.byKey(const ValueKey('bmiScaleMarker')), findsNothing);
      expect(find.text('Adult category'), findsNothing);
      expect(
        find.textContaining(
          age == null ? 'date of birth' : 'age- and sex-specific',
        ),
        findsOneWidget,
      );
    });
  }
  testWidgets('unavailable BMI has no invented value or marker', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: BmiOverview(bmi: null, age: 30, category: '')),
    );
    expect(find.text('Not available yet'), findsOneWidget);
    expect(find.text('0.0'), findsNothing);
    expect(find.byKey(const ValueKey('bmiScaleMarker')), findsNothing);
  });
  for (final language in ['en', 'ar']) {
    testWidgets('wellness fits a narrow screen with large $language text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: BmiOverview(bmi: 24.2, age: 30, category: 'Within range'),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final count in [2, 12, 123]) {
    testWidgets('calendar count $count never overlaps its date', (
      tester,
    ) async {
      final date = DateTime(2026, 10, 31);
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 42,
              height: 90,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: ServiceDateCell(
                  date: date,
                  service: true,
                  selected: true,
                  count: count,
                  status: 'mixed',
                  label: '$count scheduled orders',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      final day = tester.getRect(
        find.byKey(ValueKey('dateNumber-${date.toIso8601String()}')),
      );
      final badge = tester.getRect(
        find.byKey(ValueKey('deliveryCount-${date.toIso8601String()}')),
      );
      expect(day.overlaps(badge), isFalse);
      expect(find.byType(Badge), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
