import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_screen.dart';
import 'package:diet_time/features/dashboard/presentation/order_details_screen.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard initialization runs once across widget rebuilds', (
    tester,
  ) async {
    final dashboard = _RecordingDashboardController();
    final container = ProviderContainer(
      overrides: [
        customerDashboardControllerProvider.overrideWith(() => dashboard),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CustomerDashboardScreen()),
      ),
    );
    await tester.pump();
    expect(dashboard.initializeCalls, 1);

    container
        .read(personalizationControllerProvider.notifier)
        .replace(const CustomerProfile(profileId: 'late-profile-id'));
    await tester.pump();
    await tester.pump();

    expect(dashboard.initializeCalls, 1);
    expect(find.byKey(const ValueKey('noActivePlan')), findsOneWidget);
  });

  testWidgets('green active-plan dashboard fits a compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final summary = _summary('active', 'ACTIVE', DateTime(2026, 8, 11));
    final detail = _detail(summary);
    final state = DashboardWithActivePlan(
      order: summary,
      detail: detail,
      orders: [summary],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerDashboardControllerProvider.overrideWith(
            () => _DashboardControllerForTest(state),
          ),
        ],
        child: const MaterialApp(home: CustomerDashboardScreen()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('activePlan-active')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('QUICK ACTIONS'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('QUICK ACTIONS'), findsOneWidget);
    expect(find.textContaining('ORDER ANOTHER PLAN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple active plans use a compact swipeable carousel', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final orders = [
      _summary('active', 'ACTIVE', DateTime(2026, 8, 11)),
      _summary('confirmed', 'CONFIRMED', DateTime(2026, 9, 1)),
    ];
    final state = DashboardWithMultipleActivePlans(
      activeOrders: orders,
      details: {for (final order in orders) order.id: _detail(order)},
      orders: orders,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerDashboardControllerProvider.overrideWith(
            () => _DashboardControllerForTest(state),
          ),
        ],
        child: const MaterialApp(home: CustomerDashboardScreen()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('activePlansCarousel')), findsOneWidget);
    expect(find.text('2 PLANS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('structured order details fit a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final summary = _summary('active', 'CONFIRMED', DateTime(2026, 8, 11));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(
            _FakeOrdersRepository([summary]),
          ),
        ],
        child: const MaterialApp(home: OrderDetailsScreen(orderId: 'active')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('orderDetailsHeader')), findsOneWidget);
    expect(find.text('ORDER NUMBER'), findsOneWidget);
    expect(find.text('PAYMENT STATUS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('orders tab filters backend orders by status', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final orders = [
      _summary('confirmed', 'CONFIRMED', DateTime(2026, 8, 11)),
      _summary('pending', 'PENDING', DateTime(2026, 8, 15)),
      _summary('cancelled', 'CANCELLED', DateTime(2026, 8, 20)),
    ];
    final state = DashboardWithoutActivePlan(orders);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerDashboardControllerProvider.overrideWith(
            () => _DashboardControllerForTest(state),
          ),
          ordersRepositoryProvider.overrideWithValue(
            _FakeOrdersRepository(orders),
          ),
        ],
        child: const MaterialApp(home: CustomerDashboardScreen()),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('dashboardOrdersTab')));
    await tester.pumpAndSettle();

    expect(find.text('All Orders (3)'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('detailedOrder-confirmed')),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirmed (1)'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('detailedOrder-confirmed')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('detailedOrder-pending')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'completed customer with no current orders gets no-active-plan state',
    () async {
      final repository = _FakeOrdersRepository([
        _summary('completed', 'COMPLETED', DateTime(2026, 7, 1)),
      ]);
      final container = ProviderContainer(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(customerDashboardControllerProvider.notifier)
          .load('profile-id');

      final state = container.read(customerDashboardControllerProvider);
      expect(state, isA<DashboardWithoutActivePlan>());
      expect((state as DashboardWithoutActivePlan).orders, hasLength(1));
    },
  );

  test(
    'multiple current plans are retained and sorted by status priority',
    () async {
      final repository = _FakeOrdersRepository([
        _summary('paused', 'PAUSED', DateTime(2026, 9, 1)),
        _summary('confirmed', 'CONFIRMED', DateTime(2026, 8, 20)),
        _summary('active', 'ACTIVE', DateTime(2026, 8, 11)),
        _summary('cancelled', 'CANCELLED', DateTime(2026, 7, 1)),
      ]);
      final container = ProviderContainer(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(customerDashboardControllerProvider.notifier)
          .load('profile-id');

      final state = container.read(customerDashboardControllerProvider);
      expect(state, isA<DashboardWithMultipleActivePlans>());
      final active = (state as DashboardWithMultipleActivePlans).activeOrders;
      expect(active.map((order) => order.status), [
        'ACTIVE',
        'CONFIRMED',
        'PAUSED',
      ]);
      expect(
        state.details.keys,
        containsAll(['active', 'confirmed', 'paused']),
      );
    },
  );

  test('order list parser accepts the backend root items envelope', () async {
    final api = _OrderListApiClient();
    final repository = OrdersRepository(
      apiClient: api,
      accessTokenProvider: () async => 'token',
    );

    final orders = await repository.getCustomerOrders('profile-id');

    expect(orders.single.planName, 'Classic Plan');
    expect(orders.single.status, 'ACTIVE');
    expect(orders.single.totalAmount, 1880);
    expect(api.path, '/api/v1/customer-profiles/profile-id/orders');
    expect(api.queryParameters, {'pageNumber': '1', 'pageSize': '20'});
    expect(api.headers['Authorization'], 'Bearer token');
  });

  test('order list parser accepts a successful top-level empty page', () async {
    final repository = OrdersRepository(
      apiClient: _StaticOrdersApiClient(
        const ApiResponse(
          statusCode: 200,
          body: {'items': [], 'pageNumber': 1, 'pageSize': 20, 'totalCount': 0},
        ),
      ),
      accessTokenProvider: () async => 'token',
    );

    final orders = await repository.getCustomerOrders('profile-id');

    expect(orders, isEmpty);
  });

  test('malformed order page is an API failure, not an empty result', () async {
    final repository = OrdersRepository(
      apiClient: _StaticOrdersApiClient(
        const ApiResponse(
          statusCode: 200,
          body: {
            'data': {'orders': []},
          },
        ),
      ),
      accessTokenProvider: () async => 'token',
    );

    expect(
      repository.getCustomerOrders('profile-id'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.failure,
          'failure',
          ApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('successful empty items response becomes loaded empty state', () async {
    final container = ProviderContainer(
      overrides: [
        ordersRepositoryProvider.overrideWithValue(
          _FakeOrdersRepository(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(customerDashboardControllerProvider.notifier)
        .load('profile-id');

    final state = container.read(customerDashboardControllerProvider);
    expect(state, isA<DashboardNoOrders>());
  });

  test('orders request failure becomes retryable dashboard error', () async {
    final container = ProviderContainer(
      overrides: [
        ordersRepositoryProvider.overrideWithValue(_FailingOrdersRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(customerDashboardControllerProvider.notifier)
        .load('profile-id');

    expect(
      container.read(customerDashboardControllerProvider),
      isA<DashboardError>(),
    );
  });

  test(
    'profile PUT failure cannot block GET-based dashboard loading',
    () async {
      final profileRepository = _GetOnlyProfileRepository();
      final ordersRepository = _CountingOrdersRepository();
      final container = ProviderContainer(
        overrides: [
          customerProfileRepositoryProvider.overrideWithValue(
            profileRepository,
          ),
          ordersRepositoryProvider.overrideWithValue(ordersRepository),
          checkoutControllerProvider.overrideWith(_NoopCheckoutController.new),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        profileRepository.updateProfile(const CustomerProfile()),
        throwsA(isA<CustomerProfileException>()),
      );
      await container
          .read(customerDashboardControllerProvider.notifier)
          .initialize();

      expect(profileRepository.getCalls, 1);
      expect(profileRepository.updateCalls, 1);
      expect(ordersRepository.profileIds, ['profile-from-get']);
      expect(
        container.read(customerDashboardControllerProvider),
        isA<DashboardNoOrders>(),
      );
    },
  );
}

CustomerOrderSummary _summary(String id, String status, DateTime startDate) =>
    CustomerOrderSummary(
      id: id,
      orderNumber: 'ORD-$id',
      planName: '$id plan',
      planDurationName: '1 Month',
      status: status,
      paymentStatus: 'PAID',
      totalAmount: 100,
      currencyCode: 'QAR',
      startDate: startDate,
      endDate: startDate.add(const Duration(days: 20)),
      placedAt: startDate.subtract(const Duration(days: 1)),
    );

OrderConfirmation _detail(CustomerOrderSummary summary) =>
    OrderConfirmation.fromJson({
      'id': summary.id,
      'orderNumber': summary.orderNumber,
      'status': summary.status,
      'paymentStatus': summary.paymentStatus,
      'plan': {
        'name': summary.planName,
        'durationName': summary.planDurationName,
      },
      'meals': const [],
      'delivery': {
        'daysPerWeek': 5,
        'days': [1, 2, 3, 4, 5],
        'startDate': summary.startDate?.toIso8601String(),
        'endDate': summary.endDate?.toIso8601String(),
      },
      'pricing': {
        'totalAmount': summary.totalAmount,
        'currencyCode': summary.currencyCode,
      },
      'placedAt': summary.placedAt?.toIso8601String(),
    });

class _FakeOrdersRepository extends OrdersRepository {
  _FakeOrdersRepository(this.orders)
    : super(apiClient: ApiClient(), accessTokenProvider: _noToken);

  final List<CustomerOrderSummary> orders;

  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
  }) async => orders;

  @override
  Future<OrderConfirmation> getOrder(String orderId) async =>
      _detail(orders.singleWhere((order) => order.id == orderId));
}

class _DashboardControllerForTest extends CustomerDashboardController {
  _DashboardControllerForTest(this.initialState);

  final CustomerDashboardState initialState;

  @override
  CustomerDashboardState build() => initialState;

  @override
  Future<void> initialize({String? profileId, bool force = false}) async {}

  @override
  Future<void> load(String profileId, {bool force = false}) async {}
}

class _RecordingDashboardController extends CustomerDashboardController {
  int initializeCalls = 0;

  @override
  CustomerDashboardState build() => const DashboardLoading();

  @override
  Future<void> initialize({String? profileId, bool force = false}) async {
    initializeCalls++;
    state = const DashboardWithoutActivePlan([]);
  }
}

class _OrderListApiClient extends ApiClient {
  String? path;
  Map<String, String> queryParameters = const {};
  Map<String, String> headers = const {};

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    this.path = path;
    this.queryParameters = queryParameters;
    this.headers = headers;
    return const ApiResponse(
      statusCode: 200,
      body: {
        'items': [
          {
            'id': 'order-id',
            'orderNumber': 'ORD-1',
            'planName': 'Classic Plan',
            'planDurationName': '1 Month',
            'startDate': '2026-08-11',
            'endDate': '2026-09-05',
            'status': 'ACTIVE',
            'paymentStatus': 'PAID',
            'totalAmount': 1880,
            'currencyCode': 'QAR',
            'placedAt': '2026-08-10T10:00:00Z',
          },
        ],
        'pageNumber': 1,
        'pageSize': 100,
        'totalCount': 1,
      },
    );
  }
}

class _StaticOrdersApiClient extends ApiClient {
  _StaticOrdersApiClient(this.response);

  final ApiResponse response;

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async => response;
}

class _FailingOrdersRepository extends OrdersRepository {
  _FailingOrdersRepository()
    : super(apiClient: ApiClient(), accessTokenProvider: _noToken);

  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
  }) => throw const ApiException(ApiFailure.server, statusCode: 500);
}

class _CountingOrdersRepository extends OrdersRepository {
  _CountingOrdersRepository()
    : super(apiClient: ApiClient(), accessTokenProvider: _noToken);

  final List<String> profileIds = [];

  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
  }) async {
    profileIds.add(profileId);
    return const [];
  }
}

class _GetOnlyProfileRepository implements CustomerProfileRepository {
  int getCalls = 0;
  int updateCalls = 0;

  @override
  Future<CustomerProfile?> getProfile() async {
    getCalls++;
    return const CustomerProfile(profileId: 'profile-from-get');
  }

  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async {
    updateCalls++;
    throw const CustomerProfileException(statusCode: 500);
  }
}

class _NoopCheckoutController extends CheckoutController {
  @override
  CheckoutState build() => const CheckoutState();

  @override
  Future<void> loadAddressesForProfile(String profileId) async {}
}

Future<String?> _noToken() async => null;
