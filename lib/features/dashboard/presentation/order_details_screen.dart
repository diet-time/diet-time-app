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
      backgroundColor: const Color(0xFFF7F6F1),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFF7F6F1),
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton.filledTonal(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
          ),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: AppColors.darkGreen,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.darkGreen.withValues(alpha: .08),
                ),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.emeraldGreen,
                size: 19,
              ),
            ),
          ),
        ],
      ),
      body: order.when(
        loading: () => const _OrderDetailsLoading(),
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
    final address = delivery.address;
    return ListView(
      key: const ValueKey('orderDetails'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 30),
      children: [
        _OrderHeaderCard(order: order),
        const SizedBox(height: 12),
        _SectionCard(
          children: [
            _InformationRow(
              icon: Icons.calendar_month_outlined,
              label: 'PLAN PERIOD',
              value: _period(delivery.startDate, delivery.endDate),
            ),
            _InformationRow(
              icon: Icons.restaurant_rounded,
              label: 'MEALS INCLUDED',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final meal in order.meals)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.emeraldGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${meal.name} x ${meal.quantity}',
                              style: const _ValueStyle(),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _InformationRow(
              icon: Icons.event_available_outlined,
              label: 'DELIVERY DAYS',
              value:
                  '${delivery.daysPerWeek} Days / Week\n${_weekdays(delivery.days)}',
            ),
            _InformationRow(
              icon: Icons.location_on_outlined,
              label: 'DELIVERY ADDRESS',
              value: [
                address.displayName,
                address.area,
                address.streetLine,
                address.formattedAddress,
              ].where((value) => value.trim().isNotEmpty).join('\n'),
            ),
            _InformationRow(
              icon: Icons.schedule_rounded,
              label: 'DELIVERY TIME',
              value:
                  '${delivery.timeSlot.name}\n${_time(delivery.timeSlot.startTime)} - ${_time(delivery.timeSlot.endTime)}',
              last: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.payments_outlined,
                label: 'PRICING',
                value:
                    '${formatMealPlanPriceAmount(order.pricing.totalAmount, locale)} ${order.pricing.currencyCode}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.credit_card_rounded,
                label: 'PAYMENT STATUS',
                value: _titleCase(order.paymentStatus),
                accent: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SupportBar(orderNumber: order.orderNumber),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.teaGreen.withValues(alpha: .2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.emeraldGreen.withValues(alpha: .1),
            ),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.emeraldGreen,
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.white,
                  size: 19,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thank you for your order!',
                      style: TextStyle(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your plan and delivery schedule are confirmed above.',
                      style: TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({required this.order});

  final OrderConfirmation order;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('orderDetailsHeader'),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFEAF4EC)],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: .1)),
      boxShadow: [
        BoxShadow(
          color: AppColors.darkGreen.withValues(alpha: .04),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                color: AppColors.emeraldGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('ORDER NUMBER'),
                  const SizedBox(height: 4),
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Divider(
            height: 1,
            color: AppColors.darkGreen.withValues(alpha: .08),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('STATUS'),
                  const SizedBox(height: 6),
                  _StatusPill(order.status),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 42,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.darkGreen.withValues(alpha: .08),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('PLAN'),
                  const SizedBox(height: 5),
                  Text(
                    order.plan.name,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (order.plan.durationName.isNotEmpty)
                    Text(
                      order.plan.durationName,
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(alpha: .56),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.darkGreen.withValues(alpha: .07)),
      boxShadow: [
        BoxShadow(
          color: AppColors.darkGreen.withValues(alpha: .035),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(children: children),
  );
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    this.value,
    this.child,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? child;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: AppColors.teaGreen.withValues(alpha: .25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.emeraldGreen, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label(label),
                  const SizedBox(height: 4),
                  child ??
                      Text(
                        value?.trim().isNotEmpty == true ? value! : '—',
                        style: const _ValueStyle(),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (!last)
        Divider(height: 1, color: AppColors.darkGreen.withValues(alpha: .07)),
    ],
  );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 96),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.darkGreen.withValues(alpha: .07)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                color: AppColors.teaGreen.withValues(alpha: .26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.emeraldGreen, size: 15),
            ),
            const SizedBox(width: 8),
            Expanded(child: _Label(label)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: accent
              ? const EdgeInsets.symmetric(horizontal: 9, vertical: 4)
              : EdgeInsets.zero,
          decoration: accent
              ? BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(99),
                )
              : null,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SupportBar extends StatelessWidget {
  const _SupportBar({required this.orderNumber});

  final String orderNumber;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.darkGreen,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Expanded(
          child: _SupportAction(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Need Help?',
            onTap: () => _showSupport(context),
          ),
        ),
        Container(
          width: 1,
          height: 34,
          color: AppColors.white.withValues(alpha: .15),
        ),
        Expanded(
          child: _SupportAction(
            icon: Icons.support_agent_rounded,
            label: 'Contact Support',
            onTap: () => _showSupport(context),
          ),
        ),
      ],
    ),
  );

  void _showSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please reference order $orderNumber.')),
    );
  }
}

class _SupportAction extends StatelessWidget {
  const _SupportAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.white, size: 16),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Label extends Text {
  const _Label(super.data)
    : super(
        style: const TextStyle(
          color: Color(0xFF83928D),
          fontSize: 8,
          letterSpacing: .65,
          fontWeight: FontWeight.w900,
        ),
      );
}

class _ValueStyle extends TextStyle {
  const _ValueStyle()
    : super(
        color: AppColors.darkGreen,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w800,
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.teaGreen.withValues(alpha: .3),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.emeraldGreen,
          size: 12,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            status,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.emeraldGreen,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _OrderDetailsLoading extends StatelessWidget {
  const _OrderDetailsLoading();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      for (final height in [145.0, 420.0, 96.0]) ...[
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.darkGreen.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
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
        const Icon(Icons.receipt_long_outlined, color: AppColors.emeraldGreen),
        const SizedBox(height: 12),
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

String _titleCase(String value) {
  final words = value.replaceAll('_', ' ').trim().toLowerCase().split(' ');
  return words
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
