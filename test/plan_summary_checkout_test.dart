import 'package:go_router/go_router.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/home/presentation/home_screen.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_screen.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/checkout/presentation/order_placed_screen.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/plan_summary_screen.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('invalid pricing disables submission and offers package review', (
    tester,
  ) async {
    await tester.pumpWidget(
      _summaryApp(
        _checkoutState.copyWith(
          configurationErrorCode: 'pricing_not_available',
          placementError:
              'Pricing is unavailable for this duration. Please review your package.',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.descendant(
      of: find.byKey(const ValueKey('placeOrder')),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(find.text('Review package'), findsOneWidget);
  });

  testWidgets('placing another order reloads a reused dashboard route', (
    tester,
  ) async {
    final calls = <String?>[];
    final ready = _checkoutState.copyWith(
      selectedAddressId: _address.id,
      selectedAddress: _address,
      selectedDeliveryTimeSlotId: _slot.id,
      selectedDeliveryTimeSlot: _slot,
    );
    final container = ProviderContainer(
      overrides: [
        checkoutControllerProvider.overrideWith(
          () => _CheckoutControllerForTest(ready),
        ),
        ordersRepositoryProvider.overrideWithValue(_SuccessfulOrders()),
        customerDashboardControllerProvider.overrideWith(
          () => _ReloadedDashboard(calls),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: const HomeScreen(),
            floatingActionButton: FloatingActionButton(
              key: const ValueKey('openCheckout'),
              onPressed: () => context.push('/summary'),
              child: const Icon(Icons.shopping_cart),
            ),
          ),
        ),
        GoRoute(
          path: '/order-placed',
          builder: (_, _) => const OrderPlacedScreen(),
        ),
        GoRoute(path: '/summary', builder: (_, _) => const PlanSummaryScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final originalDashboard = tester.state(
      find.byType(CustomerDashboardScreen),
    );
    expect(calls, hasLength(1));
    await tester.tap(find.byKey(const ValueKey('openCheckout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('placeOrder')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('orderPlacedHome')));
    await tester.pumpAndSettle();
    expect(
      tester.state(find.byType(CustomerDashboardScreen)),
      same(originalDashboard),
    );
    expect(calls.length, greaterThanOrEqualTo(2));
    expect(calls.last, 'profile-id');
    expect(
      container.read(customerDashboardControllerProvider),
      isA<DashboardNoOrders>(),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Place Order validates a missing delivery location', (
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
    expect(find.text('PLACE ORDER'), findsOneWidget);
    expect(button.onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('placeOrder')));
    await tester.pump();
    expect(find.text('Please select a delivery address.'), findsOneWidget);
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
    await tester.ensureVisible(
      find.byKey(const ValueKey('checkoutFinalAmount')),
    );
    final total = tester.widget<Text>(
      find.byKey(const ValueKey('checkoutFinalAmount')),
    );
    expect(total.data, 'QAR 3200');
    expect(total.style?.fontSize, greaterThanOrEqualTo(28));
    expect(total.style?.fontWeight, FontWeight.w800);
  });

  testWidgets(
    'new submissions show pending confirmation separately from payment',
    (tester) async {
      final pending = OrderConfirmation(
        id: _confirmation.id,
        orderNumber: _confirmation.orderNumber,
        status: 'PENDING_APPROVAL',
        paymentStatus: 'PENDING',
        plan: _confirmation.plan,
        meals: _confirmation.meals,
        delivery: _confirmation.delivery,
        pricing: _confirmation.pricing,
        placedAt: _confirmation.placedAt,
        review: const {'rowVersion': 1, 'canFulfill': false},
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkoutControllerProvider.overrideWith(
              () => _CheckoutControllerForTest(
                _checkoutState.copyWith(orderConfirmation: pending),
              ),
            ),
          ],
          child: const MaterialApp(home: OrderPlacedScreen()),
        ),
      );
      expect(find.text('Order Submitted'), findsOneWidget);
      expect(find.text('Order Confirmed!'), findsNothing);
      await tester.ensureVisible(find.text('Pending Confirmation'));
      expect(find.text('Pending Confirmation'), findsOneWidget);
      expect(find.text('Payment Pending'), findsOneWidget);
    },
  );

  test(
    'pending and held orders cannot appear active and rejection reasons remain readable',
    () {
      final pending = CustomerOrderSummary.fromJson({
        'id': '1',
        'orderNumber': 'ORD-1',
        'status': 'PENDING_APPROVAL',
        'paymentStatus': 'PAID',
        'review': {'canFulfill': false},
      });
      expect(pending.isCurrent, isFalse);
      expect(pending.statusLabel, 'Pending Confirmation');
      expect(pending.paymentLabel, 'Paid');
      final rejected = OrderConfirmation.fromJson({
        'status': 'REJECTED',
        'review': {
          'rejectionReason': 'The requested package is unavailable',
          'canFulfill': false,
        },
      });
      expect(rejected.reviewMessage, 'The requested package is unavailable');
      expect(rejected.statusLabel, 'Rejected');
    },
  );

  testWidgets('confirmation renders authoritative order response', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkoutControllerProvider.overrideWith(
            () => _CheckoutControllerForTest(
              _checkoutState.copyWith(orderConfirmation: _confirmation),
            ),
          ),
        ],
        child: const MaterialApp(home: OrderPlacedScreen()),
      ),
    );

    expect(find.text('Order Confirmed!'), findsOneWidget);
    expect(find.text('ORD-20260810-000001'), findsNothing);
    expect(find.text('1880 QAR'), findsOneWidget);
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
  Future<void> prepareForOrder({required String language}) async {}

  @override
  Future<void> loadDeliveryTimeSlots() async {}
  @override
  Future<void> loadAddresses() async {}
  @override
  Future<void> loadBranches() async {}
}

final _checkoutState = CheckoutState(
  selection: MealPlanPurchaseSelection(
    mealPlan: MealPlanOption(
      id: 'plan-id',
      code: 'PLAN',
      name: 'Balanced Living',
    ),
    mealCombination: MealPlanConfiguration(
      id: 'meal-id',
      name: '3 Meals + 1 Snack',
      packages: [],
      selectedMeals: [
        MealPlanMealSelection(mealTypeId: 'lunch-id', name: 'Lunch'),
      ],
    ),
    pricingOption: MealPlanPackage(
      mealPlanPriceId: 'price-id',
      name: 'Monthly',
      serviceDays: 24,
      totalPrice: 3200,
      dailyPrice: 133.33,
      currencyCode: 'QAR',
      serverNow: DateTime.utc(2026, 8, 7),
      serverReceivedAt: DateTime.now().toUtc(),
    ),
  ),
  schedule: MealPlanServiceSchedule(
    serviceDates: [DateTime(2026, 8, 9), DateTime(2026, 9, 5)],
  ),
  customerProfileId: 'profile-id',
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

final _confirmation = OrderConfirmation(
  id: 'order-id',
  orderNumber: 'ORD-20260810-000001',
  status: 'CONFIRMED',
  paymentStatus: 'PENDING',
  plan: const OrderPlan(
    mealPlanTemplateId: 'plan-id',
    mealPlanPriceId: 'price-id',
    name: 'Classic',
    durationName: '1 Month',
  ),
  meals: const [OrderMeal(mealTypeId: 'lunch-id', name: 'Lunch', quantity: 1)],
  delivery: OrderDelivery(
    daysPerWeek: 5,
    days: const [2, 3, 4, 5, 6],
    startDate: DateTime(2026, 8, 11),
    endDate: DateTime(2026, 9, 5),
    timeSlot: const OrderTimeSlot(
      id: 'morning-id',
      name: 'Morning',
      startTime: '09:00:00',
      endTime: '11:00:00',
    ),
    address: const OrderAddress(
      addressId: 'address-id',
      addressName: 'Home',
      addressType: 'HOME',
      buildingNo: '126',
      streetNo: '960',
      zoneNo: '91',
      area: 'Al Wakrah',
      formattedAddress: 'Zone 91, Al Wakrah, Qatar',
    ),
  ),
  pricing: const OrderPricing(
    subtotal: 1880,
    discountAmount: 0,
    deliveryCharge: 0,
    totalAmount: 1880,
    currencyCode: 'QAR',
  ),
  placedAt: DateTime.utc(2026, 8, 10, 14),
);

class _ReloadedDashboard extends CustomerDashboardController {
  _ReloadedDashboard(this.calls);
  final List<String?> calls;
  @override
  CustomerDashboardState build() => const DashboardLoading();
  @override
  Future<void> initialize({String? profileId, bool force = false}) async {
    calls.add(profileId);
    state = const DashboardNoOrders();
  }
}

class _SuccessfulOrders extends OrdersRepository {
  _SuccessfulOrders()
    : super(apiClient: ApiClient(), accessTokenProvider: () async => 'token');
  @override
  Future<OrderConfirmation> placeOrder(
    PlaceOrderRequest request,
    String idempotencyKey,
  ) async => _confirmation;
}
