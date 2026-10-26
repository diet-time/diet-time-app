import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/presentation/package_discount_details.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

MealPlanPackage price({double? discounted = 799}) => MealPlanPackage.fromJson({
  'priceId': 'price',
  'packageName': 'One Week',
  'serviceDays': 6,
  'currencyCode': 'QAR',
  'amount': discounted ?? 999,
  'regularPrice': 999,
  'discountedPrice': discounted,
  'effectivePrice': discounted ?? 999,
  'pricePerServiceDay': (discounted ?? 999) / 6,
});

void main() {
  test(
    'package uses the effective price and preserves regular price and savings',
    () {
      final value = price();
      expect(value.totalPrice, 799);
      expect(value.originalPrice, 999);
      expect(value.discountAmount, 200);
      expect(value.discountPercentage, 20.02);
      expect(value.isValid, isTrue);
      expect(value.hasDiscount, isTrue);
      expect(price(discounted: null).hasDiscount, isFalse);
      expect(price(discounted: null).totalPrice, 999);
      expect(price(discounted: 0).isValid, isTrue);
    },
  );

  test(
    'money quote serializes cents rather than binary arithmetic residues',
    () {
      final request = PlaceOrderRequest(
        customerProfileId: 'p',
        mealPlanTemplateId: 't',
        mealPlanPriceId: 'price',
        customerAddressId: 'a',
        deliveryTimeSlotId: 'slot',
        startDate: DateTime(2026, 10, 27),
        deliveryDays: [2],
        meals: [],
        expectedTotalAmount: 0.1 + 0.2,
        expectedRegularPrice: 1,
        expectedDiscountAmount: 0.7,
        expectedCurrencyCode: 'QAR',
      );
      expect(request.toJson()['expectedTotalAmount'], 0.3);
      expect(request.toJson()['expectedRegularPrice'], 1);
      expect(request.toJson()['expectedDiscountAmount'], 0.7);
    },
  );

  for (final locale in ['en', 'ar']) {
    testWidgets(
      'discount details support $locale with original price and savings',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(
              body: PackageDiscountDetails(
                package: price(),
                showEffectivePrice: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .toList();
        expect(
          texts.any((t) => t.contains(locale == 'ar' ? 'خصم' : 'OFF')),
          isTrue,
        );
        expect(
          texts.any((t) => t.contains(locale == 'ar' ? 'توفر' : 'You save')),
          isTrue,
        );
        expect(
          tester
              .widgetList<Text>(find.byType(Text))
              .any((t) => t.style?.decoration == TextDecoration.lineThrough),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('no discount renders no promotion labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PackageDiscountDetails(package: price(discounted: null)),
        ),
      ),
    );
    expect(find.byType(Text), findsNothing);
  });
}
