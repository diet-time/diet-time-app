import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/checkout/presentation/plan_summary_screen.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package parser defaults to delivery and honors false', () {
    expect(MealPlanPackage.fromJson({}).isDeliveryEnabled, isTrue);
    expect(
      MealPlanPackage.fromJson({'isDeliveryEnabled': false}).isDeliveryEnabled,
      isFalse,
    );
  });

  test(
    'switching packages resets invalid fulfillment and invalid submissions stop locally',
    () async {
      final orders = _Orders();
      final container = ProviderContainer(
        overrides: [
          checkoutControllerProvider.overrideWith(
            () => _Controller(_state(true)),
          ),
          ordersRepositoryProvider.overrideWithValue(orders),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(checkoutControllerProvider.notifier);
      expect(
        await controller.placeOrder(),
        isNull,
      ); // Home delivery requires address.
      expect(orders.requests, isEmpty);
      final takeaway = _state(false);
      controller.begin(takeaway.selection!, takeaway.schedule!);
      expect(
        container.read(checkoutControllerProvider).fulfillmentMethod,
        'TAKEAWAY',
      );
      expect(container.read(checkoutControllerProvider).canPlaceOrder, isFalse);
      expect(await controller.placeOrder(), isNull);
      expect(orders.requests, isEmpty);
      controller.selectBranch(_branch);
      expect(container.read(checkoutControllerProvider).canPlaceOrder, isTrue);
      controller.selectFulfillmentMethod('HOME_DELIVERY');
      expect(container.read(checkoutControllerProvider).isTakeaway, isTrue);
      final delivery = _state(true);
      controller.begin(delivery.selection!, delivery.schedule!);
      expect(container.read(checkoutControllerProvider).isTakeaway, isTrue);
      controller.selectFulfillmentMethod('HOME_DELIVERY');
      expect(container.read(checkoutControllerProvider).canPlaceOrder, isFalse);
      controller.selectFulfillmentMethod('TAKEAWAY');
      expect(await controller.placeOrder(), isNotNull);
      expect(orders.requests.single.toJson()['fulfillmentMethod'], 'TAKEAWAY');
      expect(orders.requests.single.customerAddressId, isNull);
      expect(orders.requests.single.deliveryTimeSlotId, isNull);
      expect(orders.requests.single.takeawayBranchId, _branch.id);
    },
  );

  testWidgets(
    'inline calendar and required branch survive fulfillment changes on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [
          checkoutControllerProvider.overrideWith(
            () => _Controller(
              _state(
                true,
              ).copyWith(fulfillmentMethod: 'TAKEAWAY', schedule: null),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PlanSummaryScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('placeOrder')));
      await tester.pump();
      expect(
        container.read(checkoutControllerProvider).placementError,
        'Please select a takeaway branch.',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('branch-izghawa')));
      await tester.tap(find.byKey(const ValueKey('branch-izghawa')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('checkoutStartDate')),
      );
      await tester.tap(find.byKey(const ValueKey('checkoutStartDate')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('serviceCalendar')), findsOneWidget);
      expect(find.text('Choose your start date'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('calendarDay-20261027')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirmCalendar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('serviceCalendar')), findsNothing);
      final selected = container.read(checkoutControllerProvider);
      expect(selected.schedule!.serviceDates, hasLength(9));
      expect(
        selected.schedule!.serviceDates.any(
          (d) => d.weekday == DateTime.friday,
        ),
        isFalse,
      );
      expect(selected.selectedBranch?.id, 'izghawa');
      await tester.ensureVisible(find.byKey(const ValueKey('branch-azizia')));
      await tester.tap(find.byKey(const ValueKey('branch-azizia')));
      await tester.pump();
      expect(
        container.read(checkoutControllerProvider).selectedBranch?.id,
        'azizia',
      );
      container.read(checkoutControllerProvider.notifier).selectBranch(_branch);
      expect(selected.canPlaceOrder, isTrue);
      container
          .read(checkoutControllerProvider.notifier)
          .selectFulfillmentMethod('HOME_DELIVERY');
      await tester.pump();
      expect(find.byKey(const ValueKey('branch-izghawa')), findsNothing);
      expect(
        container.read(checkoutControllerProvider).schedule,
        same(selected.schedule),
      );
      container
          .read(checkoutControllerProvider.notifier)
          .selectFulfillmentMethod('TAKEAWAY');
      await tester.pump();
      expect(
        container.read(checkoutControllerProvider).selectedBranch?.id,
        'izghawa',
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'changing package duration recalculates dates and retains the branch',
    () {
      final container = ProviderContainer(
        overrides: [
          checkoutControllerProvider.overrideWith(
            () => _Controller(_state(true).copyWith(selectedBranch: _branch)),
          ),
        ],
      );
      addTearDown(container.dispose);
      final original = container.read(checkoutControllerProvider).selection!;
      container
          .read(checkoutControllerProvider.notifier)
          .selectPackage(
            MealPlanPurchaseSelection(
              mealPlan: original.mealPlan,
              mealCombination: original.mealCombination,
              pricingOption: MealPlanPackage(
                mealPlanPriceId: 'long-price',
                name: 'Long package',
                serviceDays: 24,
                totalPrice: 2000,
                dailyPrice: 100,
                currencyCode: 'QAR',
              ),
            ),
          );
      final state = container.read(checkoutControllerProvider);
      expect(state.schedule!.serviceDates, hasLength(24));
      expect(state.schedule!.startDate, DateTime(2026, 10, 27));
      expect(state.schedule!.endDate.month, 11);
      expect(state.selectedBranch, _branch);
    },
  );

  testWidgets('takeaway-only package hides delivery and address controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkoutControllerProvider.overrideWith(
            () => _Controller(_state(false)),
          ),
        ],
        child: const MaterialApp(home: PlanSummaryScreen()),
      ),
    );
    await tester.pump();
    expect(
      find.text('This package is available for takeaway only.'),
      findsOneWidget,
    );
    expect(find.text('Takeaway'), findsOneWidget);
    expect(find.text('Home Delivery'), findsNothing);
    expect(find.text('DELIVERY ADDRESS & TIME SLOT'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const ValueKey('placeOrder')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'delivery-enabled package offers both methods and takeaway hides address',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkoutControllerProvider.overrideWith(
              () => _Controller(_state(true)),
            ),
          ],
          child: const MaterialApp(home: PlanSummaryScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('Home Delivery'), findsWidgets);
      expect(find.text('DELIVERY ADDRESS & TIME SLOT'), findsOneWidget);
      await tester.tap(find.text('Takeaway'));
      await tester.pump();
      expect(find.text('DELIVERY ADDRESS & TIME SLOT'), findsNothing);
    },
  );
}

class _Controller extends CheckoutController {
  _Controller(this.initial);
  final CheckoutState initial;
  @override
  CheckoutState build() => initial;
  @override
  Future<void> loadDeliveryTimeSlots() async {}
  @override
  Future<void> loadAddresses() async {}
  @override
  Future<void> loadBranches() async {}
}

CheckoutState _state(bool enabled) => CheckoutState(
  customerProfileId: 'profile',
  branches: const [_branch, _azizia],
  selection: MealPlanPurchaseSelection(
    mealPlan: const MealPlanOption(id: 'plan', code: 'PLAN', name: 'Plan'),
    mealCombination: const MealPlanConfiguration(
      id: 'option',
      name: 'Meals',
      packages: [],
    ),
    pricingOption: MealPlanPackage(
      mealPlanPriceId: 'price',
      name: 'Package',
      serviceDays: 9,
      totalPrice: 900,
      dailyPrice: 100,
      currencyCode: 'QAR',
      isDeliveryEnabled: enabled,
      serverNow: DateTime.utc(2026, 10, 26),
      serverReceivedAt: DateTime.now().toUtc(),
    ),
  ),
  schedule: MealPlanServiceSchedule(
    serviceDates: [DateTime(2026, 10, 27), DateTime(2026, 11, 5)],
  ),
);

class _Orders extends OrdersRepository {
  _Orders()
    : super(apiClient: ApiClient(), accessTokenProvider: () async => 'token');
  final requests = <PlaceOrderRequest>[];
  @override
  Future<OrderConfirmation> placeOrder(
    PlaceOrderRequest request,
    String idempotencyKey,
  ) async {
    requests.add(request);
    return OrderConfirmation.fromJson({
      'id': 'order',
      'orderNumber': 'ORD-1',
      'fulfillmentMethod': request.fulfillmentMethod,
    });
  }
}

const _azizia = TakeawayBranch(id: 'azizia', name: 'Diet Time – Azizia Branch');
const _branch = TakeawayBranch(
  id: 'izghawa',
  name: 'Diet Time – Izghawa Branch',
);
