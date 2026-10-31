import 'package:diet_time/features/checkout/domain/order_status.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:diet_time/app/localization/customer_copy.dart';
import 'dart:async';
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

class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen>
    with WidgetsBindingObserver {
  Timer? _refresh;
  String get orderId => widget.orderId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.invalidate(orderDetailsProvider(orderId)));
    _refresh = Timer.periodic(
      const Duration(seconds: 30),
      (_) => ref.invalidate(orderDetailsProvider(orderId)),
    );
  }

  @override
  void dispose() {
    _refresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(orderDetailsProvider(orderId));
    }
  }

  @override
  Widget build(BuildContext context) {
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
            tooltip: context.customerCopy('Back'),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
          ),
        ),
        title: Text(
          context.customerCopy('Order Details'),
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

class _OrderDetails extends ConsumerWidget {
  const _OrderDetails({required this.order});

  final OrderConfirmation order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final delivery = order.delivery;
    final address = delivery.address;
    return ListView(
      key: const ValueKey('orderDetails'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 30),
      children: [
        _OrderHeaderCard(order: order),
        if (order.rowVersion > 0 &&
            ['PENDING_APPROVAL', 'ON_HOLD', 'CONFIRMED'].contains(order.status))
          TextButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: Text(context.customerCopy('Request cancellation')),
            onPressed: () async {
              final reason = await showDialog<String>(
                context: context,
                builder: (_) => const _CancelReasonDialog(),
              );
              if (reason == null || !context.mounted) return;
              try {
                await ref
                    .read(ordersRepositoryProvider)
                    .cancelOrder(order.id, order.rowVersion, reason);
                ref.invalidate(orderDetailsProvider(order.id));
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.customerCopy(
                          'The order could not be cancelled. Refresh the order or contact Diet Time.',
                        ),
                      ),
                    ),
                  );
                }
              }
            },
          ),
        if (order.reviewMessage != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.customerCopy(order.reviewMessage!)),
            ),
          ),
        Text(
          order.isTakeaway && order.takeawayBranch != null
              ? '${context.customerCopy('Takeaway')} · ${order.takeawayBranch!.name}${order.takeawayBranch!.address == null ? '' : '\n${order.takeawayBranch!.address}'}'
              : order.fulfillmentLabel,
        ),
        const SizedBox(height: 12),
        _SectionCard(
          children: [
            _InformationRow(
              icon: Icons.calendar_month_outlined,
              label: context.customerCopy('PLAN PERIOD'),
              value: _period(delivery.startDate, delivery.endDate),
            ),
            _InformationRow(
              icon: Icons.restaurant_rounded,
              label: context.customerCopy('MEALS INCLUDED'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.entitlement.label(
                      Localizations.localeOf(context).languageCode,
                    ),
                    style: const _ValueStyle(),
                  ),
                ],
              ),
            ),
            _InformationRow(
              icon: Icons.event_available_outlined,
              label: order.isTakeaway
                  ? context.customerCopy('COLLECTION DAYS')
                  : context.customerCopy('DELIVERY DAYS'),
              value:
                  '${lookupAppLocalizations(Localizations.localeOf(context)).customerDaysPerWeek(delivery.daysPerWeek)}\n${_weekdays(context, delivery.days)}',
            ),
            if (!order.isTakeaway)
              _InformationRow(
                icon: Icons.location_on_outlined,
                label: context.customerCopy('DELIVERY ADDRESS'),
                value: [
                  address.displayName,
                  address.area,
                  address.streetLine,
                  address.formattedAddress,
                ].where((value) => value.trim().isNotEmpty).join('\n'),
              ),
            if (!order.isTakeaway)
              _InformationRow(
                icon: Icons.schedule_rounded,
                label: context.customerCopy('DELIVERY TIME'),
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
                label: context.customerCopy('PRICING'),
                value:
                    '${formatMealPlanPriceAmount(order.pricing.totalAmount, locale)} ${order.pricing.currencyCode}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.credit_card_rounded,
                label: context.customerCopy('PAYMENT STATUS'),
                value: context.customerCopy(order.paymentLabel),
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
          child: Row(
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
                      context.customerCopy('Thank you for your order!'),
                      style: TextStyle(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      context.customerCopy(
                        order.status == 'PENDING_APPROVAL'
                            ? "Your order has been received and is awaiting confirmation from Diet Time. We'll notify you once it's reviewed."
                            : 'Your plan and delivery schedule are confirmed above.',
                      ),
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
                  _Label(context.customerCopy('ORDER NUMBER')),
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
                  _Label(context.customerCopy('STATUS')),
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
                  _Label(context.customerCopy('PLAN')),
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
            label: context.customerCopy('Need Help?'),
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
            label: context.customerCopy('Contact Support'),
            onTap: () => _showSupport(context),
          ),
        ),
      ],
    ),
  );

  void _showSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lookupAppLocalizations(
            Localizations.localeOf(context),
          ).customerOrderReference(orderNumber),
        ),
      ),
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

  Color get color => switch (status) {
    'PENDING_APPROVAL' => const Color(0xFF8A5100),
    'ON_HOLD' => const Color(0xFF954515),
    'REJECTED' => const Color(0xFFB3261E),
    'CANCELLED' => const Color(0xFF575757),
    _ => AppColors.emeraldGreen,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          switch (status) {
            'PENDING_APPROVAL' => Icons.schedule_rounded,
            'ON_HOLD' || 'PAUSED' => Icons.pause_circle_outline,
            'REJECTED' || 'CANCELLED' => Icons.cancel_outlined,
            _ => Icons.check_circle_rounded,
          },
          color: color,
          size: 12,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            status == 'PENDING_APPROVAL'
                ? lookupAppLocalizations(
                    Localizations.localeOf(context),
                  ).dashboardPendingApproval
                : context.customerCopy(orderStatusLabel(status)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
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
        Text(context.customerCopy("We couldn't load this order.")),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(context.customerCopy('TRY AGAIN')),
        ),
      ],
    ),
  );
}

String _period(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '—';
  return '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
}

String _weekdays(BuildContext context, List<int> days) {
  final labels = {
    1: context.customerCopy('Mon'),
    2: context.customerCopy('Tue'),
    3: context.customerCopy('Wed'),
    4: context.customerCopy('Thu'),
    5: context.customerCopy('Fri'),
    6: context.customerCopy('Sat'),
    7: context.customerCopy('Sun'),
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

class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog();
  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final reason = TextEditingController();
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.customerCopy('Cancel this order?')),
    content: TextField(
      controller: reason,
      maxLength: 500,
      minLines: 2,
      maxLines: 4,
      decoration: InputDecoration(labelText: context.customerCopy('Reason')),
      onChanged: (_) => setState(() {}),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.customerCopy('Keep order')),
      ),
      FilledButton(
        onPressed: reason.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, reason.text.trim()),
        child: Text(context.customerCopy('Confirm cancellation')),
      ),
    ],
  );
}
