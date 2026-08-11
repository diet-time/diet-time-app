import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpcomingDeliveriesScreen extends StatefulWidget {
  const UpcomingDeliveriesScreen({required this.order, super.key});

  final OrderConfirmation order;

  @override
  State<UpcomingDeliveriesScreen> createState() =>
      _UpcomingDeliveriesScreenState();
}

class _UpcomingDeliveriesScreenState extends State<UpcomingDeliveriesScreen> {
  late DateTime _visibleMonth;
  DateTime? _selectedDate;

  OrderDelivery get _delivery => widget.order.delivery;

  @override
  void initState() {
    super.initState();
    _selectedDate = _initialDeliveryDate();
    final anchor = _selectedDate ?? _delivery.startDate ?? DateTime.now();
    _visibleMonth = DateTime(anchor.year, anchor.month);
  }

  @override
  Widget build(BuildContext context) {
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
          'Upcoming Deliveries',
          style: TextStyle(
            color: AppColors.darkGreen,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        key: const ValueKey('upcomingDeliveriesScreen'),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          _Calendar(
            month: _visibleMonth,
            selectedDate: _selectedDate,
            isDeliveryDay: _isDeliveryDay,
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
            _DeliveryDetails(order: widget.order),
          ] else
            const _EmptyDelivery(),
          const SizedBox(height: 14),
          const _FridayNotice(),
        ],
      ),
    );
  }

  DateTime? _initialDeliveryDate() {
    final start = _dateOnly(_delivery.startDate);
    final end = _dateOnly(_delivery.endDate);
    if (start == null || end == null || _delivery.days.isEmpty) return null;
    final today = _dateOnly(DateTime.now())!;
    var candidate = today.isAfter(start) ? today : start;
    while (!candidate.isAfter(end)) {
      if (_delivery.days.contains(candidate.weekday)) return candidate;
      candidate = candidate.add(const Duration(days: 1));
    }
    return null;
  }

  bool _isDeliveryDay(DateTime date) {
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
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime? selectedDate;
  final bool Function(DateTime) isDeliveryDay;
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
            Text(
              DateFormat('MMMM yyyy').format(month),
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
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
            final selected =
                selectedDate != null && _sameDay(date, selectedDate!);
            return Center(
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
                    color: delivery ? AppColors.jasper : Colors.transparent,
                    border: selected
                        ? Border.all(color: AppColors.darkGreen, width: 2)
                        : null,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.jasper.withValues(alpha: .24),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: delivery ? AppColors.white : AppColors.darkGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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
  Widget build(BuildContext context) => Row(
    children: [
      const _LegendDot(color: AppColors.jasper),
      const SizedBox(width: 6),
      const Text('Delivery days', style: TextStyle(fontSize: 11)),
      const SizedBox(width: 24),
      const _LegendDot(color: Color(0xFFE3E3E0)),
      const SizedBox(width: 6),
      const Text('Non-delivery days', style: TextStyle(fontSize: 11)),
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
          if (order.meals.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            const Text(
              'Meals',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final meal in order.meals) _MealRow(meal: meal),
          ],
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal});

  final OrderMeal meal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.jasper.withValues(alpha: .09),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.room_service_outlined,
            color: AppColors.jasper,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                meal.quantity > 1
                    ? '${meal.quantity} meals included'
                    : 'Included in your plan',
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .62),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.cream.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.restaurant_rounded,
            color: AppColors.emeraldGreen,
            size: 20,
          ),
        ),
      ],
    ),
  );
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
            'Delivery times may slightly change on Fridays',
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
