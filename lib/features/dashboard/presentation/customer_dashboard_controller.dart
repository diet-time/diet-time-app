import 'package:diet_time/features/personalization/domain/customer_onboarding.dart';
import 'package:diet_time/features/personalization/presentation/customer_onboarding_coordinator.dart';
import 'dart:async';
import 'package:diet_time/core/performance/performance_trace.dart';

import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/dashboard/presentation/package_management_provider.dart';
import 'package:diet_time/features/dashboard/data/upcoming_meals_repository.dart';
import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
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

class DashboardAuthenticationFailure extends CustomerDashboardState {
  const DashboardAuthenticationFailure();
}

class DashboardProfileNotFound extends CustomerDashboardState {
  const DashboardProfileNotFound();
}

class DashboardNeedsOnboarding extends CustomerDashboardState {
  const DashboardNeedsOnboarding();
}

class DashboardNoOrders extends CustomerDashboardState {
  const DashboardNoOrders();
}

class DashboardWithoutActivePlan extends CustomerDashboardState {
  const DashboardWithoutActivePlan(this.orders);

  final List<CustomerOrderSummary> orders;
}

/// Authoritative summary cards are available before full order details.
class DashboardSummariesReady extends CustomerDashboardState {
  const DashboardSummariesReady({
    required this.orders,
    required this.activeOrders,
  });
  final List<CustomerOrderSummary> orders;
  final List<CustomerOrderSummary> activeOrders;
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
  bool _refreshQueued = false;
  bool _initializationInProgress = false;
  bool _hasInitialized = false;
  int _generation = 0;
  String? get profileId => _profileId;

  @override
  CustomerDashboardState build() {
    ref.listen(
      otpAuthControllerProvider.select(
        (value) => (value.isAuthenticated, value.user?.id),
      ),
      (before, after) {
        if (before != null &&
            before.$1 &&
            (!after.$1 || before.$2 != after.$2)) {
          clear();
        }
      },
    );
    return const DashboardLoading();
  }

  void clear() {
    _generation++;
    ref.invalidate(customerOrderHistoryProvider);
    _profileId = null;
    _requestInProgress = false;
    _refreshQueued = false;
    _initializationInProgress = false;
    _hasInitialized = false;
    state = const DashboardLoading();
  }

  Future<void> initialize({String? profileId, bool force = false}) async {
    if (_initializationInProgress || (!force && _hasInitialized)) return;
    _initializationInProgress = true;
    final generation = _generation;
    state = const DashboardLoading();
    try {
      var resolvedProfileId = profileId?.trim() ?? '';
      if (resolvedProfileId.isEmpty) {
        final decision = await ref
            .read(customerOnboardingCoordinatorProvider.notifier)
            .check(refresh: force);
        if (!ref.mounted || generation != _generation) return;
        if (decision.phase == CustomerOnboardingPhase.unauthenticated) {
          state = const DashboardAuthenticationFailure();
          return;
        }
        if (decision.phase == CustomerOnboardingPhase.recoverableError) {
          state = const DashboardError(
            'We could not load your dashboard. Please try again.',
          );
          return;
        }
        if (decision.phase != CustomerOnboardingPhase.ready &&
            !ref.read(customerDashboardAvailableProvider)) {
          state = decision.phase == CustomerOnboardingPhase.profileRequired
              ? const DashboardProfileNotFound()
              : const DashboardNeedsOnboarding();
          return;
        }
        final profile = decision.profile!;
        resolvedProfileId = profile.profileId!.trim();
      }
      _profileId = resolvedProfileId;
      unawaited(
        ref
            .read(checkoutControllerProvider.notifier)
            .loadAddressesForProfile(resolvedProfileId),
      );
      await load(resolvedProfileId, force: force);
      if (ref.mounted && generation == _generation) _hasInitialized = true;
    } on CustomerProfileException catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = switch (error.statusCode) {
        401 => const DashboardAuthenticationFailure(),
        _ => const DashboardError(
          'We could not load your dashboard. Please try again.',
        ),
      };
    } on ApiException catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = _errorState(error);
    } on Object {
      if (!ref.mounted || generation != _generation) return;
      state = const DashboardError(
        'We could not load your dashboard. Please try again.',
      );
    } finally {
      if (generation == _generation) _initializationInProgress = false;
    }
  }

  Future<void> load(String profileId, {bool force = false}) async {
    final normalized = profileId.trim();
    if (normalized.isEmpty || _requestInProgress) return;
    if (!force &&
        _profileId == normalized &&
        state is! DashboardLoading &&
        state is! DashboardError) {
      return;
    }
    _profileId = normalized;
    _requestInProgress = true;
    final generation = _generation;
    final watch = Stopwatch()..start();
    if (!force) state = const DashboardLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      List<CustomerOrderSummary> orders;
      try {
        orders = await repository.getCustomerOrders(
          normalized,
          dashboard: true,
        );
      } on ApiException catch (error) {
        if (error.failure != ApiFailure.unauthorized) rethrow;
        if (!ref.mounted || generation != _generation) return;
        if (!ref.mounted || generation != _generation) return;
        final refreshed = await ref
            .read(otpAuthControllerProvider.notifier)
            .refreshAfterUnauthorized();
        if (!ref.mounted || generation != _generation) return;
        if (!refreshed) {
          state = const DashboardAuthenticationFailure();
          return;
        }
        unawaited(
          ref
              .read(checkoutControllerProvider.notifier)
              .loadAddressesForProfile(normalized),
        );
        orders = await repository.getCustomerOrders(
          normalized,
          dashboard: true,
        );
      }
      if (!ref.mounted || generation != _generation) return;
      PerformanceTrace.record('dashboard.summaries_ready', watch);
      final sortedOrders = [...orders]..sort(_newestFirst);
      if (sortedOrders.isEmpty) {
        state = const DashboardNoOrders();
        return;
      }
      final activeOrders = orders.where((order) => order.isCurrent).toList()
        ..sort(_currentFirst);
      if (activeOrders.isEmpty) {
        state = DashboardWithoutActivePlan(List.unmodifiable(sortedOrders));
        return;
      }
      state = DashboardSummariesReady(
        orders: List.unmodifiable(sortedOrders),
        activeOrders: List.unmodifiable(activeOrders),
      );
      // The current API includes purchased entitlements and the authoritative
      // schedule. Fetch full calendars/addresses only when their tab is opened.
      if (activeOrders.every(
        (order) => order.packageSchedule != null && order.entitlement != null,
      )) {
        return;
      }
      final details = await Future.wait<OrderConfirmation?>(
        activeOrders.map((order) async {
          try {
            return await repository.getOrder(order.id);
          } on ApiException catch (error) {
            if (error.failure == ApiFailure.unauthorized) rethrow;
            return null;
          } on Object {
            return null;
          }
        }),
      );
      if (!ref.mounted || generation != _generation) return;
      PerformanceTrace.record('dashboard.details_ready', watch);
      if (activeOrders.length == 1) {
        if (details.first == null) return;
        state = DashboardWithActivePlan(
          order: activeOrders.first,
          detail: details.first!,
          orders: List.unmodifiable(sortedOrders),
        );
      } else {
        state = DashboardWithMultipleActivePlans(
          activeOrders: List.unmodifiable(activeOrders),
          details: {
            for (var index = 0; index < activeOrders.length; index++)
              if (details[index] != null)
                activeOrders[index].id: details[index]!,
          },
          orders: List.unmodifiable(sortedOrders),
        );
      }
    } on ApiException catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = _errorState(error);
    } on Object {
      if (!ref.mounted || generation != _generation) return;
      state = const DashboardError(
        'We could not load your orders. Please try again.',
      );
    } finally {
      if (generation == _generation) _requestInProgress = false;
      if (generation == _generation && _refreshQueued && ref.mounted) {
        _refreshQueued = false;
        unawaited(refresh());
      }
    }
  }

  Future<void> refresh() async {
    if (_requestInProgress) {
      _refreshQueued = true;
      return;
    }
    ref.invalidate(packageManagementProvider);
    ref.invalidate(customerOrderHistoryProvider);
    ref.invalidate(upcomingMealDaysProvider);
    final profileId = _profileId;
    if (profileId != null) {
      unawaited(
        ref
            .read(checkoutControllerProvider.notifier)
            .loadAddressesForProfile(profileId),
      );
      await load(profileId, force: true);
    } else {
      await initialize(force: true);
    }
  }

  CustomerDashboardState _errorState(ApiException error) =>
      switch (error.failure) {
        ApiFailure.unauthorized => const DashboardAuthenticationFailure(),
        _ => DashboardError(
          error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : 'We could not load your orders. Please try again.',
        ),
      };
}

int _statusPriority(String status) => switch (status) {
  'ACTIVE' => 0,
  'PAUSE_REQUESTED' => 0,
  'CONFIRMED' => 1,
  'UPCOMING' => 1,
  'PAUSE_SCHEDULED' => 2,
  'PAUSED' => 2,
  _ => 3,
};

int _currentFirst(CustomerOrderSummary left, CustomerOrderSummary right) {
  final status = _statusPriority(
    left.dashboardStatus,
  ).compareTo(_statusPriority(right.dashboardStatus));
  if (status != 0) return status;
  return _dateValue(right.startDate).compareTo(_dateValue(left.startDate));
}

int _newestFirst(CustomerOrderSummary left, CustomerOrderSummary right) =>
    _dateValue(right.placedAt).compareTo(_dateValue(left.placedAt));

int _dateValue(DateTime? value) => value?.millisecondsSinceEpoch ?? 0;

// Plan visibility is separate from fulfillment permission and uses the API's
// dashboard eligibility projection, with a status fallback for older APIs.
// Both the order list and active-plan state use the purchased order's ID.
List<CustomerOrderSummary> dashboardPlanOrders(CustomerDashboardState state) {
  final orders = switch (state) {
    DashboardSummariesReady(:final orders) => orders,
    DashboardWithActivePlan(:final orders) => orders,
    DashboardWithMultipleActivePlans(:final orders) => orders,
    DashboardWithoutActivePlan(:final orders) => orders,
    _ => const <CustomerOrderSummary>[],
  };
  final active = switch (state) {
    DashboardSummariesReady(:final activeOrders) => activeOrders,
    DashboardWithActivePlan(:final order) => [order],
    DashboardWithMultipleActivePlans(:final activeOrders) => activeOrders,
    _ => const <CustomerOrderSummary>[],
  };
  final byId = <String, CustomerOrderSummary>{};
  for (final order in [...active, ...orders]) {
    final previous = byId[order.id];
    if (order.id.isNotEmpty &&
        (previous == null || order.rowVersion >= previous.rowVersion)) {
      byId[order.id] = order;
    }
  }
  return List.unmodifiable(byId.values.where((order) => order.isCurrent));
}
