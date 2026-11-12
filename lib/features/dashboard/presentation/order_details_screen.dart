import 'package:diet_time/features/checkout/domain/order_status.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:diet_time/app/localization/customer_copy.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:diet_time/core/performance/performance_trace.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/dashboard/presentation/package_management_panel.dart';
import 'package:diet_time/features/dashboard/presentation/package_management_provider.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';

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
    with WidgetsBindingObserver, FirstContentTrace {
  String get orderId => widget.orderId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(orderDetailsProvider(orderId));
      ref.invalidate(packageManagementProvider(orderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailsProvider(orderId));
    traceFirstContent('order_details', ready: order.hasValue);
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
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    final management =
        order.rowVersion > 0 &&
            const {'CONFIRMED', 'ACTIVE', 'PAUSED'}.contains(order.status)
        ? ref.watch(packageManagementProvider(order.id)).asData?.value
        : null;
    final next = management?.nextDelivery;
    // Dashboard and order-detail requests may complete at different revisions.
    // A cached pause response must not replace the newer persisted plan period.
    final planEnd =
        management != null && management.rowVersion >= order.rowVersion
        ? management.endDate
        : delivery.endDate;
    final pause = management?.currentPause;
    final today = management?.qatarNow();
    final nextAvailable =
        next != null &&
        today != null &&
        !const {
          'COMPLETED',
          'CANCELLED',
          'REJECTED',
        }.contains(management?.status) &&
        !DateUtils.dateOnly(next).isBefore(DateUtils.dateOnly(today)) &&
        !(pause != null &&
            const {
              'PAUSED',
              'PAUSE_SCHEDULED',
            }.contains(management?.effectiveDisplayStatus) &&
            !next.isBefore(pause.start) &&
            next.isBefore(pause.resume));
    final slot = [
      delivery.timeSlot.name.trim(),
      [
        delivery.timeSlot.startTime,
        delivery.timeSlot.endTime,
      ].where((value) => value.trim().isNotEmpty).map(_time).join(' – '),
    ].where((value) => value.isNotEmpty).join(' · ');
    return ListView(
      key: const ValueKey('orderDetails'),
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        30 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        if (order.canRequestCancellation)
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
                await ref
                    .read(customerDashboardControllerProvider.notifier)
                    .refresh();
              } catch (error) {
                if (error is ApiException &&
                    error.code == 'ORDER_CANCELLATION_NOT_ALLOWED') {
                  ref.invalidate(orderDetailsProvider(order.id));
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error is ApiException &&
                                error.code == 'ORDER_CANCELLATION_NOT_ALLOWED'
                            ? lookupAppLocalizations(
                                Localizations.localeOf(context),
                              ).packageCancellationBlocked
                            : context.customerCopy(
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
        _SectionCard(
          children: [
            _OrderHeaderCard(
              order: order,
              status: management?.effectiveDisplayStatus == 'PAUSED'
                  ? 'PAUSED'
                  : order.status == 'PAUSED' && management != null
                  ? 'ACTIVE'
                  : order.status,
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ServiceTile(
                      icon: Icons.event_available_outlined,
                      label: context.customerCopy(
                        order.isTakeaway ? 'Next Pickup' : 'Next Delivery',
                      ),
                      value: nextAvailable
                          ? DateFormat.yMMMd(locale).format(next)
                          : context.customerCopy(
                              management == null &&
                                      !const {
                                        'COMPLETED',
                                        'CANCELLED',
                                        'REJECTED',
                                      }.contains(order.status)
                                  ? 'Schedule unavailable'
                                  : 'No upcoming service',
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ServiceTile(
                      icon: Icons.calendar_today_outlined,
                      label: copy.packageRemainingDays,
                      value: management == null
                          ? (const {
                                  'COMPLETED',
                                  'CANCELLED',
                                  'REJECTED',
                                }.contains(order.status)
                                ? copy.packagePauseDayCount(0)
                                : '—')
                          : copy.packagePauseDayCount(management.remainingDays),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            if (const {'CANCELLED', 'REJECTED'}.contains(order.status))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  context.customerCopy(orderCustomerMessage(order.status)),
                  style: const TextStyle(fontSize: 12, height: 1.4),
                ),
              ),
            _InformationRow(
              key: const ValueKey('orderPlanPeriod'),
              icon: Icons.calendar_month_outlined,
              label: context.customerCopy('PLAN PERIOD'),
              value: _period(delivery.startDate, planEnd, locale),
            ),
            _InformationRow(
              icon: Icons.event_available_outlined,
              label: copy.orderServiceDays,
              value: _weekdays(context, delivery.days),
            ),
            _InformationRow(
              key: const ValueKey('orderFulfillmentDetails'),
              icon: Icons.location_on_outlined,
              label: order.isTakeaway
                  ? copy.orderPickupLocation
                  : copy.orderDeliveryAddress,
              value: order.isTakeaway
                  ? [
                          order.takeawayBranch?.name ??
                              lookupAppLocalizations(
                                Localizations.localeOf(context),
                              ).orderBranchUnavailable,
                          order.takeawayBranch?.address,
                        ]
                        .whereType<String>()
                        .where((v) => v.trim().isNotEmpty)
                        .join('\n')
                  : [
                      address.area,
                      if (address.buildingNo.isNotEmpty ||
                          address.streetNo.isNotEmpty ||
                          address.zoneNo.isNotEmpty)
                        address.streetLine,
                      if (address.unitNumber?.isNotEmpty == true)
                        address.unitNumber!,
                      if (address.buildingNo.isEmpty &&
                          address.streetNo.isEmpty &&
                          address.zoneNo.isEmpty)
                        address.formattedAddress,
                    ].where((v) => v.trim().isNotEmpty).toSet().join('\n'),
              last: slot.isEmpty,
            ),
            if (slot.isNotEmpty)
              _InformationRow(
                icon: Icons.schedule_rounded,
                label: context.customerCopy(
                  order.isTakeaway ? 'Pickup time' : 'DELIVERY TIME',
                ),
                value: slot,
                last: true,
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MetricTile(
                    label: context.customerCopy('Total amount'),
                    value:
                        '${formatMealPlanPriceAmount(order.pricing.totalAmount, locale)} ${order.pricing.currencyCode}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: context.customerCopy('PAYMENT STATUS'),
                    value: context.customerCopy(order.paymentLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (order.rowVersion > 0 &&
            const {'CONFIRMED', 'ACTIVE', 'PAUSED'}.contains(order.status))
          PackageManagementPanel(
            orderId: order.id,
            serviceWeekdays: delivery.days.isEmpty
                ? null
                : delivery.days.toSet(),
            onChanged: () => ref.invalidate(orderDetailsProvider(order.id)),
          ),
        const SizedBox(height: 10),
        const _SupportBar(),
      ],
    );
  }
}

class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({required this.order, required this.status});

  final OrderConfirmation order;
  final String status;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('orderDetailsHeader'),
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                order.plan.name,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _StatusPill(status),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          [
            order.entitlement.label(
              Localizations.localeOf(context).languageCode,
            ),
            order.plan.durationName,
          ].where((v) => v.isNotEmpty).join(' · '),
          style: const TextStyle(
            color: Color(0xFF657B72),
            fontSize: 12,
            height: 1.4,
          ),
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
    key: const ValueKey('orderMasterCard'),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    this.value,
    this.last = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
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
  const _MetricTile({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 4),
        Text(value, style: const _ValueStyle()),
      ],
    ),
  );
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F6F2),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: AppColors.emeraldGreen),
            const SizedBox(width: 5),
            Expanded(child: _Label(label)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const _ValueStyle()),
      ],
    ),
  );
}

class _SupportBar extends StatelessWidget {
  const _SupportBar();
  @override
  Widget build(BuildContext context) => TextButton.icon(
    key: const ValueKey('orderContactSupport'),
    icon: const Icon(Icons.support_agent_rounded),
    label: Text(context.customerCopy('Need help? Contact Support')),
    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lookupAppLocalizations(
            Localizations.localeOf(context),
          ).orderSupportPending,
        ),
      ),
    ),
    style: TextButton.styleFrom(
      foregroundColor: AppColors.emeraldGreen,
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
  );
}

class _Label extends Text {
  const _Label(super.data)
    : super(
        style: const TextStyle(
          color: Color(0xFF83928D),
          fontSize: 10,
          letterSpacing: .2,
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
    'PAUSED' => const Color(0xFF69736F),
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
              fontSize: 11,
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
      for (final height in [330.0, 180.0, 48.0]) ...[
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

String _period(DateTime? start, DateTime? end, String locale) {
  if (start == null || end == null) return '—';
  return '${DateFormat.MMMd(locale).format(start)} – ${DateFormat.yMMMd(locale).format(end)}';
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
