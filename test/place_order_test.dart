import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
        'deliveryTimeSlotId': 'slot-id',
        'startDate': '2026-08-11',
        'deliveryDays': [2, 3, 4, 5, 6],
        'meals': [
          {'mealTypeId': 'lunch-id', 'quantity': 1},
          {'mealTypeId': 'dinner-id', 'quantity': 1},
          {'mealTypeId': 'snack-id', 'quantity': 1},
        ],
        'couponCode': null,
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
          'data': {
            'orders': [_confirmationJson],
          },
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
  selection: const MealPlanPurchaseSelection(
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
    pricingOption: const MealPlanPackage(
      mealPlanPriceId: '',
      name: 'Monthly Plan',
      serviceDays: 20,
      totalPrice: 1880,
      dailyPrice: 94,
      currencyCode: 'QAR',
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
