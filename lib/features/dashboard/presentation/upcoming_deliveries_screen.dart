import 'package:diet_time/app/localization/customer_copy.dart';
import 'calendar_meal_status.dart';
import 'calendar_day_meals.dart';
import 'tomorrow_menu_section.dart';
import 'package:diet_time/features/dashboard/presentation/package_management_provider.dart';
import 'service_date_cell.dart';
import 'package:diet_time/features/dashboard/domain/calendar_delivery.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/data/upcoming_meals_repository.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/features/dashboard/presentation/daily_meals_panel.dart';
import 'package:flutter/material.dart';
import 'package:diet_time/core/performance/performance_trace.dart';
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
    extends ConsumerState<UpcomingDeliveriesScreen>
    with FirstContentTrace, WidgetsBindingObserver {
  late DateTime _visibleMonth;
  DateTime? _selectedDate;
  bool _selectedByUser = false;
  final Set<DailyMenuRequest> _visitedMenus = {};
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
    WidgetsBinding.instance.addObserver(this);
    _resetDate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _retry();
      for (final request in _visitedMenus) {
        ref.invalidate(dailyMealMenuProvider(request));
      }
    }
  }

  void _resetDate() {
    _selectedByUser = false;
    _selectedDate = _initialDeliveryDate();
    final anchor =
        _selectedDate ??
        _orders.firstOrNull?.delivery.startDate ??
        DateTime.now().toUtc().add(const Duration(hours: 3));
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
      _visitedMenus.clear();
      _resetDate();
    }
  }

  void _acceptDays(String orderId, List<UpcomingMealDay> days) {
    setState(() {
      _serviceDays[orderId] = days;
      final dates = _byDate.keys.toList()..sort();
      if (_selectedByUser ||
          _selectedDate != null && dates.contains(_selectedDate)) {
        return;
      }
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
    ref.listen(packageScheduleChangesProvider, (previous, next) {
      for (final order in _orders) {
        if (previous?[order.id] != next[order.id]) {
          ref.invalidate(upcomingMealDaysProvider(order.id));
          for (final request in _visitedMenus.where(
            (r) => r.orderId == order.id,
          )) {
            ref.invalidate(dailyMealMenuProvider(request));
          }
        }
      }
    });
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
    traceFirstContent('delivery_calendar', ready: !loading && !failed);
    if (!_selectedByUser &&
        !loading &&
        !failed &&
        !byDate.containsKey(_selectedDate)) {
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
    final language = Localizations.localeOf(context).languageCode;
    for (final delivery in selected) {
      _visitedMenus.add((
        orderId: delivery.order.id,
        dayId: delivery.day.id,
        language: language,
      ));
    }
    // Keep visited menus observed for this calendar visit, scoped by order and day.
    final loadedMenus = <DailyMenuRequest, DailyMealMenu>{};
    for (final request in _visitedMenus.where((r) => r.language == language)) {
      final value = ref.watch(dailyMealMenuProvider(request)).asData?.value;
      final day = _serviceDays[request.orderId]
          ?.where((day) => day.id == request.dayId)
          .firstOrNull;
      if (value != null &&
          day != null &&
          DateUtils.isSameDay(value.date, day.date)) {
        loadedMenus[request] = value;
      }
    }
    final content = ListView(
      key: const ValueKey('upcomingDeliveriesScreen'),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        if (widget.embedded) ...[
          Text(
            context.customerCopy('Your Meal Calendar'),
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
        Text(
          context.customerCopy('View and manage your daily meals.'),
          style: const TextStyle(color: Color(0xFF657B72), fontSize: 12),
        ),
        const SizedBox(height: 12),
        _Calendar(
          key: const ValueKey('tourCalendarGrid'),
          month: _visibleMonth,
          selectedDate: _selectedDate,
          isDeliveryDay: _isDeliveryDay,
          statusForDate: (date) {
            final deliveries = byDate[date] ?? const <CalendarDelivery>[];
            final states = deliveries.map((d) {
              final menu =
                  loadedMenus[(
                    orderId: d.order.id,
                    dayId: d.day.id,
                    language: language,
                  )];
              return calendarMealStatus(
                date: date,
                status: menu?.status ?? d.day.status,
                selectionStatus: menu?.selectionStatus ?? d.day.selectionStatus,
                deliveryStatus: menu?.deliveryStatus ?? d.day.deliveryStatus,
                locked: menu?.selectionLocked ?? d.day.selectionLocked,
                editable: menu?.editable ?? d.day.canEdit,
                deadlinePassed:
                    menu?.deadlinePassed ??
                    (d.day.cutoffAt != null &&
                        !DateTime.now().toUtc().isBefore(
                          d.day.cutoffAt!.toUtc(),
                        )),
              );
            }).toSet();
            if (states.contains(CalendarMealStatus.actionNeeded)) {
              return 'actionNeeded';
            }
            return states.length == 1
                ? states.single.name
                : deliveries.isEmpty
                ? null
                : 'mixed';
          },
          countForDate: (date) => byDate[date]?.length ?? 0,
          canGoPrevious: _canChangeMonth(-1),
          canGoNext: _canChangeMonth(1),
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
          onSelect: (date) => setState(() {
            _selectedByUser = true;
            _selectedDate = date;
          }),
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
            DateFormat(
              'EEEE, d MMMM',
              Localizations.localeOf(context).toLanguageTag(),
            ).format(date),
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
            Column(
              children: [
                Text(
                  context.customerCopy('No Meals Scheduled'),
                  style: const TextStyle(
                    color: Color(0xFF79847E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.customerCopy('No meals are scheduled for this day.'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF79847E),
                  ),
                ),
              ],
            )
          else ...[
            Text(
              '${selected.length} scheduled ${selected.length == 1 ? 'delivery' : 'deliveries'}',
              key: const ValueKey('scheduledDeliveryCount'),
            ),
            const SizedBox(height: 12),
            if (selected.every(
              (d) => loadedMenus.containsKey((
                orderId: d.order.id,
                dayId: d.day.id,
                language: language,
              )),
            )) ...[
              CalendarNutritionSummary(
                meals: selected.expand(
                  (d) =>
                      loadedMenus[(
                            orderId: d.order.id,
                            dayId: d.day.id,
                            language: language,
                          )]!
                          .selected,
                ),
              ),
              const SizedBox(height: 10),
            ],
            for (final delivery in selected) _orderCard(delivery, date),
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
          _EmptyDelivery(noPlan: _orders.isEmpty),
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
          context.customerCopy('Your Meal Calendar'),
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

  Widget _orderCard(CalendarDelivery delivery, DateTime date) {
    final day = delivery.day;
    final order = delivery.order;
    return Container(
      key: ValueKey('calendarOrder-${order.id}-${day.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E9E2)),
      ),
      child: Column(
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
            calendarMode: true,
            showCalendarNutrition: false,
            onReview: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) =>
                    TomorrowMenuSection(orderId: order.id, reviewOnly: true),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _DeliveryDetails(order: order),
        ],
      ),
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

  bool _isDeliveryDay(DateTime date) => _byDate.containsKey(date);

  bool _canChangeMonth(int offset) {
    final target = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
    final dates = [
      ..._orders
          .map((o) => offset < 0 ? o.delivery.startDate : o.delivery.endDate)
          .whereType<DateTime>(),
      for (final days in _serviceDays.values) ...days.map((day) => day.date),
    ]..sort();
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
                DateFormat(
                  'MMMM yyyy',
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(month),
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
                48 +
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
                      : context.customerCopy('Non-service day')}, ${status == null ? '' : context.customerCopy(CalendarMealStatus.values.where((value) => value.name == status).firstOrNull?.label ?? 'Scheduled')}',
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
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 8,
    children: [
      for (final status in [
        CalendarMealStatus.actionNeeded,
        CalendarMealStatus.confirmed,
        CalendarMealStatus.selectedForYou,
        CalendarMealStatus.scheduled,
        CalendarMealStatus.noMeals,
      ])
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 13, color: status.color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                context.customerCopy(status.label),
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
    ],
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
  const _EmptyDelivery({this.noPlan = false});
  final bool noPlan;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    alignment: Alignment.center,
    child: Text(
      context.customerCopy(
        noPlan
            ? 'No active meal plan.'
            : 'No upcoming deliveries are scheduled.',
      ),
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

String serviceDeliveryLabel(String status) => switch (status) {
  'DELIVERED' => 'Delivered',
  'PREPARING' => 'Being prepared',
  'OUT_FOR_DELIVERY' => 'On the way',
  'CANCELLED' => 'Cancelled',
  'SKIPPED' => 'Skipped',
  'CONFIRMED' => 'Scheduled',
  _ => 'Scheduled',
};
