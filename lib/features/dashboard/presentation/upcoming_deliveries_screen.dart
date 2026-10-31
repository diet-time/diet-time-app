import 'package:diet_time/app/localization/customer_copy.dart';
import 'package:diet_time/features/plans/domain/meal_entitlement.dart';
import 'service_date_cell.dart';
import 'package:diet_time/features/dashboard/domain/calendar_delivery.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/data/upcoming_meals_repository.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/features/dashboard/presentation/daily_meals_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class UpcomingDeliveriesScreen extends ConsumerStatefulWidget {
  const UpcomingDeliveriesScreen({
    this.order,
    this.orders = const [],
    this.embedded = false,
    super.key,
  });
  final OrderConfirmation? order;
  final List<OrderConfirmation> orders;
  final bool embedded;

  @override
  ConsumerState<UpcomingDeliveriesScreen> createState() =>
      _UpcomingDeliveriesScreenState();
}

class _UpcomingDeliveriesScreenState
    extends ConsumerState<UpcomingDeliveriesScreen> {
  late DateTime _visibleMonth;
  DateTime? _selectedDate;
  final Map<String, List<UpcomingMealDay>> _serviceDays = {};
  List<OrderConfirmation> get _orders => [
    ?widget.order,
    ...widget.orders,
  ].where((o) => o.status != 'CANCELLED').toList();

  Map<DateTime, List<CalendarDelivery>> get _byDate => deliveriesByDate([
    for (final order in _orders)
      for (final day in _serviceDays[order.id] ?? <UpcomingMealDay>[])
        CalendarDelivery(order: order, day: day),
  ]);

  @override
  void initState() {
    super.initState();
    _resetDate();
  }

  void _resetDate() {
    _selectedDate = _initialDeliveryDate();
    final anchor =
        _selectedDate ??
        _orders.firstOrNull?.delivery.startDate ??
        DateTime.now();
    _visibleMonth = DateTime(anchor.year, anchor.month);
  }

  @override
  void didUpdateWidget(covariant UpcomingDeliveriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = [
      oldWidget.order?.id,
      ...oldWidget.orders.map((o) => o.id),
    ].join(',');
    final ids = [widget.order?.id, ...widget.orders.map((o) => o.id)].join(',');
    if (oldIds != ids) {
      _serviceDays.clear();
      _resetDate();
    }
  }

  void _acceptDays(String orderId, List<UpcomingMealDay> days) {
    setState(() {
      _serviceDays[orderId] = days;
      final dates = _byDate.keys.toList()..sort();
      if (_selectedDate != null && dates.contains(_selectedDate)) return;
      final today = DateUtils.dateOnly(
        DateTime.now().toUtc().add(const Duration(hours: 3)),
      );
      _selectedDate =
          dates.where((date) => !date.isBefore(today)).firstOrNull ??
          dates.lastOrNull;
      if (_selectedDate != null) {
        _visibleMonth = DateTime(_selectedDate!.year, _selectedDate!.month);
      }
    });
  }

  void _retry() {
    for (final order in _orders) {
      ref.invalidate(upcomingMealDaysProvider(order.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    var loading = false;
    var failed = false;
    for (final order in _orders) {
      final provider = upcomingMealDaysProvider(order.id);
      final result = ref.watch(provider);
      loading |= result.isLoading;
      failed |= result.hasError;
      if (result.asData?.value case final loaded?) {
        _serviceDays[order.id] = loaded;
      }
      ref.listen(provider, (_, next) {
        if (next.asData?.value case final loaded?) {
          _acceptDays(order.id, loaded);
        }
      });
    }
    final byDate = _byDate;
    if (!loading && !failed && !byDate.containsKey(_selectedDate)) {
      final dates = byDate.keys.toList()..sort();
      final today = DateUtils.dateOnly(
        DateTime.now().toUtc().add(const Duration(hours: 3)),
      );
      _selectedDate =
          dates.where((date) => !date.isBefore(today)).firstOrNull ??
          dates.lastOrNull;
      if (_selectedDate case final selected?) {
        _visibleMonth = DateTime(selected.year, selected.month);
      }
    }
    final selected = byDate[_selectedDate] ?? const <CalendarDelivery>[];
    final content = ListView(
      key: const ValueKey('upcomingDeliveriesScreen'),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        if (widget.embedded) ...[
          Text(
            context.customerCopy('Upcoming Meals'),
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
        ],
        _Calendar(
          key: const ValueKey('tourCalendarGrid'),
          month: _visibleMonth,
          selectedDate: _selectedDate,
          isDeliveryDay: _isDeliveryDay,
          statusForDate: (date) {
            final deliveries = byDate[date] ?? const <CalendarDelivery>[];
            final statuses = deliveries.map((d) => d.day.status).toSet();
            return statuses.length == 1
                ? statuses.single
                : deliveries.isEmpty
                ? null
                : 'mixed';
          },
          countForDate: (date) => byDate[date]?.length ?? 0,
          canGoPrevious: _canChangeMonth(-1),
          canGoNext: _canChangeMonth(1),
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
          onSelect: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 16),
        const KeyedSubtree(
          key: ValueKey('tourCalendarLegend'),
          child: _CalendarLegend(),
        ),
        const SizedBox(height: 18),
        Divider(color: AppColors.darkGreen.withValues(alpha: .09)),
        const SizedBox(height: 12),
        if (_selectedDate case final date?) ...[
          Text(
            'Meals for ${DateFormat('EEE, d MMM').format(date)}',
            key: const ValueKey('selectedDeliveryTitle'),
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (failed)
            MealMenuMessage(
              message: context.customerCopy(
                'We couldn’t load all your delivery meals.',
              ),
              onRetry: _retry,
            )
          else if (loading)
            const MealMenuLoading()
          else if (selected.isEmpty)
            MealMenuMessage(
              message: context.customerCopy(
                'Meals have not been assigned to this delivery yet. Our team will review it.',
              ),
            )
          else ...[
            Text(
              '${selected.length} scheduled ${selected.length == 1 ? 'delivery' : 'deliveries'}',
              key: const ValueKey('scheduledDeliveryCount'),
            ),
            const SizedBox(height: 12),
            for (final delivery in selected)
              _orderCard(delivery, date, expandable: selected.length > 1),
          ],
        ] else if (failed)
          MealMenuMessage(
            message: context.customerCopy(
              'We couldn’t load all your delivery meals.',
            ),
            onRetry: _retry,
          )
        else if (loading)
          const MealMenuLoading()
        else
          const _EmptyDelivery(),
        const SizedBox(height: 14),
        const _FridayNotice(),
      ],
    );
    if (widget.embedded) {
      return ColoredBox(color: const Color(0xFFFBFAF7), child: content);
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFBFAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFAF7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          key: const ValueKey('upcomingDeliveriesBack'),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
        title: Text(
          context.customerCopy('Upcoming Meals'),
          style: TextStyle(
            color: AppColors.darkGreen,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: content,
    );
  }

  Widget _orderCard(
    CalendarDelivery delivery,
    DateTime date, {
    required bool expandable,
  }) {
    final day = delivery.day;
    final order = delivery.order;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DailyMealsPanel(
          key: ValueKey('selectedDay-${order.id}-${day.id}'),
          request: (
            orderId: order.id,
            dayId: day.id,
            language: Localizations.localeOf(context).languageCode,
          ),
          date: date,
          planName: order.plan.name,
        ),
        const SizedBox(height: 12),
        _DeliveryDetails(order: order),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: expandable
          ? Card(
              key: ValueKey('calendarOrder-${order.id}-${day.id}'),
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                key: PageStorageKey('calendar-${order.id}-${day.id}'),
                initiallyExpanded: true,
                title: Text(
                  order.plan.name,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    if (day.mealCount != null)
                      Text(
                        MealEntitlement(
                          day.mealCount!,
                          day.snackCount ?? 0,
                        ).label(Localizations.localeOf(context).languageCode),
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 4),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _StatusChip(
                          label: context.customerCopy(
                            mealDayStatusLabel(day.status),
                          ),
                          icon: serviceStatusIcon(day.status),
                        ),
                        if (day.selectionStatus == 'AUTO_FINALIZED')
                          _StatusChip(
                            label: context.customerCopy('Meals chosen for you'),
                            icon: Icons.auto_awesome_outlined,
                          ),
                        if (day.selectionStatus == 'CUSTOMER_CONFIRMED')
                          _StatusChip(
                            label: context.customerCopy(
                              'Your choices confirmed',
                            ),
                            icon: Icons.check_circle_outline,
                          ),
                        if (day.selectionLocked && day.status != 'locked')
                          _StatusChip(
                            label: context.customerCopy('Locked'),
                            icon: Icons.lock_outline_rounded,
                          ),
                        if (day.deliveryStatus != 'PLANNED')
                          _StatusChip(
                            label: context.customerCopy(
                              serviceDeliveryLabel(day.deliveryStatus),
                            ),
                            icon: day.deliveryStatus == 'DELIVERED'
                                ? Icons.check_circle_outline
                                : Icons.local_shipping_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
                children: [
                  Padding(padding: const EdgeInsets.all(12), child: details),
                ],
              ),
            )
          : details,
    );
  }

  DateTime? _initialDeliveryDate() {
    final today = DateUtils.dateOnly(
      DateTime.now().toUtc().add(const Duration(hours: 3)),
    );
    final candidates = <DateTime>[];
    for (final order in _orders) {
      final start = _dateOnly(order.delivery.startDate);
      final end = _dateOnly(order.delivery.endDate);
      if (start == null || end == null || order.delivery.days.isEmpty) continue;
      var date = today.isAfter(start) ? today : start;
      while (!date.isAfter(end)) {
        if (date.weekday != DateTime.friday &&
            order.delivery.days.contains(date.weekday)) {
          candidates.add(date);
          break;
        }
        date = date.add(const Duration(days: 1));
      }
    }
    candidates.sort();
    return candidates.firstOrNull;
  }

  bool _isDeliveryDay(DateTime date) {
    if (date.weekday == DateTime.friday) return false;
    if (_byDate.containsKey(date)) return true;
    return _orders.any((order) {
      if (_serviceDays.containsKey(order.id)) return false;
      final start = _dateOnly(order.delivery.startDate);
      final end = _dateOnly(order.delivery.endDate);
      return start != null &&
          end != null &&
          !date.isBefore(start) &&
          !date.isAfter(end) &&
          order.delivery.days.contains(date.weekday);
    });
  }

  bool _canChangeMonth(int offset) {
    final target = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
    final dates =
        _orders
            .map((o) => offset < 0 ? o.delivery.startDate : o.delivery.endDate)
            .whereType<DateTime>()
            .toList()
          ..sort();
    if (dates.isEmpty) return false;
    final bound = offset < 0 ? dates.first : dates.last;
    final month = DateTime(bound.year, bound.month);
    return offset < 0 ? !target.isBefore(month) : !target.isAfter(month);
  }

  void _changeMonth(int offset) {
    if (_canChangeMonth(offset)) {
      setState(
        () => _visibleMonth = DateTime(
          _visibleMonth.year,
          _visibleMonth.month + offset,
        ),
      );
    }
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.isDeliveryDay,
    required this.statusForDate,
    required this.countForDate,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime? selectedDate;
  final bool Function(DateTime) isDeliveryDay;
  final String? Function(DateTime) statusForDate;
  final int Function(DateTime) countForDate;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final count = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - DateTime.monday;
    final weekdayNames = [
      context.customerCopy('Mon'),
      context.customerCopy('Tue'),
      context.customerCopy('Wed'),
      context.customerCopy('Thu'),
      context.customerCopy('Fri'),
      context.customerCopy('Sat'),
      context.customerCopy('Sun'),
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy').format(month),
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _MonthButton(
              key: const ValueKey('previousDeliveryMonth'),
              icon: Icons.chevron_left_rounded,
              enabled: canGoPrevious,
              onPressed: onPrevious,
            ),
            const SizedBox(width: 4),
            _MonthButton(
              key: const ValueKey('nextDeliveryMonth'),
              icon: Icons.chevron_right_rounded,
              enabled: canGoNext,
              onPressed: onNext,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final name in weekdayNames)
              Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .72),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent:
                64 +
                (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(
                      0,
                      double.infinity,
                    ) *
                    32,
          ),
          itemCount: leading + count,
          itemBuilder: (context, index) {
            if (index < leading) return const SizedBox.shrink();
            final date = DateTime(month.year, month.month, index - leading + 1);
            final delivery = isDeliveryDay(date);
            final status = statusForDate(date);
            final count = countForDate(date);
            final selected =
                selectedDate != null && _sameDay(date, selectedDate!);
            return ServiceDateCell(
              date: date,
              service: delivery,
              selected: selected,
              count: count,
              status: status,
              label:
                  '${DateFormat('d MMMM yyyy').format(date)}, ${count > 0
                      ? '$count scheduled orders'
                      : delivery
                      ? context.customerCopy('Service day')
                      : context.customerCopy('Non-service day')}, ${status == null ? '' : context.customerCopy(mealDayStatusLabel(status))}',
              onTap: () => onSelect(date),
            );
          },
        ),
      ],
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: enabled ? onPressed : null,
    visualDensity: VisualDensity.compact,
    iconSize: 20,
    icon: Icon(icon),
  );
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final item in [
          (Icons.event_outlined, context.customerCopy('Service day')),
          (Icons.remove, context.customerCopy('Non-service')),
          (Icons.auto_awesome_outlined, context.customerCopy('Auto-selected')),
          (Icons.tune_rounded, context.customerCopy('Customized')),
          (Icons.lock_outline_rounded, context.customerCopy('Locked')),
          (Icons.check_circle_outline, context.customerCopy('Delivered')),
        ])
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Row(
              children: [
                Icon(item.$1, size: 14, color: AppColors.darkGreen),
                const SizedBox(width: 5),
                Text(
                  item.$2,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _DeliveryDetails extends StatelessWidget {
  const _DeliveryDetails({required this.order});

  final OrderConfirmation order;

  @override
  Widget build(BuildContext context) {
    if (order.isTakeaway) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            [
              context.customerCopy('Takeaway'),
              order.takeawayBranch?.name ??
                  context.customerCopy('Collect from Diet Time'),
              if (order.takeawayBranch?.address?.trim().isNotEmpty == true)
                order.takeawayBranch!.address!,
            ].join(' · '),
          ),
        ),
      );
    }
    final slot = order.delivery.timeSlot;
    final address = order.delivery.address;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkGreen.withValues(alpha: .06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.wb_sunny_outlined,
                color: AppColors.jasper,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.name.isEmpty ? 'Delivery' : slot.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (slot.startTime.isNotEmpty ||
                        slot.endTime.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        _timeRange(slot),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (_addressLine(address).isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        address.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _addressLine(address),
                        style: TextStyle(
                          color: AppColors.darkGreen.withValues(alpha: .68),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F6E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.customerCopy('Scheduled'),
                  style: TextStyle(
                    color: AppColors.emeraldGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyDelivery extends StatelessWidget {
  const _EmptyDelivery();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    alignment: Alignment.center,
    child: Text(
      context.customerCopy('No upcoming deliveries are scheduled.'),
      style: TextStyle(color: AppColors.darkGreen.withValues(alpha: .6)),
    ),
  );
}

class _FridayNotice extends StatelessWidget {
  const _FridayNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: AppColors.jasper.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline_rounded, color: AppColors.jasper, size: 17),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            context.customerCopy(
              'Service runs Saturday to Thursday. Friday is a non-service day.',
            ),
            style: TextStyle(
              color: AppColors.jasper,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

DateTime? _dateOnly(DateTime? value) =>
    value == null ? null : DateTime(value.year, value.month, value.day);

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _timeRange(OrderTimeSlot slot) {
  final start = _time(slot.startTime);
  final end = _time(slot.endTime);
  if (start.isEmpty) return end;
  if (end.isEmpty) return start;
  return '$start – $end';
}

String _time(String value) {
  final parts = value.split(':');
  final hour = parts.isEmpty ? null : int.tryParse(parts[0]);
  final minute = parts.length < 2 ? null : int.tryParse(parts[1]);
  if (hour == null || minute == null) return value;
  return DateFormat('hh:mm a').format(DateTime(2000, 1, 1, hour, minute));
}

String _addressLine(OrderAddress address) => [
  address.area,
  if (address.buildingNo.isNotEmpty ||
      address.streetNo.isNotEmpty ||
      address.zoneNo.isNotEmpty)
    address.streetLine,
].where((value) => value.trim().isNotEmpty).join('\n');

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE9F1E5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.darkGreen),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.darkGreen),
          ),
        ),
      ],
    ),
  );
}

String serviceDeliveryLabel(String status) => switch (status) {
  'DELIVERED' => 'Delivered',
  'PREPARING' => 'Being prepared',
  'OUT_FOR_DELIVERY' => 'On the way',
  'CANCELLED' => 'Cancelled',
  'SKIPPED' => 'Skipped',
  'CONFIRMED' => 'Scheduled',
  _ => 'Scheduled',
};
