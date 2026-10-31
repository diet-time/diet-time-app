import 'support/ordering_customer.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:go_router/go_router.dart';
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
  testWidgets(
    'guest can browse but tapping a plan enters authentication without storing a selection',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          mealPlansProvider.overrideWith((ref, language) async => _pricedPlans),
          otpAuthControllerProvider.overrideWith(GuestOrderingAuth.new),
        ],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: '/plans',
        routes: [
          GoRoute(path: '/plans', builder: (_, _) => const MealPlanScreen()),
          GoRoute(
            path: '/start-plan',
            builder: (_, _) => const Text('Authentication required'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MealPlanScreen), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('High Protein').hitTestable(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('High Protein'));
      await tester.pumpAndSettle();
      expect(find.text('Authentication required'), findsOneWidget);
      expect(container.read(checkoutControllerProvider).selection, isNull);
    },
  );
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

  testWidgets('selected plan is retained when returning from details', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/plans',
      routes: [
        GoRoute(path: '/plans', builder: (_, _) => const MealPlanScreen()),
        GoRoute(
          path: '/plan-details',
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                key: const ValueKey('returnToPlans'),
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: Text((state.extra as MealPlanOption).code),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        mealPlansProvider.overrideWith((ref, language) async => _pricedPlans),
        otpAuthControllerProvider.overrideWith(OrderingAuth.new),
      ],
    );
    addTearDown(container.dispose);
    prepareOrderingCustomer(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('High Protein').hitTestable(),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('High Protein'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('HIGH_PROTEIN'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('returnToPlans')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('mealPlan-HIGH_PROTEIN')),
        matching: find.byKey(const ValueKey('selected')),
      ),
      findsOneWidget,
    );
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('plan cards fit a small phone at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealPlansProvider.overrideWith(
              (ref, language) async => _pricedPlans,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (_, child) => MediaQuery(
              data: MediaQueryData(
                size: const Size(320, 568),
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: const MealPlanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('High Protein').hitTestable(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }

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

  testWidgets(
    'cards omit daily pricing and calories while retaining plan selection',
    (tester) async {
      await tester.pumpWidget(_app(plans: _pricedPlans));
      await tester.pumpAndSettle();

      expect(find.text('Classic'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('High Protein').hitTestable(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('High Protein'), findsOneWidget);
      expect(find.textContaining('kcal'), findsNothing);
      expect(find.textContaining('/ day'), findsNothing);
      expect(find.textContaining('QAR'), findsNothing);

      await tester.tap(find.text('High Protein'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('mealPlan-HIGH_PROTEIN')),
          matching: find.byKey(const ValueKey('selected')),
        ),
        findsOneWidget,
      );
    },
  );

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

    expect(find.text('Daily price unavailable'), findsNothing);
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
        findsNothing,
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
    expect(find.textContaining('QAR'), findsNothing);
    expect(find.text('Classic'), findsOneWidget);
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
}) {
  final container = ProviderContainer(
    overrides: [
      mealPlansProvider.overrideWith((ref, language) async => plans),
      otpAuthControllerProvider.overrideWith(OrderingAuth.new),
    ],
  );
  addTearDown(container.dispose);
  prepareOrderingCustomer(container);
  return UncontrolledProviderScope(
    container: container,
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
}
