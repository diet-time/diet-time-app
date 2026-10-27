import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';

class CalendarDelivery {
  const CalendarDelivery({required this.order, required this.day});
  final OrderConfirmation order;
  final UpcomingMealDay day;
}

/// Several orders may share a delivery date; none may overwrite another.
Map<DateTime, List<CalendarDelivery>> deliveriesByDate(
  Iterable<CalendarDelivery> deliveries,
) {
  final result = <DateTime, List<CalendarDelivery>>{};
  for (final delivery in deliveries) {
    if (delivery.order.status == 'CANCELLED' ||
        delivery.day.deliveryStatus == 'CANCELLED' ||
        delivery.day.deliveryStatus == 'SKIPPED') {
      continue;
    }
    final date = delivery.day.date;
    (result[DateTime(date.year, date.month, date.day)] ??= []).add(delivery);
  }
  return result;
}
