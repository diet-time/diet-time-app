import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_details_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meal plan details use the meal-plans endpoint', () {
    expect(
      ApiEndpoints.mealPlanDetails('6b5b71bd-baf7-46b6-abf0-2bc457a5ab6d'),
      '/api/v1/meal-plans/6b5b71bd-baf7-46b6-abf0-2bc457a5ab6d',
    );
  });

  test('API configuration parser preserves package order and price IDs', () {
    final plan = MealPlanOption.fromJson(_planJson);

    expect(plan.mealConfigurations.map((item) => item.id), ['three', 'plus']);
    expect(
      plan.mealConfigurations.last.packages.map((item) => item.mealPlanPriceId),
      ['plus-week', 'plus-month'],
    );
  });

  testWidgets('selected plan hero uses a constrained, non-stretched image', (
    tester,
  ) async {
    await tester.pumpWidget(_app(plan: _plan));
    await tester.pump();

    expect(find.text('Complete Balance'), findsOneWidget);
    final image = tester.widget<Image>(find.byKey(const ValueKey('heroImage')));
    expect(image.fit, BoxFit.cover);
    expect(image.fit, isNot(BoxFit.fill));
    expect(image.width, 220);
    expect(image.height, 192);
    expect(find.byKey(const ValueKey('heroImageClip')), findsOneWidget);
    expect(find.textContaining('RECOMMENDED'), findsNothing);
    expect(find.textContaining('Recommended'), findsNothing);
  });

  testWidgets('only API configurations and durations are rendered', (
    tester,
  ) async {
    await tester.pumpWidget(_app(plan: _plan));
    await tester.pump();

    expect(find.text('3 Meals'), findsWidgets);
    expect(find.text('3 Meals + 1 Snack'), findsOneWidget);
    expect(find.text('2 Meals'), findsNothing);
    expect(find.text('1 Week'), findsOneWidget);
    expect(find.text('1 Month'), findsNothing);
  });

  testWidgets('configuration changes durations and prices locally', (
    tester,
  ) async {
    await tester.pumpWidget(_app(plan: _plan));
    await tester.pump();
    expect(find.text('QAR 100 / day'), findsOneWidget);
    expect(find.text('QAR 600'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('configuration-plus')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('1 Month'), findsOneWidget);

    await _scrollTo(tester, const ValueKey('priceSummary'));
    expect(find.text('QAR 120 / day'), findsOneWidget);
    expect(find.text('QAR 720'), findsOneWidget);
    expect(find.textContaining('6 service days'), findsWidgets);

    await _scrollTo(tester, const ValueKey('duration-plus-month'));
    await tester.tap(find.byKey(const ValueKey('duration-plus-month')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('QAR 110 / day'), findsOneWidget);
    expect(find.text('QAR 2640'), findsOneWidget);
    expect(find.textContaining('24 service days'), findsWidgets);
  });

  testWidgets('Continue sends template ID and authoritative price ID', (
    tester,
  ) async {
    String? templateId;
    String? priceId;
    await tester.pumpWidget(
      _app(
        plan: _plan,
        onContinue: (template, price) {
          templateId = template;
          priceId = price;
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('configuration-plus')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('detailsContinue')));

    expect(templateId, 'balance-id');
    expect(priceId, 'plus-week');
  });

  testWidgets('empty pricing offers navigation back and disables checkout', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        plan: const MealPlanOption(
          id: 'empty',
          code: 'EMPTY',
          name: 'Empty plan',
          mealConfigurations: [],
        ),
        configurationsOverride: (ref, request) async => const [],
      ),
    );
    await tester.pump();

    expect(
      find.text('No packages are currently available for this meal plan.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('chooseAnotherPlan')), findsOneWidget);
    expect(find.byKey(const ValueKey('detailsContinue')), findsNothing);
  });

  testWidgets('pricing failure keeps hero visible with Retry', (tester) async {
    await tester.pumpWidget(
      _app(
        plan: const MealPlanOption(
          id: 'error-id',
          code: 'ERROR',
          name: 'Visible plan',
          description: 'The hero stays visible.',
          dailyCaloriesKcal: 1650,
        ),
        configurationsOverride: (ref, request) async => throw Exception('down'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('planHero')), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -280));
    await tester.pump();
    expect(find.text('Pricing is temporarily unavailable.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('retryPricing'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('detailsContinue')), findsNothing);
  });

  testWidgets('Arabic uses RTL while retaining the same image URL', (
    tester,
  ) async {
    await tester.pumpWidget(_app(plan: _plan, locale: const Locale('ar')));
    await tester.pump();

    expect(
      Directionality.of(tester.element(find.byType(MealPlanDetailsScreen))),
      TextDirection.rtl,
    );
    final image = tester.widget<Image>(find.byKey(const ValueKey('heroImage')));
    expect(
      (image.image as NetworkImage).url,
      'https://example.com/meal-wide.jpg',
    );
    expect(find.text('اختر وجباتك اليومية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _scrollTo(WidgetTester tester, ValueKey<String> key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

Widget _app({
  required MealPlanOption plan,
  Locale locale = const Locale('en'),
  MealPlanContinue? onContinue,
  Future<List<MealPlanConfiguration>> Function(
    Ref ref,
    MealPlanDetailsRequest request,
  )?
  configurationsOverride,
}) {
  return ProviderScope(
    overrides: [
      if (configurationsOverride != null)
        mealPlanConfigurationsProvider.overrideWith(configurationsOverride),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MealPlanDetailsScreen(plan: plan, onContinue: onContinue),
    ),
  );
}

final _plan = MealPlanOption.fromJson(_planJson);

const _planJson = <String, dynamic>{
  'id': 'balance-id',
  'code': 'BALANCE',
  'name': 'Complete Balance',
  'description': 'Balanced meals, fresh ingredients and daily variety.',
  'imageUrl': 'https://example.com/meal-wide.jpg',
  'dailyCaloriesKcal': 1650,
  'mealConfigurations': [
    {
      'id': 'three',
      'name': '3 Meals',
      'description': 'Breakfast · Lunch · Dinner',
      'packages': [
        {
          'mealPlanPriceId': 'three-week',
          'name': '1 Week',
          'serviceDays': 6,
          'totalPrice': 600,
          'dailyPrice': 100,
          'currencyCode': 'QAR',
        },
      ],
    },
    {
      'id': 'plus',
      'name': '3 Meals + 1 Snack',
      'description': 'Breakfast · Lunch · Dinner · 1 Snack',
      'packages': [
        {
          'mealPlanPriceId': 'plus-week',
          'name': '1 Week',
          'serviceDays': 6,
          'totalPrice': 720,
          'dailyPrice': 120,
          'currencyCode': 'QAR',
        },
        {
          'mealPlanPriceId': 'plus-month',
          'name': '1 Month',
          'serviceDays': 24,
          'totalPrice': 2640,
          'dailyPrice': 110,
          'currencyCode': 'QAR',
        },
      ],
    },
  ],
};
