import 'dart:math';

DateTime _date(Object? value) => DateTime.parse(value as String);
String packageDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime packageRestartLimit(DateTime now) {
  final lastDay = DateTime(now.year, now.month + 7, 0).day;
  return DateTime(now.year, now.month + 6, min(now.day, lastDay));
}

class PackagePause {
  PackagePause.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      start = _date(json['pauseStartDate']),
      resume = _date(json['resumeDate']),
      status = json['status'] as String;
  final String id, status;
  final DateTime start, resume;
}

class PackageManagement {
  PackageManagement.fromJson(Map<String, dynamic> json)
    : rowVersion = (json['rowVersion'] as num).toInt(),
      serverNow = _date(json['serverNow']).toUtc(),
      receivedAt = DateTime.now().toUtc(),
      status = json['status'] as String,
      remainingDays = (json['remainingServiceDays'] as num).toInt(),
      nextDelivery = json['nextScheduledDelivery'] == null
          ? null
          : _date(json['nextScheduledDelivery']),
      firstDeliveryAfterPause = json['firstDeliveryAfterPause'] == null
          ? null
          : _date(json['firstDeliveryAfterPause']),
      endDate = _date(json['expectedEndDate']),
      eligibleDates = (json['eligiblePauseDates'] as List)
          .map(_date)
          .toList(growable: false),
      currentPause = json['currentPause'] == null
          ? null
          : PackagePause.fromJson(json['currentPause'] as Map<String, dynamic>),
      canResumeEarly = json['canResumeEarly'] == true,
      latestRequest = json['latestRequest'] is Map<String, dynamic>
          ? PackageChangeRequest.fromJson(
              json['latestRequest'] as Map<String, dynamic>,
            )
          : null;
  final int rowVersion, remainingDays;
  final String status;
  final DateTime serverNow, receivedAt, endDate;
  final DateTime? nextDelivery;
  final DateTime? firstDeliveryAfterPause;
  final List<DateTime> eligibleDates;
  final PackagePause? currentPause;
  final bool canResumeEarly;
  final PackageChangeRequest? latestRequest;
  bool get hasPendingRequest => latestRequest?.status == 'PENDING_APPROVAL';

  DateTime qatarNow({DateTime? utcNow}) {
    final elapsed = (utcNow ?? DateTime.now().toUtc()).difference(receivedAt);
    return serverNow
        .add(elapsed.isNegative ? Duration.zero : elapsed)
        .add(const Duration(hours: 3));
  }

  bool allowsPauseDate(DateTime date, {DateTime? utcNow}) {
    final now = qatarNow(utcNow: utcNow);
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    return day.isAfter(today) &&
        day.weekday != DateTime.friday &&
        eligibleDates.any((d) => packageDate(d) == packageDate(day)) &&
        !(day == today.add(const Duration(days: 1)) && now.hour >= 21);
  }

  DateTime earliestRestartDate({DateTime? utcNow}) {
    final now = qatarNow(utcNow: utcNow);
    return DateTime(now.year, now.month, now.day + (now.hour >= 21 ? 2 : 1));
  }

  DateTime? earliestPauseDate({DateTime? utcNow}) {
    final dates =
        eligibleDates.where((d) => allowsPauseDate(d, utcNow: utcNow)).toList()
          ..sort();
    return dates.firstOrNull;
  }

  DateTime? earliestPauseRestartDate({DateTime? utcNow}) {
    final start = earliestPauseDate(utcNow: utcNow);
    return start?.add(const Duration(days: 1));
  }

  DateTime latestRestartDate({DateTime? utcNow}) {
    return packageRestartLimit(qatarNow(utcNow: utcNow));
  }
}

class PackageChangeRequest {
  PackageChangeRequest.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      type = json['type'] as String,
      status = json['status'] as String,
      start = json['pauseStartDate'] == null
          ? null
          : _date(json['pauseStartDate']),
      resume = json['resumeDate'] == null ? null : _date(json['resumeDate']),
      reviewReason = json['reviewReason'] as String?;
  final String id, type, status;
  final DateTime? start, resume;
  final String? reviewReason;
}

class PackagePausePreview {
  PackagePausePreview.fromJson(Map<String, dynamic> json)
    : rowVersion = (json['rowVersion'] as num).toInt(),
      scheduleVersion = json['scheduleVersion'] as String,
      affectedDays = (json['affectedServiceDays'] as num).toInt(),
      rescheduledDays = (json['rescheduledServiceDays'] as num).toInt(),
      committedDays = (json['preservedCommittedDays'] as num).toInt(),
      remainingDays = (json['remainingServiceDays'] as num?)?.toInt(),
      pauseStartDate = json['pauseStartDate'] == null
          ? null
          : _date(json['pauseStartDate']),
      resumeDate = json['resumeDate'] == null
          ? null
          : _date(json['resumeDate']),
      actualRestartDate = json['actualRestartDate'] == null
          ? null
          : _date(json['actualRestartDate']),
      endDate = _date(json['projectedEndDate']);
  final int rowVersion, affectedDays, rescheduledDays, committedDays;
  final String scheduleVersion;
  final DateTime endDate;
  final int? remainingDays;
  final DateTime? pauseStartDate, resumeDate, actualRestartDate;
}

String packageCommandId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
