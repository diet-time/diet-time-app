import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class CustomerDashboardState {
  const CustomerDashboardState();
}

class DashboardLoading extends CustomerDashboardState {
  const DashboardLoading();
}

class DashboardError extends CustomerDashboardState {
  const DashboardError(this.message);

  final String message;
}

class DashboardWithoutActivePlan extends CustomerDashboardState {
  const DashboardWithoutActivePlan(this.orders);

  final List<CustomerOrderSummary> orders;
}

class DashboardWithActivePlan extends CustomerDashboardState {
  const DashboardWithActivePlan({
    required this.order,
    required this.detail,
    required this.orders,
  });

  final CustomerOrderSummary order;
  final OrderConfirmation detail;
  final List<CustomerOrderSummary> orders;
}

class DashboardWithMultipleActivePlans extends CustomerDashboardState {
  const DashboardWithMultipleActivePlans({
    required this.activeOrders,
    required this.details,
    required this.orders,
  });

  final List<CustomerOrderSummary> activeOrders;
  final Map<String, OrderConfirmation> details;
  final List<CustomerOrderSummary> orders;
}

final customerDashboardControllerProvider =
    NotifierProvider<CustomerDashboardController, CustomerDashboardState>(
      CustomerDashboardController.new,
    );

class CustomerDashboardController extends Notifier<CustomerDashboardState> {
  String? _profileId;
  bool _requestInProgress = false;

  @override
  CustomerDashboardState build() => const DashboardLoading();

  Future<void> load(String profileId, {bool force = false}) async {
    final normalized = profileId.trim();
    if (normalized.isEmpty || _requestInProgress) return;
    if (!force && _profileId == normalized && state is! DashboardError) return;
    _profileId = normalized;
    _requestInProgress = true;
    state = const DashboardLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final orders = await repository.getCustomerOrders(normalized);
      final sortedOrders = [...orders]..sort(_newestFirst);
      final activeOrders = orders.where((order) => order.isCurrent).toList()
        ..sort(_currentFirst);
      if (activeOrders.isEmpty) {
        state = DashboardWithoutActivePlan(List.unmodifiable(sortedOrders));
        return;
      }
      final details = await Future.wait(
        activeOrders.map((order) => repository.getOrder(order.id)),
      );
      if (activeOrders.length == 1) {
        state = DashboardWithActivePlan(
          order: activeOrders.first,
          detail: details.first,
          orders: List.unmodifiable(sortedOrders),
        );
      } else {
        state = DashboardWithMultipleActivePlans(
          activeOrders: List.unmodifiable(activeOrders),
          details: {
            for (var index = 0; index < activeOrders.length; index++)
              activeOrders[index].id: details[index],
          },
          orders: List.unmodifiable(sortedOrders),
        );
      }
    } on Object {
      state = const DashboardError("We couldn't load your plans.");
    } finally {
      _requestInProgress = false;
    }
  }

  Future<void> refresh() async {
    final profileId = _profileId;
    if (profileId != null) await load(profileId, force: true);
  }
}

int _statusPriority(String status) => switch (status) {
  'ACTIVE' => 0,
  'CONFIRMED' => 1,
  'PAUSED' => 2,
  _ => 3,
};

int _currentFirst(CustomerOrderSummary left, CustomerOrderSummary right) {
  final status = _statusPriority(
    left.status,
  ).compareTo(_statusPriority(right.status));
  if (status != 0) return status;
  return _dateValue(right.startDate).compareTo(_dateValue(left.startDate));
}

int _newestFirst(CustomerOrderSummary left, CustomerOrderSummary right) =>
    _dateValue(right.placedAt).compareTo(_dateValue(left.placedAt));

int _dateValue(DateTime? value) => value?.millisecondsSinceEpoch ?? 0;
