import 'dart:async';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'purchase response keeps plan, package, duration and price identities separate',
    () {
      final price = MealPlanPackage.fromJson({
        'priceId': 'price-id',
        'mealPlanId': 'plan-id',
        'packageOptionId': 'package-id',
        'packageCode': 'SIX',
        'serviceDays': 6,
        'amount': 699,
        'currencyCode': 'QAR',
        'packageName': '6 service days',
      });
      expect(price.mealPlanTemplateId, 'plan-id');
      expect(price.packageOptionId, 'package-id');
      expect(price.packageCode, 'SIX');
      expect(price.mealPlanPriceId, 'price-id');
    },
  );

  test(
    'populated pricing is revalidated without changing unrelated selections',
    () async {
      final pricing = _AvailabilityPricing();
      final container = ProviderContainer(
        overrides: [
          checkoutControllerProvider.overrideWith(
            () => _CheckoutControllerForTest(_readyCheckout),
          ),
          mealPlanRepositoryProvider.overrideWithValue(pricing),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(checkoutControllerProvider.notifier);
      final pending = controller.prepareForOrder(language: 'en');
      expect(container.read(checkoutControllerProvider).canPlaceOrder, isFalse);
      pricing.pending[0].complete([
        _availabilityConfiguration(_readyCheckout.selection!),
      ]);
      await pending;
      final state = container.read(checkoutControllerProvider);
      expect(pricing.planIds, ['plan-id']);
      expect(state.mealPlanPriceId, 'price-id');
      expect(state.selectedAddress, same(_readyCheckout.selectedAddress));
      expect(state.customerProfileId, _readyCheckout.customerProfileId);
      expect(state.schedule, same(_readyCheckout.schedule));
      expect(state.canPlaceOrder, isTrue);
      final returning = controller.prepareForOrder(language: 'en');
      pricing.pending[1].complete([
        _availabilityConfiguration(state.selection!),
      ]);
      await returning;
      expect(
        container.read(checkoutControllerProvider).configurationErrorCode,
        isNull,
      );
    },
  );
  for (final switchPlan in [true, false]) {
    test(
      'late configuration response cannot overwrite a newer ${switchPlan ? 'plan' : 'package'}',
      () async {
        final pricing = _AvailabilityPricing();
        final container = ProviderContainer(
          overrides: [
            checkoutControllerProvider.overrideWith(
              () => _CheckoutControllerForTest(_readyCheckout),
            ),
            mealPlanRepositoryProvider.overrideWithValue(pricing),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(checkoutControllerProvider.notifier);
        final previous = controller.prepareForOrder(language: 'en');
        final next = MealPlanPurchaseSelection(
          mealPlan: switchPlan
              ? const MealPlanOption(
                  id: 'second-plan',
                  code: 'SECOND',
                  name: 'Different display name',
                )
              : _readyCheckout.selection!.mealPlan,
          mealCombination: const MealPlanConfiguration(
            id: 'second-package',
            name: 'Different label',
            packages: [],
          ),
          pricingOption: const MealPlanPackage(
            mealPlanPriceId: 'second-price',
            name: 'Same duration',
            serviceDays: 20,
            totalPrice: 700,
            dailyPrice: 35,
            currencyCode: 'QAR',
          ),
        );
        controller.selectPackage(next);
        final current = controller.prepareForOrder(language: 'en');
        pricing.pending[1].complete([_availabilityConfiguration(next)]);
        await current;
        pricing.pending[0].complete([
          _availabilityConfiguration(_readyCheckout.selection!),
        ]);
        await previous;
        final state = container.read(checkoutControllerProvider);
        expect(state.mealPlanTemplateId, next.mealPlan.id);
        expect(state.mealPlanPriceId, 'second-price');
        expect(state.selectedAddress, same(_readyCheckout.selectedAddress));
        expect(state.configurationErrorCode, isNull);
        expect(state.isResolvingOrderOptions, isFalse);
      },
    );
  }
  for (final code in ['database_conflict', 'concurrency_conflict', null]) {
    test(
      'unrelated conflict $code is not reported as an unavailable plan',
      () async {
        final orders = _RejectedOrders(code);
        final container = ProviderContainer(
          overrides: [
            checkoutControllerProvider.overrideWith(
              () => _CheckoutControllerForTest(_readyCheckout),
            ),
            ordersRepositoryProvider.overrideWithValue(orders),
          ],
        );
        addTearDown(container.dispose);
        await container.read(checkoutControllerProvider.notifier).placeOrder();
        final state = container.read(checkoutControllerProvider);
        expect(state.placementError, contains('could not be saved'));
        expect(
          state.placementError,
          isNot(contains('plan is no longer available')),
        );
        expect(state.configurationErrorCode, isNull);
      },
    );
  }
  test(
    'invalid pricing blocks repeated submission until successful revalidation',
    () async {
      final orders = _RejectedOrders('pricing_not_available'),
          pricing = _AvailabilityPricing();
      final container = ProviderContainer(
        overrides: [
          checkoutControllerProvider.overrideWith(
            () => _CheckoutControllerForTest(_readyCheckout),
          ),
          ordersRepositoryProvider.overrideWithValue(orders),
          mealPlanRepositoryProvider.overrideWithValue(pricing),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(checkoutControllerProvider.notifier);
      await controller.placeOrder();
      expect(container.read(checkoutControllerProvider).canPlaceOrder, isFalse);
      await controller.placeOrder();
      expect(orders.calls, 1);
      final retry = controller.prepareForOrder(language: 'en');
      pricing.pending.single.complete([
        _availabilityConfiguration(_readyCheckout.selection!),
      ]);
      await retry;
      expect(container.read(checkoutControllerProvider).canPlaceOrder, isTrue);
    },
  );
  test('foreign plan identity in a returned price is rejected', () async {
    final pricing = _AvailabilityPricing();
    final container = ProviderContainer(
      overrides: [
        checkoutControllerProvider.overrideWith(
          () => _CheckoutControllerForTest(_readyCheckout),
        ),
        mealPlanRepositoryProvider.overrideWithValue(pricing),
      ],
    );
    addTearDown(container.dispose);
    final request = container
        .read(checkoutControllerProvider.notifier)
        .prepareForOrder(language: 'en');
    final original = _readyCheckout.selection!;
    pricing.pending.single.complete([
      MealPlanConfiguration(
        id: original.mealCombination.id,
        name: 'Package',
        packages: [
          MealPlanPackage(
            mealPlanPriceId: original.pricingOption.mealPlanPriceId,
            mealPlanTemplateId: 'foreign-plan',
            packageOptionId: original.mealCombination.id,
            name: 'Duration',
            serviceDays: 20,
            totalPrice: 100,
            dailyPrice: 5,
            currencyCode: 'QAR',
          ),
        ],
      ),
    ]);
    await request;
    expect(
      container.read(checkoutControllerProvider).configurationErrorCode,
      'invalid_plan_configuration',
    );
  });

  test(
    'changed pricing refreshes the summary and requires a second customer submission',
    () async {
      final orders = _ChangedPriceOrders();
      final container = ProviderContainer(
        overrides: [
          checkoutControllerProvider.overrideWith(
            () => _CheckoutControllerForTest(_readyCheckout),
          ),
          ordersRepositoryProvider.overrideWithValue(orders),
          mealPlanRepositoryProvider.overrideWithValue(
            _RefreshedDiscountPricing(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(checkoutControllerProvider.notifier);
      expect(await controller.placeOrder(), isNull);
      final refreshed = container.read(checkoutControllerProvider);
      expect(refreshed.selection!.pricingOption.totalPrice, 1600);
      expect(refreshed.selection!.pricingOption.originalPrice, 1880);
      expect(refreshed.placementError, contains('price has changed'));
      expect(orders.requests, hasLength(1));
      expect(orders.requests.first.expectedTotalAmount, 1880);
      expect((await controller.placeOrder())!.pricing.totalAmount, 1600);
      expect(orders.requests, hasLength(2));
      expect(orders.requests.last.expectedTotalAmount, 1600);
      expect(orders.requests.last.expectedDiscountAmount, 280);
    },
  );

  test('ProblemDetails preserves the backend order failure explanation', () {
    final error = ApiException.fromResponse(
      const ApiResponse(
        statusCode: 400,
        body: {
          'title': 'Invalid request',
          'detail': 'startDate must fall on a selected delivery weekday.',
          'code': 'invalid_start_date',
        },
      ),
    );

    expect(error.failure, ApiFailure.validation);
    expect(error.code, 'invalid_start_date');
    expect(
      error.message,
      'startDate must fall on a selected delivery weekday.',
    );
  });

  test(
    'placement retries with one idempotency key and clears only draft',
    () async {
      final api = _OrdersApiClient(failFirst: true);
      final container = ProviderContainer(
        overrides: [
          checkoutControllerProvider.overrideWith(
            () => _CheckoutControllerForTest(_readyCheckout),
          ),
          ordersRepositoryProvider.overrideWithValue(
            OrdersRepository(
              apiClient: api,
              accessTokenProvider: () async => 'access-token',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(checkoutControllerProvider.notifier);

      expect(await controller.placeOrder(), isNull);
      final failed = container.read(checkoutControllerProvider);
      expect(failed.idempotencyKey, isNotEmpty);
      expect(failed.selection, isNotNull);
      expect(failed.selectedAddress, isNotNull);

      final confirmation = await controller.placeOrder();
      expect(confirmation?.orderNumber, 'ORD-20260810-000001');
      expect(api.requests, hasLength(2));
      expect(
        api.requests[0].headers['Idempotency-Key'],
        api.requests[1].headers['Idempotency-Key'],
      );
      expect(api.requests[1].headers['Authorization'], 'Bearer access-token');
      expect(api.requests[1].body, {
        'customerProfileId': 'profile-id',
        'mealPlanTemplateId': 'plan-id',
        'mealPlanPriceId': 'price-id',
        'customerAddressId': 'address-id',
        'fulfillmentMethod': 'HOME_DELIVERY',
        'takeawayBranchId': null,
        'serviceDates': ['2026-08-11', '2026-09-05'],
        'deliveryTimeSlotId': 'slot-id',
        'startDate': '2026-08-11',
        'deliveryDays': [2, 3, 4, 5, 6],
        'meals': [],
        'couponCode': null,
        'expectedTotalAmount': 1880.0,
        'expectedRegularPrice': 1880.0,
        'expectedDiscountAmount': 0.0,
        'expectedCurrencyCode': 'QAR',
      });
      for (final forbidden in [
        'planName',
        'durationName',
        'endDate',
        'totalAmount',
        'currencyCode',
        'latitude',
        'longitude',
      ]) {
        expect(api.requests[1].body, isNot(contains(forbidden)));
      }

      final completed = container.read(checkoutControllerProvider);
      expect(completed.selection, isNull);
      expect(completed.selectedAddress, isNull);
      expect(completed.customerProfileId, 'profile-id');
      expect(completed.addresses, hasLength(1));
      expect(completed.orderConfirmation?.pricing.totalAmount, 1880);
    },
  );

  test(
    'repository prepares customer order list and order detail endpoints',
    () async {
      final api = _OrdersApiClient();
      final repository = OrdersRepository(
        apiClient: api,
        accessTokenProvider: () async => null,
      );

      final orders = await repository.getCustomerOrders('profile 1');
      final order = await repository.getOrder('order/1');

      expect(orders.single.orderNumber, 'ORD-20260810-000001');
      expect(order.id, 'order-id');
      expect(
        api.requests[0].path,
        '/api/v1/customer-profiles/profile%201/orders',
      );
      expect(api.requests[1].path, '/api/v1/orders/order%2F1');
    },
  );

  test('simultaneous Place Order taps submit only one request', () async {
    final api = _OrdersApiClient();
    final container = ProviderContainer(
      overrides: [
        checkoutControllerProvider.overrideWith(
          () => _CheckoutControllerForTest(_readyCheckout),
        ),
        ordersRepositoryProvider.overrideWithValue(
          OrdersRepository(
            apiClient: api,
            accessTokenProvider: () async => 'access-token',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(checkoutControllerProvider.notifier);

    final results = await Future.wait([
      controller.placeOrder(),
      controller.placeOrder(),
    ]);

    expect(api.requests, hasLength(1));
    expect(results.whereType<Object>(), hasLength(1));
  });

  test(
    'starting another order clears checkout but preserves profile and addresses',
    () {
      final container = ProviderContainer(
        overrides: [
          checkoutControllerProvider.overrideWith(
            () => _CheckoutControllerForTest(_readyCheckout),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(checkoutControllerProvider.notifier).beginNewOrder();

      final checkout = container.read(checkoutControllerProvider);
      expect(checkout.selection, isNull);
      expect(checkout.schedule, isNull);
      expect(checkout.selectedAddressId, isNull);
      expect(checkout.selectedDeliveryTimeSlotId, isNull);
      expect(checkout.idempotencyKey, isNull);
      expect(checkout.orderConfirmation, isNull);
      expect(checkout.customerProfileId, 'profile-id');
      expect(checkout.addresses, [_address]);
    },
  );

  test(
    'summary resolves a display-only package to its authenticated price ID',
    () async {
      final api = _PurchaseOptionsApiClient();
      final container = ProviderContainer(
        overrides: [
          checkoutControllerProvider.overrideWith(
            () => _CheckoutControllerForTest(_displayOnlyCheckout),
          ),
          mealPlanRepositoryProvider.overrideWithValue(
            MealPlanRepository(
              api,
              accessTokenProvider: () async => 'access-token',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(checkoutControllerProvider.notifier)
          .prepareForOrder(language: 'en');

      final checkout = container.read(checkoutControllerProvider);
      expect(checkout.mealPlanPriceId, 'authoritative-price-id');
      expect(checkout.selection?.pricingOption.name, '1 Month');
      expect(checkout.selectedMeals, hasLength(3));
      expect(checkout.canPlaceOrder, isTrue);
      expect(api.path, '/api/v1/customer/meal-plans/CLASSIC/purchase-options');
      expect(api.authorization, 'Bearer access-token');
    },
  );
}

class _CheckoutControllerForTest extends CheckoutController {
  _CheckoutControllerForTest(this.initialState);
  final CheckoutState initialState;

  @override
  CheckoutState build() => initialState;
}

class _ChangedPriceOrders extends OrdersRepository {
  _ChangedPriceOrders()
    : super(apiClient: ApiClient(), accessTokenProvider: () async => 'token');
  final requests = <PlaceOrderRequest>[];
  @override
  Future<OrderConfirmation> placeOrder(
    PlaceOrderRequest request,
    String idempotencyKey,
  ) async {
    requests.add(request);
    if (requests.length == 1) {
      throw const ApiException(
        ApiFailure.conflict,
        statusCode: 409,
        code: 'price_changed',
      );
    }
    return OrderConfirmation.fromJson({
      ..._confirmationJson,
      'pricing': {
        'subtotal': 1880,
        'discountAmount': 280,
        'deliveryCharge': 0,
        'totalAmount': 1600,
        'currencyCode': 'QAR',
      },
    });
  }
}

class _RefreshedDiscountPricing extends MealPlanRepository {
  _RefreshedDiscountPricing() : super(ApiClient());
  @override
  Future<List<MealPlanConfiguration>> getMealPlanConfigurations({
    required String mealPlanTemplateId,
    required String language,
  }) async => [
    MealPlanConfiguration(
      id: 'configuration-id',
      name: '3 Meals',
      selectedMeals: _readyCheckout.selectedMeals,
      packages: [
        MealPlanPackage(
          mealPlanPriceId: 'price-id',
          name: '1 Month',
          serviceDays: 20,
          totalPrice: 1600,
          dailyPrice: 80,
          currencyCode: 'QAR',
          serverNow: DateTime.utc(2026, 8, 7),
          serverReceivedAt: DateTime.now().toUtc(),
          regularPrice: 1880,
          discountedPrice: 1600,
        ),
      ],
    ),
  ];
}

class _OrdersApiClient extends ApiClient {
  _OrdersApiClient({this.failFirst = false});

  final bool failFirst;
  final requests = <_Request>[];

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    requests.add(
      _Request(method: method, path: path, headers: headers, body: body),
    );
    if (failFirst && requests.length == 1) {
      throw const ApiException(ApiFailure.timeout);
    }
    if (method == 'GET' && path.contains('/customer-profiles/')) {
      return ApiResponse(
        statusCode: 200,
        body: {
          'items': [_confirmationJson],
          'pageNumber': 1,
          'pageSize': 20,
          'totalCount': 1,
        },
      );
    }
    return ApiResponse(
      statusCode: method == 'POST' ? 201 : 200,
      body: {'data': _confirmationJson},
    );
  }
}

class _PurchaseOptionsApiClient extends ApiClient {
  String? path;
  String? authorization;

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    this.path = path;
    authorization = headers['Authorization'];
    return const ApiResponse(
      statusCode: 200,
      body: {
        'data': {
          'plan': {'id': 'plan-id', 'code': 'CLASSIC', 'name': 'Classic'},
          'mealConfigurations': [
            {
              'mealsPerDay': 3,
              'snacksPerDay': 1,
              'displayName': '3 Meals + 1 Snack',
              'includedText': 'Lunch, Dinner and Snack',
              'packages': [
                {
                  'priceId': 'authoritative-price-id',
                  'packageId': 'MONTH',
                  'packageCode': 'MONTH',
                  'packageName': '1 Month',
                  'serviceDays': 20,
                  'serverNow': '2026-08-07T00:00:00Z',
                  'currencyCode': 'QAR',
                  'amount': 1880,
                  'pricePerServiceDay': 94,
                },
              ],
            },
          ],
        },
      },
    );
  }
}

class _Request {
  const _Request({
    required this.method,
    required this.path,
    required this.headers,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, String> headers;
  final Map<String, dynamic>? body;
}

final _readyCheckout = CheckoutState(
  selection: MealPlanPurchaseSelection(
    mealPlan: MealPlanOption(id: 'plan-id', code: 'CLASSIC', name: 'Classic'),
    mealCombination: MealPlanConfiguration(
      id: 'configuration-id',
      name: '3 Meals',
      packages: [],
      selectedMeals: [
        MealPlanMealSelection(mealTypeId: 'lunch-id', name: 'Lunch'),
        MealPlanMealSelection(mealTypeId: 'dinner-id', name: 'Dinner'),
        MealPlanMealSelection(mealTypeId: 'snack-id', name: 'Snack'),
      ],
    ),
    pricingOption: MealPlanPackage(
      mealPlanPriceId: 'price-id',
      name: '1 Month',
      serviceDays: 20,
      totalPrice: 1880,
      dailyPrice: 94,
      currencyCode: 'QAR',
      serverNow: DateTime.utc(2026, 8, 7),
      serverReceivedAt: DateTime.now().toUtc(),
    ),
    deliveryDaysPerWeek: 5,
    selectedWeekdays: {2, 3, 4, 5, 6},
  ),
  schedule: MealPlanServiceSchedule(
    serviceDates: [DateTime(2026, 8, 11), DateTime(2026, 9, 5)],
  ),
  customerProfileId: 'profile-id',
  selectedAddressId: 'address-id',
  selectedAddress: _address,
  selectedDeliveryTimeSlotId: 'slot-id',
  selectedDeliveryTimeSlot: _slot,
  addresses: const [_address],
  deliveryTimeSlots: const [_slot],
);

final _displayOnlyCheckout = _readyCheckout.copyWith(
  selection: MealPlanPurchaseSelection(
    mealPlan: _readyCheckout.selection!.mealPlan,
    mealCombination: const MealPlanConfiguration(
      id: '3-1',
      name: '3 Meals + 1 Snack',
      packages: [],
      selectedMeals: [
        MealPlanMealSelection(mealTypeId: 'lunch-id', name: 'Lunch'),
        MealPlanMealSelection(mealTypeId: 'dinner-id', name: 'Dinner'),
        MealPlanMealSelection(mealTypeId: 'snack-id', name: 'Snack'),
      ],
    ),
    pricingOption: MealPlanPackage(
      mealPlanPriceId: '',
      name: 'Monthly Plan',
      serviceDays: 20,
      totalPrice: 1880,
      dailyPrice: 94,
      currencyCode: 'QAR',
      serverNow: DateTime.utc(2026, 8, 7),
      serverReceivedAt: DateTime.now().toUtc(),
    ),
    deliveryDaysPerWeek: 5,
    selectedWeekdays: const {2, 3, 4, 5, 6},
  ),
);

const _address = CustomerDeliveryAddress(
  id: 'address-id',
  addressName: 'Home',
  addressType: DeliveryAddressType.home,
  buildingNo: '126',
  streetNo: '960',
  zoneNo: '91',
  area: 'Al Wakrah',
  latitude: 25.17,
  longitude: 51.60,
  formattedAddress: 'Zone 91, Al Wakrah, Qatar',
);

const _slot = DeliveryTimeSlot(
  id: 'slot-id',
  name: 'Morning',
  startTime: '09:00:00',
  endTime: '11:00:00',
);

const _confirmationJson = <String, dynamic>{
  'id': 'order-id',
  'orderNumber': 'ORD-20260810-000001',
  'status': 'CONFIRMED',
  'paymentStatus': 'PENDING',
  'plan': {
    'mealPlanTemplateId': 'plan-id',
    'mealPlanPriceId': 'price-id',
    'name': 'Classic',
    'durationName': '1 Month',
  },
  'meals': [
    {'mealTypeId': 'lunch-id', 'name': 'Lunch', 'quantity': 1},
  ],
  'delivery': {
    'daysPerWeek': 5,
    'days': [2, 3, 4, 5, 6],
    'startDate': '2026-08-11',
    'endDate': '2026-09-05',
    'timeSlot': {
      'id': 'slot-id',
      'name': 'Morning',
      'startTime': '09:00:00',
      'endTime': '11:00:00',
    },
    'address': {
      'addressId': 'address-id',
      'addressName': 'Home',
      'addressType': 'HOME',
      'buildingNo': '126',
      'streetNo': '960',
      'zoneNo': '91',
      'area': 'Al Wakrah',
      'formattedAddress': 'Zone 91, Al Wakrah, Qatar',
    },
  },
  'pricing': {
    'subtotal': 1880.0,
    'discountAmount': 0.0,
    'deliveryCharge': 0.0,
    'totalAmount': 1880.0,
    'currencyCode': 'QAR',
  },
  'placedAt': '2026-08-10T14:00:00Z',
};

class _AvailabilityPricing extends MealPlanRepository {
  _AvailabilityPricing() : super(ApiClient());
  final pending = <Completer<List<MealPlanConfiguration>>>[];
  final planIds = <String>[];
  @override
  Future<List<MealPlanConfiguration>> getMealPlanConfigurations({
    required String mealPlanTemplateId,
    required String language,
  }) {
    planIds.add(mealPlanTemplateId);
    final completer = Completer<List<MealPlanConfiguration>>();
    pending.add(completer);
    return completer.future;
  }
}

MealPlanConfiguration _availabilityConfiguration(
  MealPlanPurchaseSelection selection,
) => MealPlanConfiguration(
  id: selection.mealCombination.id,
  name: selection.mealCombination.name,
  selectedMeals: selection.mealCombination.selectedMeals,
  packages: [selection.pricingOption],
);

class _RejectedOrders extends OrdersRepository {
  _RejectedOrders(this.code)
    : super(apiClient: ApiClient(), accessTokenProvider: () async => 'token');
  final String? code;
  int calls = 0;
  @override
  Future<OrderConfirmation> placeOrder(
    PlaceOrderRequest request,
    String idempotencyKey,
  ) async {
    calls++;
    throw ApiException(ApiFailure.conflict, statusCode: 409, code: code);
  }
}
