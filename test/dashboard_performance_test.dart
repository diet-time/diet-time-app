import 'dart:async';

import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
    bool dashboard = false,
  }) async => [
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

  @override
  Future<OrderConfirmation> getOrder(String orderId) {
    detailRequested.complete();
    return detail.future;
  }
}
