import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_details_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'repository uses exact plan ID and preserves package identity and API prices',
    () async {
      final client = _Client(_response());
      final options = await MealPlanRepository(client)
          .getMealPlanConfigurations(
            mealPlanTemplateId: 'live-plan',
            language: 'en',
          );
      expect(
        client.path,
        '/api/v1/customer/meal-plans/live-plan/purchase-options',
      );
      expect(options.first.id, 'package-3');
      expect(options.first.name, 'Three meals and a snack');
      expect(options.first.packages.first.mealPlanPriceId, 'week-price');
      expect(options.first.packages.first.totalPrice, 715);
      expect(options.first.packages.first.dailyPrice, 119.17);
      expect(options.first.selectedMeals, hasLength(4));
    },
  );

  test(
    'a response for a different plan cannot be used as its pricing',
    () async {
      final client = _Client(_response());
      await expectLater(
        MealPlanRepository(client).getMealPlanConfigurations(
          mealPlanTemplateId: 'another-plan',
          language: 'en',
        ),
        throwsA(isA<ApiException>()),
      );
    },
  );

  test(
    'thirteen returned combinations are retained without inventing prices',
    () {
      final response = _response();
      response['mealConfigurations'] = [
        for (var meals = 1; meals <= 5; meals++)
          {
            'packageOptionId': 'package-$meals',
            'packageOptionName': '$meals meals',
            'mealsPerDay': meals,
            'snacksPerDay': 1,
            'packages': [
              for (final days in [6, 12, 24])
                if (meals < 5 || days == 6)
                  {
                    'priceId': '$meals-$days',
                    'durationId': 'D$days',
                    'durationName': '$days delivery days',
                    'serviceDays': days,
                    'amount': meals * 100 + days,
                    'pricePerServiceDay': 25.5,
                    'currencyCode': 'QAR',
                    'isActive': true,
                    'isAvailable': true,
                  },
            ],
          },
      ];
      final options = parseMealPlanConfigurations(response, language: 'en');
      final prices = options.expand((option) => option.packages).toList();
      expect(prices, hasLength(13));
      expect(prices.last.mealPlanPriceId, '5-6');
      expect(prices.last.totalPrice, 506);
      expect(
        prices.last.dailyPrice,
        25.5,
      ); // The server's display equivalent is authoritative.
    },
  );

  test(
    'inactive, unavailable and unidentified price rows cannot be selected',
    () {
      final response = _response();
      final configs = response['mealConfigurations'] as List;
      final packages =
          (configs.first as Map<String, dynamic>)['packages'] as List;
      final valid = packages.first as Map<String, dynamic>;
      (configs.first
          as Map<String, dynamic>)['packages'] = <Map<String, dynamic>>[
        ...packages.cast<Map<String, dynamic>>(),
        {...valid, 'priceId': 'inactive', 'isActive': false},
        {...valid, 'priceId': 'unavailable', 'isAvailable': false},
        {...valid, 'priceId': ''},
        {...valid, 'priceId': 'free', 'amount': 0},
      ];
      expect(
        parseMealPlanConfigurations(response, language: 'en').single.packages,
        hasLength(1),
      );
    },
  );

  testWidgets(
    'API package and duration show configured total and continue with exact price ID',
    (tester) async {
      final client = _Client(_response());
      String? chosenPlan;
      String? chosenPrice;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealPlanRepositoryProvider.overrideWithValue(
              MealPlanRepository(client),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MealPlanDetailsScreen(
              plan: const MealPlanOption(
                id: 'live-plan',
                code: 'BALANCE',
                name: 'Complete Balance',
              ),
              onContinue: (plan, price) {
                chosenPlan = plan;
                chosenPrice = price;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Choose your meals'), findsOneWidget);
      expect(find.text('Three meals and a snack'), findsWidgets);
      expect(find.byKey(const ValueKey('duration-week-price')), findsOneWidget);
      expect(find.text('QAR 715'), findsOneWidget);
      expect(find.text('Daily price unavailable'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('detailsContinue')));
      expect(chosenPlan, 'live-plan');
      expect(chosenPrice, 'week-price');
    },
  );
}

Map<String, dynamic> _response() => {
  'plan': {'id': 'live-plan', 'code': 'BALANCE', 'name': 'Complete Balance'},
  'supportedMealTypes': [
    for (final code in ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'])
      {'id': code, 'code': code, 'name': code},
  ],
  'mealConfigurations': [
    {
      'packageOptionId': 'package-3',
      'packageOptionName': 'Three meals and a snack',
      'mealsPerDay': 3,
      'snacksPerDay': 1,
      'includedText': '3 meals + 1 snack per delivery day',
      'packages': [
        {
          'priceId': 'week-price',
          'mealPlanId': 'live-plan',
          'packageOptionId': 'package-3',
          'durationId': 'WEEK',
          'durationName': 'One Week',
          'serviceDays': 6,
          'amount': 715,
          'currencyCode': 'QAR',
          'pricePerServiceDay': 119.17,
          'isActive': true,
          'isAvailable': true,
        },
      ],
    },
  ],
};

class _Client extends ApiClient {
  _Client(this.data);
  final Map<String, dynamic> data;
  String? path;
  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    this.path = path;
    return ApiResponse(statusCode: 200, body: {'data': data});
  }
}
