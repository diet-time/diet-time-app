import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_details_screen.dart';
import 'package:diet_time/features/plans/presentation/subscription_selection_widgets.dart';
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

  test('selected plan always loads its own details from the API', () async {
    final repository = _RecordingMealPlanRepository();
    final container = ProviderContainer(
      overrides: [mealPlanRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    const plan = MealPlanOption(
      id: 'complete-balance-id',
      code: 'COMPLETE_BALANCE',
      name: 'Complete Balance',
      mealConfigurations: [
        MealPlanConfiguration(
          id: 'embedded',
          name: 'Embedded configuration',
          packages: [],
        ),
      ],
    );

    await container.read(
      mealPlanConfigurationsProvider((plan: plan, language: 'en')).future,
    );

    expect(repository.requestedPlanId, 'complete-balance-id');
    expect(repository.requestedLanguage, 'en');
    expect(repository.callCount, 1);
  });

  test('API configuration parser preserves package order and price IDs', () {
    final plan = MealPlanOption.fromJson(_planJson);

    expect(plan.mealConfigurations.map((item) => item.id), ['three', 'plus']);
    expect(
      plan.mealConfigurations.last.packages.map((item) => item.mealPlanPriceId),
      ['plus-week', 'plus-month'],
    );
  });

  test(
    'flat meal-plan prices with identities are grouped into configurations',
    () {
      final configurations = parseMealPlanConfigurations(const {
        'prices': [
          {
            'priceId': 'day-price',
            'durationDays': 1,
            'mealsPerDay': 3,
            'snacksPerDay': 1,
            'amount': 135.0,
            'currencyCode': 'QAR',
            'name': '1 Day Plan',
          },
          {
            'priceId': 'week-price',
            'durationDays': 6,
            'mealsPerDay': 3,
            'snacksPerDay': 1,
            'amount': 900.0,
            'currencyCode': 'QAR',
            'name': 'Weekly Plan',
          },
          {
            'priceId': 'month-price',
            'durationDays': 24,
            'mealsPerDay': 3,
            'snacksPerDay': 1,
            'amount': 2800.0,
            'currencyCode': 'QAR',
            'name': 'Monthly Plan',
          },
        ],
        'supportedMealTypes': [
          {'code': 'BREAKFAST', 'name': 'Breakfast'},
          {'code': 'LUNCH', 'name': 'Lunch'},
          {'code': 'DINNER', 'name': 'Dinner'},
          {'code': 'SNACK_DESSERT', 'name': 'Snack / Dessert'},
        ],
      }, language: 'en');

      expect(configurations, hasLength(1));
      expect(configurations.single.name, '3 Meals + 1 Snack');
      expect(
        configurations.single.description,
        '1 Breakfast · 1 Lunch · 1 Dinner · 1 Snack',
      );
      expect(configurations.single.packages.map((item) => item.name), [
        '1 Day Plan',
        'Weekly Plan',
        'Monthly Plan',
      ]);
      expect(configurations.single.packages[1].dailyPrice, 150);
      expect(
        configurations.single.packages.last.dailyPrice,
        closeTo(116.67, .01),
      );
      expect(configurations.single.packages.first.mealPlanPriceId, 'day-price');
    },
  );

  test('duration labels are never inferred from service-day counts', () {
    final configurations = parseMealPlanConfigurations(const {
      'prices': [
        {
          'durationDays': 6,
          'mealsPerDay': 3,
          'snacksPerDay': 1,
          'amount': 900.0,
          'currencyCode': 'QAR',
        },
      ],
    }, language: 'en');

    expect(configurations, isEmpty);
  });

  testWidgets('selected plan image is a cropped hero background', (
    tester,
  ) async {
    await tester.pumpWidget(_app(plan: _plan));
    await tester.pump();

    expect(find.text('Complete Balance'), findsOneWidget);
    final image = tester.widget<Image>(find.byKey(const ValueKey('heroImage')));
    expect(image.fit, BoxFit.cover);
    expect(image.fit, isNot(BoxFit.fill));
    expect(find.byKey(const ValueKey('heroImageClip')), findsOneWidget);
    expect(find.byKey(const ValueKey('detailsBackground')), findsOneWidget);
    expect(find.byKey(const ValueKey('detailsBackgroundImage')), findsNothing);
    expect(find.text('Your plan'), findsNothing);
    expect(find.byKey(const ValueKey('detailsLanguageSelector')), findsNothing);
    final description = tester.widget<Text>(
      find.text('Balanced meals, fresh ingredients and daily variety.'),
    );
    expect(description.maxLines, 3);
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
    expect(find.text('QAR 100 per delivery day'), findsOneWidget);
    expect(find.text('QAR 600'), findsOneWidget);
    await _tapChoice(tester, 'configuration-plus');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('1 Month'), findsOneWidget);

    expect(find.text('QAR 120 per delivery day'), findsOneWidget);
    expect(find.text('QAR 720'), findsOneWidget);
    expect(find.textContaining('6 delivery days'), findsWidgets);

    await _scrollTo(tester, const ValueKey('duration-plus-month'));
    await _tapChoice(tester, 'duration-plus-month');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('QAR 110 per delivery day'), findsOneWidget);
    expect(find.text('QAR 2640'), findsOneWidget);
    expect(find.textContaining('24 delivery days'), findsWidgets);
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

    await _tapChoice(tester, 'configuration-plus');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('detailsContinue')));

    expect(templateId, 'balance-id');
    expect(priceId, 'plus-week');
  });

  testWidgets('Continue opens the calendar panel over plan details', (
    tester,
  ) async {
    await tester.pumpWidget(_app(plan: _plan));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('detailsContinue')));
    await tester.pumpAndSettle();

    expect(find.byType(MealPlanDetailsScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('serviceCalendar')), findsOneWidget);
    expect(find.byKey(const ValueKey('startDateTitle')), findsNothing);
  });

  testWidgets('Continue is disabled when a displayed price has no ID', (
    tester,
  ) async {
    var continued = false;
    await tester.pumpWidget(
      _app(
        plan: const MealPlanOption(
          id: 'flat-plan',
          code: 'FLAT',
          name: 'Flat pricing plan',
          mealConfigurations: [
            MealPlanConfiguration(
              id: '3-1',
              name: '3 Meals + 1 Snack',
              packages: [
                MealPlanPackage(
                  mealPlanPriceId: '',
                  name: '1 Day',
                  serviceDays: 1,
                  totalPrice: 120,
                  dailyPrice: 120,
                  currencyCode: 'QAR',
                ),
              ],
            ),
          ],
        ),
        onContinue: (_, _) => continued = true,
      ),
    );
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('detailsContinue')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(continued, isFalse);
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

  testWidgets('hero leaves pricing to the selected subscription summary', (
    tester,
  ) async {
    const configurations = [
      MealPlanConfiguration(
        id: 'daily-meals',
        name: '3 Meals + 1 Snack',
        packages: [
          MealPlanPackage(
            mealPlanPriceId: 'month-price',
            name: '1 Month',
            serviceDays: 24,
            totalPrice: 80,
            dailyPrice: 3.33,
            currencyCode: 'QAR',
          ),
          MealPlanPackage(
            mealPlanPriceId: 'day-price',
            name: '1 Day',
            serviceDays: 1,
            totalPrice: 135,
            dailyPrice: 135,
            currencyCode: 'QAR',
          ),
        ],
      ),
    ];
    await tester.pumpWidget(
      _app(
        plan: const MealPlanOption(
          id: 'complete-balance',
          code: 'COMPLETE_BALANCE',
          name: 'Complete Balance',
          mealConfigurations: configurations,
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('From QAR'), findsNothing);
    expect(find.text('QAR 80'), findsOneWidget);
    expect(find.textContaining('3.33/day'), findsNothing);
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

  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(390, 844),
    const Size(430, 932),
    const Size(360, 800),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('selection fits $size at text scale $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(_app(plan: _plan, textScale: scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final button = find.byKey(const ValueKey('detailsContinue'));
        expect(button.hitTestable(), findsOneWidget);
        final card = find.byKey(const ValueKey('configuration-three'));
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        expect(tester.getSize(card).width, 180);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('unpriced durations are disabled without displaying a price', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        plan: const MealPlanOption(
          id: 'unavailable',
          code: 'UNAVAILABLE',
          name: 'Complete Balance',
          mealConfigurations: [
            MealPlanConfiguration(
              id: 'one',
              name: '1 Meal',
              packages: [
                MealPlanPackage(
                  mealPlanPriceId: '',
                  name: '4 Weeks',
                  serviceDays: 24,
                  totalPrice: 999,
                  dailyPrice: 41.625,
                  currencyCode: 'QAR',
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pricing unavailable'), findsOneWidget);
    expect(find.textContaining('999'), findsNothing);
    expect(find.text('Currently unavailable'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('detailsContinue')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('switching meals guides unavailable duration to a valid price', (
    tester,
  ) async {
    await tester.pumpWidget(_app(plan: _plan));
    await tester.pumpAndSettle();
    await _tapChoice(tester, 'configuration-plus');
    await tester.pumpAndSettle();
    await _tapChoice(tester, 'duration-plus-month');
    await tester.pumpAndSettle();
    expect(find.text('QAR 2640'), findsOneWidget);
    await _tapChoice(tester, 'configuration-three');
    await tester.pumpAndSettle();
    expect(find.text('QAR 600'), findsOneWidget);
    expect(find.byKey(const ValueKey('duration-plus-month')), findsNothing);
    expect(find.text('QAR 2640'), findsNothing);
  });

  testWidgets('selection transitions respect reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: PackageSelectionCard(
              name: '3 Meals + 1 Snack',
              selected: true,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(container.duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matching duration survives a change of meals and price ID', (
    tester,
  ) async {
    final configurations = (_planJson['mealConfigurations'] as List)
        .cast<Map<String, dynamic>>();
    final monthly =
        (configurations.last['packages'] as List).last as Map<String, dynamic>;
    final plan = MealPlanOption.fromJson({
      ..._planJson,
      'mealConfigurations': [
        {
          ...configurations.first,
          'packages': [
            ...(configurations.first['packages'] as List),
            {...monthly, 'mealPlanPriceId': 'three-month'},
          ],
        },
        configurations.last,
      ],
    });
    String? selectedPrice;
    await tester.pumpWidget(
      _app(plan: plan, onContinue: (_, price) => selectedPrice = price),
    );
    await tester.pumpAndSettle();
    await _tapChoice(tester, 'duration-three-month');
    await tester.pumpAndSettle();
    await _tapChoice(tester, 'configuration-plus');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('detailsContinue')));
    expect(selectedPrice, 'plus-month');
  });
}

Future<void> _tapChoice(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> _scrollTo(WidgetTester tester, ValueKey<String> key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
}

Widget _app({
  required MealPlanOption plan,
  Locale locale = const Locale('en'),
  MealPlanContinue? onContinue,
  double textScale = 1,
  Future<List<MealPlanConfiguration>> Function(
    Ref ref,
    MealPlanDetailsRequest request,
  )?
  configurationsOverride,
}) {
  return ProviderScope(
    overrides: [
      mealPlanConfigurationsProvider.overrideWith(
        configurationsOverride ??
            (ref, request) async => request.plan.mealConfigurations,
      ),
    ],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
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
      'description': '1 Breakfast · 1 Lunch · 1 Dinner',
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
      'description': '1 Breakfast · 1 Lunch · 1 Dinner · 1 Snack',
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

class _RecordingMealPlanRepository extends MealPlanRepository {
  _RecordingMealPlanRepository() : super(ApiClient());

  int callCount = 0;
  String? requestedPlanId;
  String? requestedLanguage;

  @override
  Future<List<MealPlanConfiguration>> getMealPlanConfigurations({
    required String mealPlanTemplateId,
    required String language,
  }) async {
    callCount++;
    requestedPlanId = mealPlanTemplateId;
    requestedLanguage = language;
    return const [];
  }
}
