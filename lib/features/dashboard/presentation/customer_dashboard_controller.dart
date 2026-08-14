import 'dart:async';

import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
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

class DashboardNoOrders extends CustomerDashboardState {
  const DashboardNoOrders();
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
  bool _initializationInProgress = false;
  bool _hasInitialized = false;

  @override
  CustomerDashboardState build() => const DashboardLoading();

  void clear() {
    _profileId = null;
    _requestInProgress = false;
    _initializationInProgress = false;
    _hasInitialized = false;
    state = const DashboardLoading();
  }

  Future<void> initialize({String? profileId, bool force = false}) async {
    if (_initializationInProgress || (!force && _hasInitialized)) return;
    _initializationInProgress = true;
    state = const DashboardLoading();
    try {
      var resolvedProfileId = profileId?.trim() ?? '';
      if (resolvedProfileId.isEmpty) {
        final profile = await _loadAuthenticatedProfile();
        if (profile == null || profile.profileId?.trim().isNotEmpty != true) {
          state = const DashboardProfileNotFound();
          return;
        }
        ref.read(personalizationControllerProvider.notifier).replace(profile);
        resolvedProfileId = profile.profileId!.trim();
      }
      _profileId = resolvedProfileId;
      unawaited(
        ref
            .read(checkoutControllerProvider.notifier)
            .loadAddressesForProfile(resolvedProfileId),
      );
      await load(resolvedProfileId, force: force);
      _hasInitialized = true;
    } on CustomerProfileException catch (error) {
      state = switch (error.statusCode) {
        401 => const DashboardAuthenticationFailure(),
        404 => const DashboardProfileNotFound(),
        _ => const DashboardError(
          'We could not load your dashboard. Please try again.',
        ),
      };
    } on ApiException catch (error) {
      state = _errorState(error);
    } on Object {
      state = const DashboardError(
        'We could not load your dashboard. Please try again.',
      );
    } finally {
      _initializationInProgress = false;
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
    state = const DashboardLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      List<CustomerOrderSummary> orders;
      try {
        orders = await repository.getCustomerOrders(normalized, pageSize: 20);
      } on ApiException catch (error) {
        if (error.failure != ApiFailure.unauthorized) rethrow;
        final refreshed = await ref
            .read(otpAuthControllerProvider.notifier)
            .refreshAfterUnauthorized();
        if (!refreshed) {
          state = const DashboardAuthenticationFailure();
          return;
        }
        unawaited(
          ref
              .read(checkoutControllerProvider.notifier)
              .loadAddressesForProfile(normalized),
        );
        orders = await repository.getCustomerOrders(normalized, pageSize: 20);
      }
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
    } on ApiException catch (error) {
      state = _errorState(error);
    } on Object {
      state = const DashboardError(
        'We could not load your orders. Please try again.',
      );
    } finally {
      _requestInProgress = false;
    }
  }

  Future<void> refresh() async {
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

  Future<CustomerProfile?> _loadAuthenticatedProfile() async {
    final repository = ref.read(customerProfileRepositoryProvider);
    try {
      return await repository.getProfile();
    } on CustomerProfileException catch (error) {
      if (error.statusCode != 401) rethrow;
      final refreshed = await ref
          .read(otpAuthControllerProvider.notifier)
          .refreshAfterUnauthorized();
      if (!refreshed) {
        throw const CustomerProfileException(statusCode: 401);
      }
      return repository.getProfile();
    }
  }

  CustomerDashboardState _errorState(ApiException error) =>
      switch (error.failure) {
        ApiFailure.unauthorized => const DashboardAuthenticationFailure(),
        ApiFailure.notFound => const DashboardProfileNotFound(),
        _ => DashboardError(
          error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : 'We could not load your orders. Please try again.',
        ),
      };
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
