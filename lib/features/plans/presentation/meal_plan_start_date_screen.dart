import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
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
  late DateTime _visibleMonth;

  DateTime get _today => dateOnly(widget.today ?? DateTime.now());

  DateTime get _earliestStartDate {
    final package = widget.selection.pricingOption;
    final leadDate = _today.add(Duration(days: package.startDateLeadTimeDays));
    final configured = package.earliestStartDate;
    if (configured == null) return leadDate;
    final normalized = dateOnly(configured);
    return normalized.isAfter(leadDate) ? normalized : leadDate;
  }

  @override
  void initState() {
    super.initState();
    final earliest = _earliestStartDate;
    _visibleMonth = DateTime(earliest.year, earliest.month);
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
      _visibleMonth = DateTime(date.year, date.month);
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
    final selected = await showDatePicker(
      context: context,
      helpText: 'Choose your start date',
      initialDate: _schedule?.startDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(firstDate.year + 2, firstDate.month, firstDate.day),
      selectableDayPredicate: _isValidStart,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.emeraldGreen,
            onPrimary: AppColors.white,
            surface: const Color(0xFFF5F3E9),
            onSurface: AppColors.darkGreen,
          ),
        ),
        child: child!,
      ),
    );
    if (selected != null) _selectStartDate(selected);
  }

  Future<void> _continue() async {
    final schedule = _schedule;
    if (schedule == null) return;
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
      route: AppRoutes.home,
      planCode: plan.code,
      planName: plan.name,
      mealPlanTemplateId: plan.id,
      mealPlanPriceId: widget.selection.pricingOption.mealPlanPriceId,
    );
    if (authenticated) {
      ref.read(otpAuthControllerProvider.notifier).begin(destination);
      context.go(AppRoutes.home);
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
                        Text(
                          _schedule == null
                              ? 'Tap an available day below to choose your start date.'
                              : 'Tap another available day to change your start date.',
                          key: const ValueKey('calendarInstruction'),
                          style: TextStyle(
                            color: AppColors.emeraldGreen.withValues(
                              alpha: .82,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ServiceCalendar(
                          visibleMonth: _visibleMonth,
                          earliestStartDate: _earliestStartDate,
                          schedule: _schedule,
                          isUnavailable: _isUnavailable,
                          onSelect: _selectStartDate,
                          onPreviousMonth: () => setState(() {
                            _visibleMonth = DateTime(
                              _visibleMonth.year,
                              _visibleMonth.month - 1,
                            );
                          }),
                          onNextMonth: () => setState(() {
                            _visibleMonth = DateTime(
                              _visibleMonth.year,
                              _visibleMonth.month + 1,
                            );
                          }),
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
  });
  final DateTime visibleMonth;
  final DateTime earliestStartDate;
  final MealPlanServiceSchedule? schedule;
  final bool Function(DateTime) isUnavailable;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkGreen.withValues(alpha: .12)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('previousMonth'),
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                const Spacer(),
                const Text(
                  'Select a delivery day',
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  key: const ValueKey('nextMonth'),
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
          ),
          for (var index = 0; index < monthCount; index++)
            _CalendarMonth(
              month: DateTime(visibleMonth.year, visibleMonth.month + index),
              earliestStartDate: earliestStartDate,
              schedule: schedule,
              isUnavailable: isUnavailable,
              onSelect: onSelect,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 13),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: Color(0xFF9A9DA2),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Unavailable days are skipped and do not count toward your service days.',
                    style: TextStyle(
                      color: AppColors.darkGreen.withValues(alpha: .5),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
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
    required this.earliestStartDate,
    required this.schedule,
    required this.isUnavailable,
    required this.onSelect,
  });
  final DateTime month;
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
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 15),
      child: Column(
        children: [
          Text(
            DateFormat('MMMM yyyy').format(month),
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
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
        : end
        ? AppColors.jazzberryJam
        : service
        ? const Color(0xFFDFF1E3)
        : unavailable
        ? const Color(0xFFE5E5E5)
        : Colors.transparent;
    final foreground = start || end
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
