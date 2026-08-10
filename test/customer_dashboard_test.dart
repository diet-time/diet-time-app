import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_screen.dart';
import 'package:diet_time/features/dashboard/presentation/order_details_screen.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'dashboard loads when profile ID becomes available after first frame',
    (tester) async {
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
      expect(dashboard.loadedProfileId, isNull);

      container
          .read(personalizationControllerProvider.notifier)
          .replace(const CustomerProfile(profileId: 'late-profile-id'));
      await tester.pump();
      await tester.pump();

      expect(dashboard.loadedProfileId, 'late-profile-id');
      expect(find.byKey(const ValueKey('noActivePlan')), findsOneWidget);
    },
  );

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
    final repository = OrdersRepository(
      apiClient: _OrderListApiClient(),
      accessTokenProvider: () async => 'token',
    );

    final orders = await repository.getCustomerOrders('profile-id');

    expect(orders.single.planName, 'Classic Plan');
    expect(orders.single.status, 'ACTIVE');
    expect(orders.single.totalAmount, 1880);
  });
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
    int pageSize = 100,
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
  Future<void> load(String profileId, {bool force = false}) async {}
}

class _RecordingDashboardController extends CustomerDashboardController {
  String? loadedProfileId;

  @override
  CustomerDashboardState build() => const DashboardLoading();

  @override
  Future<void> load(String profileId, {bool force = false}) async {
    loadedProfileId = profileId;
    state = const DashboardWithoutActivePlan([]);
  }
}

class _OrderListApiClient extends ApiClient {
  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async => const ApiResponse(
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

Future<String?> _noToken() async => null;
