import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('meal selection shows a working back button when pushed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealPlansProvider.overrideWith((ref, language) async => _pricedPlans),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  key: const ValueKey('openMealPlans'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MealPlanScreen(),
                    ),
                  ),
                  child: const Text('Open plans'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('openMealPlans')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mealPlanBackButton')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mealPlanBackButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('openMealPlans')), findsOneWidget);
  });

  test('one-day package amount is used directly', () {
    final plan = _planFromPrice(
      startingPrice: 55,
      durationDays: 1,
      currency: 'BHD',
    );

    expect(plan.dailyPrice, 55);
    expect(plan.currencyCode, 'BHD');
    expect(plan.hasActivePrice, isTrue);
  });

  test('six service-day package is divided by six and never seven', () {
    final plan = _planFromPrice(
      startingPrice: 300,
      durationDays: 6,
      currency: 'QAR',
    );

    expect(plan.dailyPrice, 50);
    expect(plan.dailyPrice, isNot(closeTo(300 / 7, .001)));
    expect(plan.sourceDurationDays, 6);
  });

  test('API-provided daily price is preferred over local calculation', () {
    final plan = MealPlanOption.fromJson(const {
      'id': 'plan-id',
      'code': 'CLASSIC',
      'name': 'Classic',
      'startingPrice': 300,
      'priceDurationDays': 6,
      'displayDailyPrice': 49.25,
      'currencyCode': 'QAR',
      'hasActivePrice': true,
      'pricingRecordId': 'price-id',
      'sourcePackageCode': 'WEEKLY',
      'sourceDurationDays': 6,
    });

    expect(plan.dailyPrice, 49.25);
    expect(plan.pricingRecordId, 'price-id');
    expect(plan.sourcePackageCode, 'WEEKLY');
    expect(plan.sourceDurationDays, 6);
  });

  test('daily price formatting preserves currency-friendly precision', () {
    expect(formatMealPlanPriceAmount(50, 'en'), '50');
    expect(formatMealPlanPriceAmount(41.6667, 'en'), '41.67');
    expect(formatMealPlanPriceAmount(41.5, 'en'), '41.50');
  });

  testWidgets('cards show API currency and daily price and still select', (
    tester,
  ) async {
    await tester.pumpWidget(_app(plans: _pricedPlans));
    await tester.pumpAndSettle();

    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('High Protein'), findsOneWidget);
    expect(find.text('1840 kcal / day'), findsOneWidget);
    expect(find.text('QAR 50 / day'), findsOneWidget);
    expect(find.text('BHD 41.50 / day'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mealPlan-HIGH_PROTEIN')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('mealPlan-HIGH_PROTEIN')),
        matching: find.byKey(const ValueKey('selected')),
      ),
      findsOneWidget,
    );
    final priceText = tester.widget<Text>(find.text('BHD 41.50 / day'));
    expect(priceText.style?.color, AppColors.emeraldGreen);
  });

  testWidgets('unavailable pricing is muted and never displays zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        plans: const [
          MealPlanOption(
            id: 'no-price-id',
            code: 'NO_PRICE',
            name: 'No Price Plan',
            dailyCaloriesKcal: 1600,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daily price unavailable'), findsOneWidget);
    expect(find.textContaining('0 / day'), findsNothing);
    expect(find.text('No Price Plan'), findsOneWidget);
  });

  testWidgets(
    'price loading keeps plan cards visible with a compact skeleton',
    (tester) async {
      await tester.pumpWidget(
        _app(
          plans: const [
            MealPlanOption(
              id: 'loading-id',
              code: 'LOADING',
              name: 'Visible Plan',
              dailyCaloriesKcal: 1700,
              isPriceLoading: true,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visible Plan'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mealPlanPriceLoading-LOADING')),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('Arabic pricing stays localized, RTL, and numerically readable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(plans: _pricedPlans.take(1).toList(), locale: const Locale('ar')),
    );
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(MealPlanScreen))),
      TextDirection.rtl,
    );
    final price = find.byKey(const ValueKey('mealPlanDailyPrice-CLASSIC'));
    final priceText = tester.widget<Text>(
      find.descendant(of: price, matching: find.byType(Text)),
    );
    expect(priceText.data, contains('QAR'));
    expect(priceText.data, contains('/ يوم'));
    expect(priceText.textDirection, TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });
}

MealPlanOption _planFromPrice({
  required double startingPrice,
  required int durationDays,
  required String currency,
}) => MealPlanOption.fromJson({
  'id': 'plan-id',
  'code': 'CLASSIC',
  'name': 'Classic',
  'startingPrice': startingPrice,
  'priceDurationDays': durationDays,
  'currencyCode': currency,
});

const _pricedPlans = [
  MealPlanOption(
    id: 'classic-id',
    code: 'CLASSIC',
    name: 'Classic',
    description: 'Everyday balanced meals.',
    dailyCaloriesKcal: 1840,
    startingPrice: 300,
    currencyCode: 'QAR',
    priceDurationDays: 6,
    dailyPrice: 50,
    hasActivePrice: true,
    pricingRecordId: 'classic-price-id',
    sourceDurationDays: 6,
  ),
  MealPlanOption(
    id: 'protein-id',
    code: 'HIGH_PROTEIN',
    name: 'High Protein',
    description: 'Protein-forward meals.',
    dailyCaloriesKcal: 2210,
    startingPrice: 249,
    currencyCode: 'BHD',
    priceDurationDays: 6,
    dailyPrice: 41.5,
    hasActivePrice: true,
    pricingRecordId: 'protein-price-id',
    sourceDurationDays: 6,
  ),
];

Widget _app({
  required List<MealPlanOption> plans,
  Locale locale = const Locale('en'),
}) => ProviderScope(
  overrides: [mealPlansProvider.overrideWith((ref, language) async => plans)],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: const MealPlanScreen(),
  ),
);
