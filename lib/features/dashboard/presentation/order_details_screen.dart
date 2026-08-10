import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final orderDetailsProvider = FutureProvider.autoDispose
    .family<OrderConfirmation, String>(
      (ref, orderId) => ref.watch(ordersRepositoryProvider).getOrder(orderId),
    );

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailsProvider(orderId));
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6EF),
        surfaceTintColor: Colors.transparent,
        title: const Text('Order Details'),
      ),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _OrderError(
          onRetry: () => ref.invalidate(orderDetailsProvider(orderId)),
        ),
        data: (value) => _OrderDetails(order: value),
      ),
    );
  }
}

class _OrderDetails extends StatelessWidget {
  const _OrderDetails({required this.order});

  final OrderConfirmation order;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final delivery = order.delivery;
    return ListView(
      key: const ValueKey('orderDetails'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        _DetailsCard(
          children: [
            _Detail('ORDER NUMBER', order.orderNumber),
            _Detail('PLAN', '${order.plan.name}\n${order.plan.durationName}'),
            _Detail('STATUS', order.status),
            _Detail(
              'PLAN PERIOD',
              _period(delivery.startDate, delivery.endDate),
            ),
            _Detail(
              'MEALS',
              order.meals
                  .map((meal) => '${meal.name} x ${meal.quantity}')
                  .join('\n'),
            ),
            _Detail(
              'DELIVERY DAYS',
              '${delivery.daysPerWeek} Days / Week\n${_weekdays(delivery.days)}',
            ),
            _Detail(
              'DELIVERY ADDRESS',
              [
                delivery.address.displayName,
                delivery.address.area,
                delivery.address.streetLine,
                delivery.address.formattedAddress,
              ].where((value) => value.trim().isNotEmpty).join('\n'),
            ),
            _Detail(
              'DELIVERY TIME',
              '${delivery.timeSlot.name}\n${_time(delivery.timeSlot.startTime)} - ${_time(delivery.timeSlot.endTime)}',
            ),
            _Detail(
              'PRICING',
              '${formatMealPlanPriceAmount(order.pricing.totalAmount, locale)} ${order.pricing.currencyCode}',
            ),
            _Detail('PAYMENT STATUS', order.paymentStatus, last: true),
          ],
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.darkGreen.withValues(alpha: .08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value, {this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.darkGreen.withValues(alpha: .5),
            fontSize: 10,
            letterSpacing: .8,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _OrderError extends StatelessWidget {
  const _OrderError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("We couldn't load this order."),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
      ],
    ),
  );
}

String _period(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '—';
  return '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
}

String _weekdays(List<int> days) {
  const labels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };
  return days.map((day) => labels[day]).whereType<String>().join(', ');
}

String _time(String value) {
  final parts = value.split(':');
  final hour = parts.isEmpty ? null : int.tryParse(parts[0]);
  final minute = parts.length < 2 ? null : int.tryParse(parts[1]);
  if (hour == null || minute == null) return value;
  return DateFormat('hh:mm a').format(DateTime(2000, 1, 1, hour, minute));
}
