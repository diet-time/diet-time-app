import 'dart:async';

import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'an old empty result cannot overwrite the newer customer dashboard',
    () async {
      final repository = _QueuedSummariesRepository();
      final container = ProviderContainer(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        customerDashboardControllerProvider.notifier,
      );
      final old = controller.load('old-profile');
      controller.clear();
      final current = controller.load('current-profile');
      final fixture = _SlowDetailRepository()..withSnapshot = true;
      repository.current.complete(
        await fixture.getCustomerOrders('current-profile'),
      );
      await current;
      final visible = container.read(customerDashboardControllerProvider);
      repository.old.complete([]);
      await old;
      expect(
        container.read(customerDashboardControllerProvider),
        same(visible),
      );
      expect(dashboardPlanOrders(visible).single.id, 'active');
    },
  );
  test(
    'refresh keeps the existing dashboard visible until new summaries arrive',
    () async {
      final repository = _SlowDetailRepository()..withSnapshot = true;
      final container = ProviderContainer(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        customerDashboardControllerProvider.notifier,
      );
      await controller.load('profile');
      final visible = container.read(customerDashboardControllerProvider);
      repository.summaryPending = Completer<List<CustomerOrderSummary>>();
      final refresh = controller.load('profile', force: true);
      expect(
        container.read(customerDashboardControllerProvider),
        same(visible),
      );
      repository.summaryPending!.complete([]);
      await refresh;
      expect(
        container.read(customerDashboardControllerProvider),
        isA<DashboardNoOrders>(),
      );
    },
  );
  test(
    'complete schedule summaries do not download full order calendars for home',
    () async {
      final repository = _SlowDetailRepository()..withSnapshot = true;
      final container = ProviderContainer(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container
          .read(customerDashboardControllerProvider.notifier)
          .load('profile');
      expect(
        dashboardPlanOrders(
          container.read(customerDashboardControllerProvider),
        ).single.id,
        'active',
      );
      expect(repository.detailRequested.isCompleted, isFalse);
    },
  );
  test('summaries render while an independent order detail is pending', () async {
    final repository = _SlowDetailRepository();
    final container = ProviderContainer(
      overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final load = container
        .read(customerDashboardControllerProvider.notifier)
        .load('profile');
    await repository.detailRequested.future;
    final pendingState = container.read(customerDashboardControllerProvider);
    // ignore: avoid_print
    print(
      'DASHBOARD_BENCHMARK detail_pending=true state=${pendingState.runtimeType}',
    );
    expect(dashboardPlanOrders(pendingState).single.id, 'active');
    repository.detail.completeError(const ApiException(ApiFailure.timeout));
    await load;
    expect(
      dashboardPlanOrders(
        container.read(customerDashboardControllerProvider),
      ).single.id,
      'active',
    );
  });

  test(
    'clearing the customer prevents an old in-flight detail restoring their data',
    () async {
      final repository = _SlowDetailRepository();
      final container = ProviderContainer(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        customerDashboardControllerProvider.notifier,
      );
      final load = controller.load('profile');
      await repository.detailRequested.future;
      controller.clear();
      repository.detail.completeError(const ApiException(ApiFailure.timeout));
      await load;
      expect(
        container.read(customerDashboardControllerProvider),
        isA<DashboardLoading>(),
      );
      expect(controller.profileId, isNull);
    },
  );
}

class _SlowDetailRepository extends OrdersRepository {
  _SlowDetailRepository()
    : super(apiClient: ApiClient(), accessTokenProvider: () async => null);
  final detail = Completer<OrderConfirmation>();
  final detailRequested = Completer<void>();
  bool withSnapshot = false;
  Completer<List<CustomerOrderSummary>>? summaryPending;

  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
    bool dashboard = false,
  }) async {
    if (summaryPending case final pending?) return pending.future;
    return [
      CustomerOrderSummary.fromJson({
        'id': 'active',
        'orderNumber': 'ORD-A',
        'planName': 'Balance',
        'status': 'ACTIVE',
        'paymentStatus': 'PAID',
        if (withSnapshot) ...{
          'mealCount': 3,
          'snackCount': 1,
          'packageSchedule': {
            'displayStatus': 'ACTIVE',
            'revisedEndDate': '2026-12-01',
            'remainingServiceDays': 12,
            'tomorrowScheduled': true,
          },
        },
      }),
    ];
  }

  @override
  Future<OrderConfirmation> getOrder(String orderId) {
    detailRequested.complete();
    return detail.future;
  }
}

class _QueuedSummariesRepository extends OrdersRepository {
  _QueuedSummariesRepository()
    : super(apiClient: ApiClient(), accessTokenProvider: () async => null);
  final old = Completer<List<CustomerOrderSummary>>();
  final current = Completer<List<CustomerOrderSummary>>();
  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
    bool dashboard = false,
  }) => profileId == 'old-profile' ? old.future : current.future;
}
