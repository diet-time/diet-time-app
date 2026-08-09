import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

typedef MealPlanDateContinue =
    void Function(
      MealPlanPurchaseSelection selection,
      MealPlanServiceSchedule schedule,
    );

class MealPlanStartDateScreen extends ConsumerStatefulWidget {
  const MealPlanStartDateScreen({
    required this.selection,
    this.onContinue,
    this.today,
    super.key,
  });

  final MealPlanPurchaseSelection selection;
  final MealPlanDateContinue? onContinue;
  final DateTime? today;

  @override
  ConsumerState<MealPlanStartDateScreen> createState() =>
      _MealPlanStartDateScreenState();
}

class _MealPlanStartDateScreenState
    extends ConsumerState<MealPlanStartDateScreen> {
  MealPlanServiceSchedule? _schedule;

  DateTime get _today => dateOnly(widget.today ?? DateTime.now());

  DateTime get _earliestStartDate {
    final package = widget.selection.pricingOption;
    final leadDate = _today.add(Duration(days: package.startDateLeadTimeDays));
    final configured = package.earliestStartDate;
    if (configured == null) return leadDate;
    final normalized = dateOnly(configured);
    return normalized.isAfter(leadDate) ? normalized : leadDate;
  }

  bool _isUnavailable(DateTime date) {
    final package = widget.selection.pricingOption;
    return package.nonDeliveryWeekdays.contains(date.weekday) ||
        package.unavailableDates.any((item) => dateKey(item) == dateKey(date));
  }

  bool _isValidStart(DateTime date) =>
      !dateOnly(date).isBefore(_earliestStartDate) && !_isUnavailable(date);

  void _selectStartDate(DateTime date) {
    if (!_isValidStart(date)) return;
    final package = widget.selection.pricingOption;
    final schedule = calculateMealPlanServiceSchedule(
      startDate: date,
      serviceDays: widget.selection.serviceDays,
      nonDeliveryWeekdays: package.nonDeliveryWeekdays,
      unavailableDates: package.unavailableDates,
    );
    setState(() {
      _schedule = schedule;
    });
  }

  DateTime get _firstSelectableDate {
    var candidate = _earliestStartDate;
    while (_isUnavailable(candidate)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  Future<void> _openStartDatePicker() async {
    final firstDate = _firstSelectableDate;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.darkGreen.withValues(alpha: .22),
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          widthFactor: 1,
          heightFactor: .78,
          child: _StartDateBottomSheet(
            initialMonth: _schedule?.startDate ?? firstDate,
            earliestStartDate: _earliestStartDate,
            schedule: _schedule,
            isUnavailable: _isUnavailable,
            calculateSchedule: (date) {
              final package = widget.selection.pricingOption;
              return calculateMealPlanServiceSchedule(
                startDate: date,
                serviceDays: widget.selection.serviceDays,
                nonDeliveryWeekdays: package.nonDeliveryWeekdays,
                unavailableDates: package.unavailableDates,
              );
            },
            onSelect: _selectStartDate,
          ),
        ),
      ),
    );
  }

  Future<void> _showCalendarFromInstruction() => _openStartDatePicker();
  Future<void> _continue() async {
    final schedule = _schedule;
    if (schedule == null) return;
    ref
        .read(checkoutControllerProvider.notifier)
        .begin(widget.selection, schedule);
    if (widget.onContinue case final callback?) {
      callback(widget.selection, schedule);
      return;
    }
    final authenticated = await ref
        .read(otpAuthControllerProvider.notifier)
        .restoreSession();
    if (!mounted) return;
    final plan = widget.selection.mealPlan;
    final destination = PendingAuthDestination(
      route: AppRoutes.planSummary,
      planCode: plan.code,
      planName: plan.name,
      mealPlanTemplateId: plan.id,
      mealPlanPriceId: widget.selection.pricingOption.mealPlanPriceId,
    );
    if (authenticated) {
      ref.read(otpAuthControllerProvider.notifier).begin(destination);
      context.push(AppRoutes.planSummary);
    } else {
      context.push(AppRoutes.phoneLogin, extra: destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = widget.selection;
    return ColoredBox(
      color: const Color(0xFFF5F3E9),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            key: const ValueKey('startDateBack'),
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            'Diet Time',
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Choose your start date',
                          key: ValueKey('startDateTitle'),
                          style: TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 27,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _DateFields(
                          schedule: _schedule,
                          onChooseStartDate: _openStartDatePicker,
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          key: const ValueKey('calendarInstruction'),
                          onTap: _showCalendarFromInstruction,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.touch_app_rounded,
                                  size: 16,
                                  color: AppColors.emeraldGreen,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _schedule == null
                                        ? 'Tap to choose an available delivery day.'
                                        : 'Tap to choose a different delivery day.',
                                    style: TextStyle(
                                      color: AppColors.emeraldGreen.withValues(
                                        alpha: .82,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                color: const Color(0xE6F5F3E9),
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${selection.pricingOption.name} · '
                          '${selection.serviceDays} service days · '
                          '${selection.mealCombination.name}',
                          key: const ValueKey('startDateSummary'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.darkGreen.withValues(alpha: .68),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${selection.pricingOption.currencyCode} '
                          '${formatMealPlanPriceAmount(selection.totalPrice, Localizations.localeOf(context).toLanguageTag())}',
                          key: const ValueKey('startDateTotalPrice'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.emeraldGreen,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          key: const ValueKey('startDateContinue'),
                          label: 'Continue →',
                          onPressed: _schedule == null ? null : _continue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateFields extends StatelessWidget {
  const _DateFields({required this.schedule, required this.onChooseStartDate});
  final MealPlanServiceSchedule? schedule;
  final VoidCallback onChooseStartDate;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    return Row(
      children: [
        Expanded(
          child: _ReadOnlyDateField(
            label: 'Start date',
            value: schedule == null
                ? 'Select a date'
                : formatter.format(schedule!.startDate),
            active: schedule != null,
            fieldKey: const ValueKey('startDateField'),
            onTap: onChooseStartDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ReadOnlyDateField(
            label: 'End date',
            value: schedule == null
                ? 'Calculated automatically'
                : formatter.format(schedule!.endDate),
            fieldKey: const ValueKey('endDateField'),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyDateField extends StatelessWidget {
  const _ReadOnlyDateField({
    required this.label,
    required this.value,
    required this.fieldKey,
    this.active = false,
    this.onTap,
  });
  final String label;
  final String value;
  final Key fieldKey;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: active ? AppColors.emeraldGreen : AppColors.darkGreen,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 5),
      Material(
        key: fieldKey,
        color: active ? const Color(0xFFE7F4E8) : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: active
                ? AppColors.emeraldGreen
                : AppColors.darkGreen.withValues(alpha: .1),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 2,
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(
                          alpha: active ? 1 : .5,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: AppColors.emeraldGreen,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _ServiceCalendar extends StatelessWidget {
  const _ServiceCalendar({
    required this.visibleMonth,
    required this.earliestStartDate,
    required this.schedule,
    required this.isUnavailable,
    required this.onSelect,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDone,
  });
  final DateTime visibleMonth;
  final DateTime earliestStartDate;
  final MealPlanServiceSchedule? schedule;
  final bool Function(DateTime) isUnavailable;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback? onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final end = schedule?.endDate;
    final calculatedMonthCount = end == null
        ? 1
        : (end.year - visibleMonth.year) * 12 +
              end.month -
              visibleMonth.month +
              1;
    final monthCount = calculatedMonthCount < 1 ? 1 : calculatedMonthCount;
    return Container(
      key: const ValueKey('serviceCalendar'),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: .12),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkGreen.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 8, 7),
            child: Row(
              children: [
                const SizedBox(width: 48),
                const Expanded(
                  child: Text(
                    'Select a delivery day',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('closeCalendar'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 21),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('previousMonth'),
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(visibleMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('nextMonth'),
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const _CalendarWeekdays(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  for (var index = 0; index < monthCount; index++) ...[
                    _CalendarMonth(
                      month: DateTime(
                        visibleMonth.year,
                        visibleMonth.month + index,
                      ),
                      showMonthHeader: index > 0,
                      earliestStartDate: earliestStartDate,
                      schedule: schedule,
                      isUnavailable: isUnavailable,
                      onSelect: onSelect,
                    ),
                    if (index < monthCount - 1)
                      const Divider(indent: 20, endIndent: 20),
                  ],
                  if (schedule case final selectedSchedule?)
                    _SelectedDurationSummary(schedule: selectedSchedule),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 7,
                      children: [
                        const _CalendarLegend(
                          color: AppColors.emeraldGreen,
                          label: 'Selected start date',
                        ),
                        const _CalendarLegend(
                          color: Color(0xFFDFF1E3),
                          label: 'Plan delivery day',
                        ),
                        const _CalendarLegend(
                          color: Color(0xFFE9EAEB),
                          label: 'Friday unavailable',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: AppButton(
              key: const ValueKey('confirmCalendar'),
              label: schedule == null ? 'Select a start date' : 'Done',
              onPressed: onDone,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarMonth extends StatelessWidget {
  const _CalendarMonth({
    required this.month,
    required this.showMonthHeader,
    required this.earliestStartDate,
    required this.schedule,
    required this.isUnavailable,
    required this.onSelect,
  });
  final DateTime month;
  final bool showMonthHeader;
  final DateTime earliestStartDate;
  final MealPlanServiceSchedule? schedule;
  final bool Function(DateTime) isUnavailable;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - DateTime.monday;
    final cells = ((leading + days + 6) ~/ 7) * 7;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 14),
      child: Column(
        children: [
          if (showMonthHeader) ...[
            const SizedBox(height: 10),
            Text(
              DateFormat('MMMM yyyy').format(month),
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const _CalendarWeekdays(),
          ],
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.05,
            ),
            itemCount: cells,
            itemBuilder: (context, index) {
              final day = index - leading + 1;
              if (day < 1 || day > days) return const SizedBox.shrink();
              final date = DateTime(month.year, month.month, day);
              return _CalendarDay(
                date: date,
                beforeEarliest: date.isBefore(earliestStartDate),
                unavailable: isUnavailable(date),
                schedule: schedule,
                onSelect: onSelect,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.beforeEarliest,
    required this.unavailable,
    required this.schedule,
    required this.onSelect,
  });
  final DateTime date;
  final bool beforeEarliest;
  final bool unavailable;
  final MealPlanServiceSchedule? schedule;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final key = dateKey(date);
    final start = schedule != null && dateKey(schedule!.startDate) == key;
    final end = schedule != null && dateKey(schedule!.endDate) == key;
    final service =
        schedule?.serviceDates.any((item) => dateKey(item) == key) ?? false;
    final disabled = beforeEarliest || unavailable;
    final background = start
        ? AppColors.emeraldGreen
        : service || end
        ? const Color(0xFFDFF1E3)
        : disabled
        ? const Color(0xFFE9EAEB)
        : const Color(0xFFF0F8F2);
    final foreground = start
        ? AppColors.white
        : disabled
        ? AppColors.darkGreen.withValues(alpha: .28)
        : AppColors.darkGreen;
    return Semantics(
      label: DateFormat('dd MMMM yyyy').format(date),
      button: !disabled,
      enabled: !disabled,
      child: InkWell(
        key: ValueKey('calendarDay-$key'),
        onTap: disabled ? null : () => onSelect(date),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
            border: unavailable && !beforeEarliest
                ? Border.all(color: AppColors.darkGreen.withValues(alpha: .12))
                : null,
          ),
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: service || start || end
                  ? FontWeight.w900
                  : FontWeight.w600,
              decoration: unavailable ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _StartDateBottomSheet extends StatefulWidget {
  const _StartDateBottomSheet({
    required this.initialMonth,
    required this.earliestStartDate,
    required this.schedule,
    required this.isUnavailable,
    required this.calculateSchedule,
    required this.onSelect,
  });

  final DateTime initialMonth;
  final DateTime earliestStartDate;
  final MealPlanServiceSchedule? schedule;
  final bool Function(DateTime) isUnavailable;
  final MealPlanServiceSchedule? Function(DateTime) calculateSchedule;
  final ValueChanged<DateTime> onSelect;

  @override
  State<_StartDateBottomSheet> createState() => _StartDateBottomSheetState();
}

class _StartDateBottomSheetState extends State<_StartDateBottomSheet> {
  late DateTime _month;
  MealPlanServiceSchedule? _schedule;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.initialMonth.year, widget.initialMonth.month);
    _schedule = widget.schedule;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: _ServiceCalendar(
      visibleMonth: _month,
      earliestStartDate: widget.earliestStartDate,
      schedule: _schedule,
      isUnavailable: widget.isUnavailable,
      onSelect: _select,
      onPreviousMonth: _isFirstMonth
          ? null
          : () => setState(() {
              _month = DateTime(_month.year, _month.month - 1);
            }),
      onNextMonth: () => setState(() {
        _month = DateTime(_month.year, _month.month + 1);
      }),
      onDone: _schedule == null ? null : () => Navigator.of(context).pop(),
    ),
  );

  void _select(DateTime date) {
    final schedule = widget.calculateSchedule(date);
    if (schedule == null) return;
    setState(() {
      _month = DateTime(date.year, date.month);
      _schedule = schedule;
    });
    widget.onSelect(date);
  }

  bool get _isFirstMonth =>
      _month.year == widget.earliestStartDate.year &&
      _month.month == widget.earliestStartDate.month;
}

class _CalendarWeekdays extends StatelessWidget {
  const _CalendarWeekdays();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    child: Row(
      children: [
        for (final day in ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'])
          Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF777B82),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    ),
  );
}

class _SelectedDurationSummary extends StatelessWidget {
  const _SelectedDurationSummary({required this.schedule});

  final MealPlanServiceSchedule schedule;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('selectedDurationSummary'),
    margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F4E8),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.date_range_rounded, color: AppColors.emeraldGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${schedule.serviceDates.length} delivery days selected',
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${DateFormat('dd MMM yyyy').format(schedule.startDate)} - ${DateFormat('dd MMM yyyy').format(schedule.endDate)}',
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .65),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          color: AppColors.darkGreen.withValues(alpha: .58),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
