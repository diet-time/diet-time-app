import 'package:flutter/material.dart';

enum CalendarMealStatus {
  actionNeeded('Action Needed', Icons.schedule_rounded),
  confirmed('Confirmed', Icons.check_circle_outline),
  selectedForYou('Selected for You', Icons.auto_awesome_outlined),
  scheduled('Scheduled', Icons.event_outlined),
  closed('Selection Closed', Icons.event_available_outlined),
  noMeals('No Meals Scheduled', Icons.remove_rounded);

  const CalendarMealStatus(this.label, this.icon);
  final String label;
  final IconData icon;

  Color get color => this == actionNeeded
      ? const Color(0xFF895C25)
      : this == noMeals
      ? const Color(0xFF79847E)
      : const Color(0xFF17684F);
}

/// Calendar presentation of existing service and selection states.
CalendarMealStatus calendarMealStatus({
  required DateTime date,
  required String status,
  String? selectionStatus,
  String deliveryStatus = 'PLANNED',
  bool locked = false,
  bool? editable,
  bool deadlinePassed = false,
}) {
  if (const {
        'CANCELLED',
        'SKIPPED',
        'PAUSED',
        'SUSPENDED',
        'DISPLACED',
        'NO_DELIVERY',
      }.contains(deliveryStatus.toUpperCase()) ||
      const {
        'CANCELLED',
        'SKIPPED',
        'PAUSED',
        'SUSPENDED',
        'DISPLACED',
        'NO_DELIVERY',
      }.contains(status.toUpperCase())) {
    return CalendarMealStatus.noMeals;
  }
  if (selectionStatus == 'CUSTOMER_CONFIRMED') {
    return CalendarMealStatus.confirmed;
  }
  if (selectionStatus == 'AUTO_FINALIZED') {
    return CalendarMealStatus.selectedForYou;
  }
  if (locked ||
      deadlinePassed ||
      const {'DELIVERED', 'COLLECTED'}.contains(deliveryStatus.toUpperCase()) ||
      const {'DELIVERED', 'COLLECTED'}.contains(status.toUpperCase())) {
    return CalendarMealStatus.closed;
  }
  final now = DateTime.now().toUtc().add(const Duration(hours: 3));
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  if (DateUtils.isSameDay(date, tomorrow) && editable == true) {
    return CalendarMealStatus.actionNeeded;
  }
  if (DateUtils.dateOnly(date).isAfter(tomorrow)) {
    return CalendarMealStatus.scheduled;
  }
  if (status.toUpperCase() == 'LOCKED' || selectionStatus == 'LOCKED') {
    return CalendarMealStatus.closed;
  }
  if (status == 'auto_selected' || selectionStatus == 'DEFAULT_PENDING') {
    return CalendarMealStatus.selectedForYou;
  }
  return CalendarMealStatus.scheduled;
}
