import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_start_date_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';

const _package = MealPlanPackage(
  mealPlanPriceId: 'price',
  name: 'Week',
  serviceDays: 6,
  totalPrice: 600,
  dailyPrice: 100,
  currencyCode: 'QAR',
);

void main() {
  test(
    'checkout rejects a next-day schedule after cutoff before sending an order',
    () async {
      final package = _ClockedPackage(DateTime.utc(2026, 10, 26, 18));
      final address = CustomerDeliveryAddress.fromJson({
        'id': 'address',
        'area': 'Doha',
      });
      const slot = DeliveryTimeSlot(
        id: 'slot',
        name: 'Morning',
        startTime: '07:00',
        endTime: '11:00',
      );
      final state = CheckoutState(
        customerProfileId: 'profile',
        selection: MealPlanPurchaseSelection(
          mealPlan: const MealPlanOption(
            id: 'plan',
            code: 'PLAN',
            name: 'Plan',
          ),
          mealCombination: const MealPlanConfiguration(
            id: 'meals',
            name: 'Meals',
            packages: [],
          ),
          pricingOption: package,
        ),
        schedule: MealPlanServiceSchedule(
          serviceDates: [DateTime(2026, 10, 27)],
        ),
        selectedAddress: address,
        selectedAddressId: address.id,
        selectedDeliveryTimeSlot: slot,
        selectedDeliveryTimeSlotId: slot.id,
      );
      final orders = _ForbiddenOrders();
      final container = ProviderContainer(
        overrides: [
          checkoutControllerProvider.overrideWith(() => _Checkout(state)),
          ordersRepositoryProvider.overrideWithValue(orders),
        ],
      );
      addTearDown(container.dispose);
      expect(
        await container.read(checkoutControllerProvider.notifier).placeOrder(),
        isNull,
      );
      expect(orders.calls, 0);
      expect(
        container.read(checkoutControllerProvider).placementError,
        serviceStartDateMessage,
      );
    },
  );
  for (final time in [
    '17:59:59',
    '18:00:00',
    '18:00:01',
    '20:59:59',
    '21:00:00',
  ]) {
    test('Qatar next-day booking boundary at UTC $time', () {
      final now = DateTime.parse('2026-10-26T${time}Z');
      final minimum = minimumDeliveryStart(_package, now: now);
      final beforeCutoff = now.isBefore(DateTime.utc(2026, 10, 26, 18));
      expect(minimum, DateTime(2026, 10, beforeCutoff ? 27 : 28));
      expect(
        eligibleDeliveryStart(DateTime(2026, 10, 27), _package, now: now),
        beforeCutoff,
      );
      expect(
        eligibleDeliveryStart(DateTime(2026, 10, 28), _package, now: now),
        isTrue,
      );
    });
  }

  test('a longer configured lead and unavailable dates still apply', () {
    final package = MealPlanPackage(
      mealPlanPriceId: 'price',
      name: 'Week',
      serviceDays: 6,
      totalPrice: 600,
      dailyPrice: 100,
      currencyCode: 'QAR',
      startDateLeadTimeDays: 3,
      unavailableDates: [DateTime(2026, 10, 29)],
    );
    final now = DateTime.utc(2026, 10, 26, 18);
    expect(minimumDeliveryStart(package, now: now), DateTime(2026, 10, 29));
    expect(
      eligibleDeliveryStart(DateTime(2026, 10, 29), package, now: now),
      isFalse,
    );
    expect(
      eligibleDeliveryStart(DateTime(2026, 10, 30), package, now: now),
      isFalse,
    ); // Friday.
  });

  test('cached availability advances past the cutoff without a reload', () {
    final package = MealPlanPackage(
      mealPlanPriceId: 'price',
      name: 'Week',
      serviceDays: 6,
      totalPrice: 600,
      dailyPrice: 100,
      currencyCode: 'QAR',
      serverNow: DateTime.utc(2026, 10, 26, 17, 59, 59),
      serverReceivedAt: DateTime.now().toUtc().subtract(
        const Duration(seconds: 3),
      ),
      earliestStartDate: DateTime(2026, 10, 27),
    );
    expect(eligibleDeliveryStart(DateTime(2026, 10, 27), package), isFalse);
    expect(minimumDeliveryStart(package), DateTime(2026, 10, 28));
  });

  testWidgets('calendar disables tomorrow at exactly 9 PM Qatar', (
    tester,
  ) async {
    final package = _ClockedPackage(DateTime.utc(2026, 10, 26, 18));
    await _openCalendar(tester, package);
    expect(
      tester
          .widget<InkWell>(find.byKey(const ValueKey('calendarDay-20261027')))
          .onTap,
      isNull,
    );
    expect(
      tester
          .widget<InkWell>(find.byKey(const ValueKey('calendarDay-20261028')))
          .onTap,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a calendar left open across 9 PM cannot confirm tomorrow', (
    tester,
  ) async {
    final package = _ClockedPackage(DateTime.utc(2026, 10, 26, 17, 59, 59));
    await _openCalendar(tester, package);
    await tester.ensureVisible(
      find.byKey(const ValueKey('calendarDay-20261027')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendarDay-20261027')));
    await tester.pump();
    package.instant = DateTime.utc(2026, 10, 26, 18);
    await tester.ensureVisible(find.byKey(const ValueKey('confirmCalendar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirmCalendar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('serviceCalendar')), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(find.byKey(const ValueKey('calendarDay-20261027')))
          .onTap,
      isNull,
    );
    expect(find.text(serviceStartDateMessage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> _openCalendar(WidgetTester tester, MealPlanPackage package) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showMealPlanStartDatePanel(
              context: context,
              selection: MealPlanPurchaseSelection(
                mealPlan: const MealPlanOption(
                  id: 'plan',
                  code: 'PLAN',
                  name: 'Plan',
                ),
                mealCombination: const MealPlanConfiguration(
                  id: 'meals',
                  name: 'Meals',
                  packages: [],
                ),
                pricingOption: package,
              ),
            ),
            child: const Text('Open calendar'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open calendar'));
  await tester.pumpAndSettle();
}

class _ClockedPackage extends MealPlanPackage {
  _ClockedPackage(this.instant)
    : super(
        mealPlanPriceId: 'price',
        name: 'Week',
        serviceDays: 6,
        totalPrice: 600,
        dailyPrice: 100,
        currencyCode: 'QAR',
      );
  DateTime instant;
  @override
  DateTime get serverNow => instant;
  @override
  DateTime get serverReceivedAt => DateTime.now().toUtc();
}

class _Checkout extends CheckoutController {
  _Checkout(this.initial);
  final CheckoutState initial;
  @override
  CheckoutState build() => initial;
}

class _ForbiddenOrders extends OrdersRepository {
  _ForbiddenOrders()
    : super(apiClient: ApiClient(), accessTokenProvider: () async => 'token');
  int calls = 0;
  @override
  Future<OrderConfirmation> placeOrder(
    PlaceOrderRequest request,
    String idempotencyKey,
  ) async {
    calls++;
    throw StateError('An order must not be sent after the cutoff');
  }
}
