import 'package:diet_time/app/localization/customer_copy.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/presentation/daily_meals_panel.dart';
import 'package:diet_time/features/dashboard/presentation/order_details_screen.dart';
import 'package:diet_time/features/dashboard/presentation/upcoming_deliveries_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uses the paginated customer order list, including completed subscriptions.
class CustomerDeliveryCalendar extends ConsumerWidget {
  const CustomerDeliveryCalendar({
    required this.orders,
    required this.knownOrders,
    super.key,
  });
  final List<CustomerOrderSummary> orders;
  final Map<String, OrderConfirmation> knownOrders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = <OrderConfirmation>[];
    var loading = false;
    var failed = false;
    for (final summary in orders.where((o) => o.isCurrent || o.isCompleted)) {
      final known = knownOrders[summary.id];
      if (known != null) {
        details.add(known);
      } else {
        final result = ref.watch(orderDetailsProvider(summary.id));
        loading |= result.isLoading;
        failed |= result.hasError;
        if (result.asData?.value case final detail?) details.add(detail);
      }
    }
    if (failed) {
      return MealMenuMessage(
        message: context.customerCopy(
          'We couldn’t load all your delivery orders.',
        ),
        onRetry: () {
          for (final summary in orders) {
            ref.invalidate(orderDetailsProvider(summary.id));
          }
        },
      );
    }
    if (loading) return const MealMenuLoading();
    return UpcomingDeliveriesScreen(orders: details, embedded: true);
  }
}
