import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/checkout/presentation/plan_summary_screen.dart';
import 'package:diet_time/features/checkout/presentation/order_placed_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Delivery on a legacy-disabled package keeps address, slot and plan amount in the order request',
    () async {
      final orders = _Orders();
      final address = CustomerDeliveryAddress.fromJson({
        'id': 'address',
        'addressName': 'Home',
        'addressType': 'HOME',
        'buildingNo': '1',
        'streetNo': '2',
        'zoneNo': '3',
        'area': 'Doha',
        'latitude': 25.28,
        'longitude': 51.53,
      });
      const slot = DeliveryTimeSlot(
        id: 'slot',
        name: 'Morning',
        startTime: '08:00',
        endTime: '10:00',
      );
      final state = _state(false).copyWith(
        selectedAddress: address,
        selectedAddressId: address.id,
        selectedDeliveryTimeSlot: slot,
        selectedDeliveryTimeSlotId: slot.id,
      );
      final container = ProviderContainer(
        overrides: [
          checkoutControllerProvider.overrideWith(() => _Controller(state)),
          ordersRepositoryProvider.overrideWithValue(orders),
        ],
      );
      addTearDown(container.dispose);
      expect(
        await container.read(checkoutControllerProvider.notifier).placeOrder(),
        isNotNull,
      );
      final request = orders.requests.single;
      expect(request.fulfillmentMethod, 'HOME_DELIVERY');
      expect(request.customerAddressId, address.id);
      expect(request.deliveryTimeSlotId, slot.id);
      expect(request.takeawayBranchId, isNull);
      expect(request.expectedTotalAmount, 900);
      expect(request.toJson(), isNot(contains('deliveryFee')));
      expect(request.toJson(), isNot(contains('estimatedDeliveryAmount')));
      expect(state.selection!.totalPrice, 900);
      expect(container.read(checkoutControllerProvider).selection, isNull);
    },
  );
  test('package parser defaults to delivery and honors false', () {
    expect(MealPlanPackage.fromJson({}).isDeliveryEnabled, isTrue);
    expect(
      MealPlanPackage.fromJson({'isDeliveryEnabled': false}).isDeliveryEnabled,
      isFalse,
    );
  });

  test(
    'switching packages keeps fulfillment choice and still requires delivery details or a branch',
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
        'HOME_DELIVERY',
      );
      expect(container.read(checkoutControllerProvider).canPlaceOrder, isFalse);
      expect(await controller.placeOrder(), isNull);
      expect(orders.requests, isEmpty);
      controller.selectFulfillmentMethod('TAKEAWAY');
      controller.selectBranch(_branch);
      expect(container.read(checkoutControllerProvider).canPlaceOrder, isTrue);
      controller.selectFulfillmentMethod('HOME_DELIVERY');
      expect(container.read(checkoutControllerProvider).isTakeaway, isFalse);
      final delivery = _state(true);
      controller.begin(delivery.selection!, delivery.schedule!);
      expect(container.read(checkoutControllerProvider).isTakeaway, isFalse);
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

  for (final enabled in [false, true]) {
    for (final language in ['en', 'ar']) {
      testWidgets(
        'all packages offer both methods and localized delivery notice: legacy=$enabled lang=$language',
        (tester) async {
          final initial = _state(
            enabled,
          ).copyWith(fulfillmentMethod: 'TAKEAWAY', selectedBranch: _branch);
          final container = ProviderContainer(
            overrides: [
              checkoutControllerProvider.overrideWith(
                () => _Controller(initial),
              ),
            ],
          );
          addTearDown(container.dispose);
          final copy = lookupAppLocalizations(Locale(language));
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const PlanSummaryScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final selector = find.byKey(const ValueKey('checkoutFulfillment'));
          final delivery = find.descendant(
            of: selector,
            matching: find.text(copy.customerHomeDelivery),
          );
          final takeaway = find.descendant(
            of: selector,
            matching: find.text(copy.customerTakeaway),
          );
          expect(delivery, findsOneWidget);
          expect(takeaway, findsOneWidget);
          expect(
            find.byKey(const ValueKey('deliveryInformationNotice')),
            findsNothing,
          );
          final amount = tester
              .widget<Text>(find.byKey(const ValueKey('checkoutFinalAmount')))
              .data;
          await tester.ensureVisible(delivery);
          await tester.tap(delivery);
          await tester.pump();
          expect(
            find.byKey(const ValueKey('deliveryInformationNotice')),
            findsOneWidget,
          );
          expect(find.text(copy.customerDeliveryInformation), findsOneWidget);
          expect(find.text(copy.customerDeliveryChargesNotice), findsOneWidget);
          expect(find.text(copy.customerMealPlanAmount), findsOneWidget);
          expect(
            container.read(checkoutControllerProvider).isTakeaway,
            isFalse,
          );
          expect(
            container.read(checkoutControllerProvider).selection,
            same(initial.selection),
          );
          expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('checkoutFinalAmount')))
                .data,
            amount,
          );
          await tester.ensureVisible(takeaway);
          await tester.tap(takeaway);
          await tester.pump();
          expect(
            find.byKey(const ValueKey('deliveryInformationNotice')),
            findsNothing,
          );
          expect(
            container.read(checkoutControllerProvider).selectedBranch,
            _branch,
          );
          expect(
            container.read(checkoutControllerProvider).selection!.totalPrice,
            900,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final method in ['HOME_DELIVERY', 'TAKEAWAY']) {
    for (final language in ['en', 'ar']) {
      testWidgets(
        'order confirmation notice follows fulfillment: $method $language',
        (tester) async {
          final confirmation = OrderConfirmation.fromJson({
            'id': 'order',
            'orderNumber': 'ORD-1',
            'fulfillmentMethod': method,
            'pricing': {'totalAmount': 900, 'currencyCode': 'QAR'},
          });
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                checkoutControllerProvider.overrideWith(
                  () => _Controller(
                    _state(false).copyWith(orderConfirmation: confirmation),
                  ),
                ),
              ],
              child: MaterialApp(
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const OrderPlacedScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final copy = lookupAppLocalizations(Locale(language));
          expect(
            find.byKey(const ValueKey('deliveryInformationNotice')),
            method == 'HOME_DELIVERY' ? findsOneWidget : findsNothing,
          );
          if (method == 'HOME_DELIVERY') {
            expect(
              find.text(copy.customerDeliveryChargesNotice),
              findsOneWidget,
            );
            expect(find.text(copy.customerMealPlanAmount), findsOneWidget);
          }
          expect(confirmation.pricing.totalAmount, 900);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
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
  Future<void> prepareForOrder({required String language}) async {}
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
