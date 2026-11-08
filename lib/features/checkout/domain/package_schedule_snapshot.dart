class PackageScheduleSnapshot {
  PackageScheduleSnapshot.fromJson(Map<String, dynamic> json)
    : displayStatus = json['displayStatus'] as String,
      pauseApprovalStatus = json['pauseApprovalStatus'] as String?,
      pauseStart = DateTime.tryParse(json['pauseStartDate']?.toString() ?? ''),
      resume = DateTime.tryParse(json['resumeDate']?.toString() ?? ''),
      revisedEnd = DateTime.parse(json['revisedEndDate'] as String),
      remainingDays = (json['remainingServiceDays'] as num).toInt(),
      nextDelivery = DateTime.tryParse(
        json['nextScheduledDelivery']?.toString() ?? '',
      ),
      tomorrowScheduled = json['tomorrowScheduled'] == true,
      dashboardEligible = json['dashboardEligible'] as bool?,
      dashboardStatus = json['dashboardStatus'] as String?,
      dashboardExclusionReason = json['dashboardExclusionReason'] as String?,
      serverNow = DateTime.tryParse(json['serverNow']?.toString() ?? '');
  final String displayStatus;
  final String? pauseApprovalStatus;
  final DateTime? pauseStart, resume, nextDelivery;
  final DateTime revisedEnd;
  final int remainingDays;
  final bool tomorrowScheduled;
  final bool? dashboardEligible;
  final String? dashboardStatus, dashboardExclusionReason;
  final DateTime? serverNow;
}
