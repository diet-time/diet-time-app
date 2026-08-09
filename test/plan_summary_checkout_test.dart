import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/checkout/presentation/order_placed_screen.dart';
import 'package:diet_time/features/checkout/presentation/plan_summary_screen.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Place Order stays disabled without a delivery location', (
    tester,
  ) async {
    await tester.pumpWidget(_summaryApp(_checkoutState));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('placeOrder')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(find.text('Place Order'), findsOneWidget);
    expect(button.onPressed, isNull);
  });

  testWidgets('Place Order enables after address and time selection', (
    tester,
  ) async {
    final ready = _checkoutState.copyWith(
      selectedAddressId: _address.id,
      selectedAddress: _address,
      selectedDeliveryTimeSlotId: _slot.id,
      selectedDeliveryTimeSlot: _slot,
    );
    await tester.pumpWidget(_summaryApp(ready));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('placeOrder')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('dummy order confirmation is explicit', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OrderPlacedScreen()));

    expect(find.text('Order Placed!'), findsOneWidget);
    expect(
      find.textContaining('No payment or order API was submitted'),
      findsOneWidget,
    );
  });
}

Widget _summaryApp(CheckoutState state) => ProviderScope(
  overrides: [
    checkoutControllerProvider.overrideWith(
      () => _CheckoutControllerForTest(state),
    ),
  ],
  child: const MaterialApp(home: PlanSummaryScreen()),
);

class _CheckoutControllerForTest extends CheckoutController {
  _CheckoutControllerForTest(this.initialState);
  final CheckoutState initialState;

  @override
  CheckoutState build() => initialState;

  @override
  Future<void> loadDeliveryTimeSlots() async {}
}

final _checkoutState = CheckoutState(
  selection: const MealPlanPurchaseSelection(
    mealPlan: MealPlanOption(
      id: 'plan-id',
      code: 'PLAN',
      name: 'Balanced Living',
    ),
    mealCombination: MealPlanConfiguration(
      id: 'meal-id',
      name: '3 Meals + 1 Snack',
      packages: [],
    ),
    pricingOption: MealPlanPackage(
      mealPlanPriceId: 'price-id',
      name: 'Monthly',
      serviceDays: 24,
      totalPrice: 3200,
      dailyPrice: 133.33,
      currencyCode: 'QAR',
    ),
  ),
  schedule: MealPlanServiceSchedule(
    serviceDates: [DateTime(2026, 8, 9), DateTime(2026, 9, 5)],
  ),
);

const _address = CustomerDeliveryAddress(
  id: 'address-id',
  addressName: 'Home',
  addressType: DeliveryAddressType.home,
  buildingNo: '126',
  streetNo: '960',
  zoneNo: '45',
  area: 'Doha',
  latitude: 25.28,
  longitude: 51.53,
  formattedAddress: 'Doha, Qatar',
);

const _slot = DeliveryTimeSlot(
  id: 'morning-id',
  name: 'Morning',
  startTime: '09:00',
  endTime: '11:00',
);
