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
    required this.order,
    this.embedded = false,
    super.key,
  });

  final OrderConfirmation order;
  final bool embedded;

  @override
  ConsumerState<UpcomingDeliveriesScreen> createState() =>
      _UpcomingDeliveriesScreenState();
}

class _UpcomingDeliveriesScreenState
    extends ConsumerState<UpcomingDeliveriesScreen> {
  late DateTime _visibleMonth;
  DateTime? _selectedDate;
  List<UpcomingMealDay>? _serviceDays;

  OrderDelivery get _delivery => widget.order.delivery;

  @override
  void initState() {
    super.initState();
    _selectedDate = _initialDeliveryDate();
    final anchor = _selectedDate ?? _delivery.startDate ?? DateTime.now();
    _visibleMonth = DateTime(anchor.year, anchor.month);
  }

  @override
  void didUpdateWidget(covariant UpcomingDeliveriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      _serviceDays = null;
      _selectedDate = _initialDeliveryDate();
      final anchor = _selectedDate ?? _delivery.startDate ?? DateTime.now();
      _visibleMonth = DateTime(anchor.year, anchor.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(upcomingMealDaysProvider(widget.order.id));
    ref.listen(upcomingMealDaysProvider(widget.order.id), (_, next) {
      final loaded = next.asData?.value;
      if (loaded == null) return;
      setState(() {
        _serviceDays = loaded;
        if (_selectedDate != null &&
            loaded.any((d) => _sameDay(d.date, _selectedDate!))) {
          return;
        }
        final today = DateUtils.dateOnly(
          DateTime.now().toUtc().add(const Duration(hours: 3)),
        );
        final upcoming = loaded.where((d) => !d.date.isBefore(today));
        _selectedDate = upcoming.isNotEmpty
            ? upcoming.first.date
            : loaded.lastOrNull?.date;
        if (_selectedDate != null) {
          _visibleMonth = DateTime(_selectedDate!.year, _selectedDate!.month);
        }
      });
    });
    final selectedDay =
        (_serviceDays ?? days.asData?.value ?? const <UpcomingMealDay>[])
            .where(
              (d) => _selectedDate != null && _sameDay(d.date, _selectedDate!),
            )
            .firstOrNull;
    final content = ListView(
      key: const ValueKey('upcomingDeliveriesScreen'),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        if (widget.embedded) ...[
          const Text(
            'Upcoming Meals',
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
        ],
        _Calendar(
          month: _visibleMonth,
          selectedDate: _selectedDate,
          isDeliveryDay: _isDeliveryDay,
          statusForDate: (date) => (_serviceDays ?? const <UpcomingMealDay>[])
              .where((d) => _sameDay(d.date, date))
              .firstOrNull
              ?.status,
          canGoPrevious: _canChangeMonth(-1),
          canGoNext: _canChangeMonth(1),
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
          onSelect: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 16),
        const _CalendarLegend(),
        const SizedBox(height: 18),
        Divider(color: AppColors.darkGreen.withValues(alpha: .09)),
        const SizedBox(height: 12),
        if (_selectedDate case final selected?) ...[
          Text(
            'Delivery for ${DateFormat('EEE, d MMM').format(selected)}',
            key: const ValueKey('selectedDeliveryTitle'),
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (days.isLoading)
            const MealMenuLoading()
          else if (days.hasError)
            MealMenuMessage(
              message: 'We couldn’t load your delivery meals.',
              onRetry: () =>
                  ref.invalidate(upcomingMealDaysProvider(widget.order.id)),
            )
          else if (selectedDay != null)
            DailyMealsPanel(
              key: ValueKey('selectedDay-${selectedDay.id}'),
              request: (
                orderId: widget.order.id,
                dayId: selectedDay.id,
                language: Localizations.localeOf(context).languageCode,
              ),
              date: selected,
              planName: widget.order.plan.name,
            )
          else
            const MealMenuMessage(
              message:
                  'Meals have not been assigned to this delivery yet. Our team will review it.',
            ),
          const SizedBox(height: 12),
          _DeliveryDetails(order: widget.order),
        ] else if (days.isLoading)
          const MealMenuLoading()
        else if (days.hasError)
          MealMenuMessage(
            message: 'We couldn’t load your delivery meals.',
            onRetry: () =>
                ref.invalidate(upcomingMealDaysProvider(widget.order.id)),
          )
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
        title: const Text(
          'Upcoming Meals',
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

  DateTime? _initialDeliveryDate() {
    final start = _dateOnly(_delivery.startDate);
    final end = _dateOnly(_delivery.endDate);
    if (start == null || end == null || _delivery.days.isEmpty) return null;
    final today = _dateOnly(
      DateTime.now().toUtc().add(const Duration(hours: 3)),
    )!;
    var candidate = today.isAfter(start) ? today : start;
    while (!candidate.isAfter(end)) {
      if (_delivery.days.contains(candidate.weekday)) return candidate;
      candidate = candidate.add(const Duration(days: 1));
    }
    return null;
  }

  bool _isDeliveryDay(DateTime date) {
    if (date.weekday == DateTime.friday) return false;
    final loaded = _serviceDays;
    if (loaded != null) return loaded.any((d) => _sameDay(d.date, date));
    final start = _dateOnly(_delivery.startDate);
    final end = _dateOnly(_delivery.endDate);
    if (start == null || end == null) return false;
    return !date.isBefore(start) &&
        !date.isAfter(end) &&
        _delivery.days.contains(date.weekday);
  }

  bool _canChangeMonth(int offset) {
    final target = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
    final start = _delivery.startDate;
    final end = _delivery.endDate;
    if (offset < 0 && start != null) {
      return !target.isBefore(DateTime(start.year, start.month));
    }
    if (offset > 0 && end != null) {
      return !target.isAfter(DateTime(end.year, end.month));
    }
    return true;
  }

  void _changeMonth(int offset) {
    if (!_canChangeMonth(offset)) return;
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.selectedDate,
    required this.isDeliveryDay,
    required this.statusForDate,
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
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.08,
          ),
          itemCount: leading + count,
          itemBuilder: (context, index) {
            if (index < leading) return const SizedBox.shrink();
            final date = DateTime(month.year, month.month, index - leading + 1);
            final delivery = isDeliveryDay(date);
            final status = statusForDate(date);
            final selected =
                selectedDate != null && _sameDay(date, selectedDate!);
            return Tooltip(
              message: status == null
                  ? 'No delivery'
                  : mealDayStatusLabel(status),
              child: Semantics(
                label:
                    '${DateFormat('d MMMM yyyy').format(date)}${status == null ? '' : ', ${mealDayStatusLabel(status)}'}',
                selected: selected,
                child: Center(
                  child: InkWell(
                    key: ValueKey('deliveryDate-${date.toIso8601String()}'),
                    onTap: delivery ? () => onSelect(date) : null,
                    customBorder: const CircleBorder(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: delivery
                            ? status == 'locked'
                                  ? const Color(0xFF63776D)
                                  : status == 'delivered'
                                  ? const Color(0xFF476A5C)
                                  : status == 'customized'
                                  ? const Color(0xFF168176)
                                  : AppColors.emeraldGreen
                            : Colors.transparent,
                        border: selected
                            ? Border.all(color: AppColors.darkGreen, width: 2)
                            : null,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.emeraldGreen.withValues(
                                    alpha: .24,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: delivery
                              ? AppColors.white
                              : AppColors.darkGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
  Widget build(BuildContext context) => const Wrap(
    spacing: 24,
    runSpacing: 8,
    children: [
      _LegendItem(color: AppColors.emeraldGreen, label: 'Delivery days'),
      _LegendItem(color: Color(0xFFE3E3E0), label: 'Non-delivery days'),
      _LegendItem(
        color: AppColors.emeraldGreen,
        label: 'Automatically Selected',
      ),
      _LegendItem(color: Color(0xFF168176), label: 'Customized'),
      _LegendItem(color: Color(0xFF63776D), label: 'Locked'),
      _LegendItem(color: Color(0xFF476A5C), label: 'Delivered'),
    ],
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _LegendDot(color: color),
      const SizedBox(width: 6),
      Flexible(child: Text(label, style: const TextStyle(fontSize: 11))),
    ],
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _DeliveryDetails extends StatelessWidget {
  const _DeliveryDetails({required this.order});

  final OrderConfirmation order;

  @override
  Widget build(BuildContext context) {
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
                child: const Text(
                  'Scheduled',
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
      'No upcoming deliveries are scheduled.',
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
    child: const Row(
      children: [
        Icon(Icons.info_outline_rounded, color: AppColors.jasper, size: 17),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Deliveries run Saturday to Thursday. Friday is a non-delivery day.',
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
