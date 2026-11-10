import 'dart:async';
import 'package:diet_time/app/localization/customer_copy.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/dashboard/data/upcoming_meals_repository.dart';
import 'package:diet_time/features/dashboard/domain/package_management.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/dashboard/presentation/package_management_provider.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

String _dateLabel(BuildContext context, DateTime? date) => date == null
    ? '—'
    : DateFormat.yMMMd(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(date);

String _packageError(BuildContext context, Object? error) {
  final copy = lookupAppLocalizations(Localizations.localeOf(context));
  if (error is ApiException) {
    final message = switch (error.code) {
      'pause_date_unavailable' ||
      'schedule_changed' ||
      'order_changed' => copy.packageEligibilityChanged,
      'invalid_resume_date' => copy.packageInvalidRestart,
      'schedule_review_required' => copy.packageReviewRequired,
      'no_eligible_service_days' => copy.packageUnavailable,
      'pause_already_scheduled' => copy.packageAlreadyPaused,
      'package_not_active' => copy.packageNotActive,
      'package_request_pending' => copy.packageRequestPending,
      _ => null,
    };
    if (message != null) return message;
    if ((error.statusCode == 400 || error.statusCode == 409) &&
        error.message?.trim().isNotEmpty == true) {
      return error.message!;
    }
  }
  return copy.packageScheduleChanged;
}

class PackageManagementPanel extends ConsumerStatefulWidget {
  const PackageManagementPanel({
    required this.orderId,
    this.planName,
    this.onChanged,
    super.key,
  });
  final String orderId;
  final String? planName;
  final VoidCallback? onChanged;
  @override
  ConsumerState<PackageManagementPanel> createState() =>
      _PackageManagementPanelState();
}

class _PackageManagementPanelState
    extends ConsumerState<PackageManagementPanel> {
  Timer? _eligibilityRefresh;
  bool _busy = false;
  String? _resumeCommand, _resumePause;
  DateTime? _resumeDate;
  @override
  void dispose() {
    _eligibilityRefresh?.cancel();
    super.dispose();
  }

  void _refreshAtBoundary(PackageManagement data) {
    _eligibilityRefresh?.cancel();
    final now = data.qatarNow();
    var boundary = DateTime.utc(now.year, now.month, now.day, 21);
    if (!boundary.isAfter(now)) {
      boundary = DateTime.utc(now.year, now.month, now.day + 1);
    }
    _eligibilityRefresh = Timer(
      boundary.difference(now) + const Duration(milliseconds: 100),
      () {
        if (mounted) ref.invalidate(packageManagementProvider(widget.orderId));
      },
    );
  }

  void _changed() {
    ref.invalidate(packageManagementProvider(widget.orderId));
    ref.invalidate(upcomingMealDaysProvider(widget.orderId));
    ref.read(packageScheduleChangesProvider.notifier).changed(widget.orderId);
    widget.onChanged?.call();
    unawaited(ref.read(customerDashboardControllerProvider.notifier).refresh());
  }

  void _failure([Object? error]) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_packageError(context, error))));
    ref.invalidate(packageManagementProvider(widget.orderId));
  }

  Future<void> _pause() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final data = await repository.getPackageManagement(widget.orderId);
      if (!mounted) return;
      final start = data.earliestPauseDate();
      if (start == null) {
        _failure(
          const ApiException(
            ApiFailure.conflict,
            code: 'no_eligible_service_days',
          ),
        );
        return;
      }
      final first = start.add(const Duration(days: 1));
      final last = data.latestRestartDate();
      if (first.isAfter(last)) {
        _failure(
          const ApiException(
            ApiFailure.validation,
            code: 'invalid_resume_date',
          ),
        );
        return;
      }
      final restart = await showDatePicker(
        context: context,
        initialDate: first,
        firstDate: first,
        lastDate: last,
        currentDate: data.qatarNow(),
        helpText: lookupAppLocalizations(
          Localizations.localeOf(context),
        ).packageResumeDate,
      );
      if (!mounted || restart == null) return;
      final result = await showDialog<PackageManagement>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PauseDialog(
          orderId: widget.orderId,
          start: start,
          initialResume: restart,
          remainingDays: data.remainingDays,
          repository: repository,
          qatarNow: data.qatarNow,
        ),
      );
      // A committed command can lose its network response. Refresh after dismissing an error too.
      if (mounted) {
        _changed();
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lookupAppLocalizations(
                  Localizations.localeOf(context),
                ).packagePauseSuccess,
              ),
            ),
          );
        }
      }
    } catch (error) {
      _failure(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resume(PackageManagement data) async {
    if (_busy || data.currentPause == null) return;
    setState(() => _busy = true);
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    final now = data.qatarNow();
    final first = data.earliestRestartDate();
    final last = data.latestRestartDate();
    if (first.isAfter(last)) {
      setState(() => _busy = false);
      return;
    }
    final restart = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: first,
      lastDate: last,
      currentDate: now,
      helpText: copy.packageResumeDate,
    );
    if (!mounted) return;
    if (restart == null) {
      setState(() => _busy = false);
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(copy.packageResumeEarly),
        content: Text(
          '${copy.packageResumeDate}: ${_dateLabel(context, restart)}\n${copy.packageResumeConfirmation}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.customerCopy('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(copy.packageResumeEarly),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (accepted != true) {
      setState(() => _busy = false);
      return;
    }
    if (_resumePause != data.currentPause!.id || _resumeDate != restart) {
      _resumePause = data.currentPause!.id;
      _resumeDate = restart;
      _resumeCommand = packageCommandId();
    }
    try {
      await ref
          .read(ordersRepositoryProvider)
          .resumePackage(
            widget.orderId,
            _resumeCommand!,
            data.currentPause!.id,
            data.rowVersion,
            resumeDate: restart,
          );
      if (mounted) {
        _resumeCommand = null;
        _resumePause = null;
        _resumeDate = null;
        _changed();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(copy.packageResumeSuccess)));
      }
    } catch (error) {
      _failure(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    ref.listen(packageManagementProvider(widget.orderId), (previous, next) {
      if (next.value case final data?) {
        _refreshAtBoundary(data);
        if (previous?.value?.hasPendingRequest == true &&
            !data.hasPendingRequest) {
          Future.microtask(() {
            if (mounted) _changed();
          });
        }
      }
    });
    return Container(
      key: ValueKey('packageManagement-${widget.orderId}'),
      child: ref
          .watch(packageManagementProvider(widget.orderId))
          .when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Column(
              children: [
                Text(copy.packageLoadFailure),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(packageManagementProvider(widget.orderId)),
                  child: Text(context.customerCopy('Retry')),
                ),
              ],
            ),
            data: (data) => _summary(data, copy),
          ),
    );
  }

  Widget _summary(PackageManagement data, AppLocalizations copy) {
    final effective = data.effectiveDisplayStatus;
    final approved =
        const {'PAUSED', 'PAUSE_SCHEDULED'}.contains(effective) &&
        data.currentPause != null;
    final paused = effective == 'PAUSED';
    final next = data.nextDelivery;
    final pending = data.hasPendingRequest;
    final requestingPause = pending && data.latestRequest!.type == 'PAUSE';
    final color = pending
        ? const Color(0xFF925719)
        : paused
        ? const Color(0xFF59655F)
        : AppColors.emeraldGreen;
    final background = pending
        ? const Color(0xFFFFF4E3)
        : paused
        ? const Color(0xFFEEF0EE)
        : const Color(0xFFEAF3EE);
    final title = requestingPause
        ? copy.packagePauseRequested
        : paused
        ? copy.packagePaused
        : approved
        ? copy.packagePauseScheduled
        : copy.packageManage;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                pending
                    ? Icons.schedule_rounded
                    : paused
                    ? Icons.pause_circle_outline
                    : approved
                    ? Icons.check_circle_outline
                    : Icons.tune_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (requestingPause) ...[
            const SizedBox(height: 6),
            Text(
              copy.packagePendingSummary,
              style: TextStyle(fontSize: 12, height: 1.4, color: color),
            ),
            _dates(
              copy.packageRequestedPauseStart,
              data.latestRequest!.start,
              copy.packageRequestedRestart,
              data.latestRequest!.resume,
            ),
          ],
          if (approved) ...[
            const SizedBox(height: 6),
            Text(
              paused ? copy.packagePausedSummary : copy.packageScheduledSummary,
              style: TextStyle(fontSize: 12, height: 1.4, color: color),
            ),
            _dates(
              copy.packagePauseStart,
              data.currentPause!.start,
              copy.packageResumeOn,
              data.currentPause!.resume,
            ),
            if (data.firstDeliveryAfterPause != null &&
                packageDate(data.firstDeliveryAfterPause!) !=
                    packageDate(data.currentPause!.resume))
              _line(
                copy.packageActualRestartDate,
                _dateLabel(context, data.firstDeliveryAfterPause),
              ),
            _facts(
              copy.packageRemainingDays,
              copy.packagePauseDayCount(data.remainingDays),
              copy.packageRevisedEnd,
              _dateLabel(context, data.endDate),
            ),
          ],
          if (pending && !requestingPause) ...[
            const SizedBox(height: 8),
            Text(
              copy.packageResumePending,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            _line(
              copy.packageRequestedRestart,
              _dateLabel(context, data.latestRequest!.resume),
            ),
            Text(
              copy.packageApprovalExplanation,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
          if (!pending && data.latestRequest?.status == 'REJECTED') ...[
            const SizedBox(height: 8),
            Text(
              data.latestRequest!.type == 'PAUSE'
                  ? copy.packagePauseRejected
                  : copy.packageResumeRejected,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            if (data.latestRequest!.reviewReason?.isNotEmpty == true)
              Text(
                data.latestRequest!.reviewReason!,
                style: const TextStyle(fontSize: 12),
              ),
          ],
          if (!approved && !requestingPause)
            _facts(
              copy.packageRemainingDays,
              copy.packagePauseDayCount(data.remainingDays),
              copy.packageNextDelivery,
              _dateLabel(context, data.nextDelivery),
            )
          else if (requestingPause)
            _line(
              copy.packageNextDelivery,
              _dateLabel(context, data.nextDelivery),
            ),
          if (approved && next != null) ...[
            if (next.isBefore(data.currentPause!.resume)) ...[
              _line(
                packageDate(next) == packageDate(data.qatarNow())
                    ? copy.packageDeliveryToday
                    : next.isBefore(data.currentPause!.start)
                    ? copy.packageDeliveryBeforePause
                    : copy.packageCommittedDelivery,
                _dateLabel(context, next),
              ),
              const SizedBox(height: 6),
              Text(
                copy.packagePauseScheduleNote,
                style: const TextStyle(fontSize: 11, height: 1.4),
              ),
            ] else if (data.firstDeliveryAfterPause == null &&
                packageDate(next) != packageDate(data.currentPause!.resume))
              _line(copy.packageActualRestartDate, _dateLabel(context, next)),
          ],
          if (!pending && !approved) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: ValueKey('pausePackage-${widget.orderId}'),
              onPressed: !_busy && data.eligibleDates.any(data.allowsPauseDate)
                  ? _pause
                  : null,
              icon: const Icon(Icons.pause_circle_outline, size: 18),
              label: Text(copy.packagePause),
            ),
            if (data.eligibleDates.isEmpty)
              Text(
                copy.packageUnavailable,
                style: const TextStyle(fontSize: 12),
              ),
          ] else if (!pending && approved && data.canResumeEarly) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : () => _resume(data),
              child: Text(copy.packageResumeEarly),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dates(
    String left,
    DateTime? start,
    String right,
    DateTime? end,
  ) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _fact(left, _dateLabel(context, start), date: true)),
          const SizedBox(width: 8),
          Expanded(child: _fact(right, _dateLabel(context, end), date: true)),
        ],
      ),
    ),
  );

  Widget _facts(String left, String first, String right, String second) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _fact(left, first)),
            const SizedBox(width: 8),
            Expanded(child: _fact(right, second)),
          ],
        ),
      );

  Widget _fact(String label, String value, {bool date = false}) => Container(
    padding: date ? const EdgeInsets.all(10) : EdgeInsets.zero,
    decoration: date
        ? BoxDecoration(
            color: Colors.white.withValues(alpha: .8),
            borderRadius: BorderRadius.circular(10),
          )
        : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF65756D),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGreen,
            height: 1.4,
          ),
        ),
      ],
    ),
  );

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Text(
      '$label: $value',
      style: const TextStyle(fontSize: 12, height: 1.4),
    ),
  );
}

class _PauseDialog extends StatefulWidget {
  const _PauseDialog({
    required this.orderId,
    required this.start,
    required this.initialResume,
    required this.remainingDays,
    required this.repository,
    required this.qatarNow,
  });
  final String orderId;
  final DateTime start;
  final DateTime initialResume;
  final int remainingDays;
  final OrdersRepository repository;
  final DateTime Function() qatarNow;
  @override
  State<_PauseDialog> createState() => _PauseDialogState();
}

class _PauseDialogState extends State<_PauseDialog> {
  late DateTime _start = widget.start;
  late int _remainingDays = widget.remainingDays;
  late DateTime _resume = widget.initialResume;
  final _reason = TextEditingController();
  PackagePausePreview? _preview;
  String? _error, _commandId;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _previewPause();
    });
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _previewPause() async {
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
    });
    try {
      final current = await widget.repository.getPackageManagement(
        widget.orderId,
      );
      final start = current.earliestPauseDate();
      if (start == null) {
        throw ApiException(
          ApiFailure.conflict,
          code: current.currentPause != null
              ? 'pause_already_scheduled'
              : 'no_eligible_service_days',
        );
      }
      if (!mounted) return;
      setState(() {
        _start = start;
        _remainingDays = current.remainingDays;
      });
      if (!_resume.isAfter(start)) {
        throw const ApiException(
          ApiFailure.validation,
          code: 'invalid_resume_date',
        );
      }
      final result = await widget.repository.previewPause(
        widget.orderId,
        start,
        _resume,
      );
      if (mounted && result.pauseStartDate != null) {
        setState(() => _start = result.pauseStartDate!);
      }
      if (!_resume.isAfter(result.pauseStartDate ?? start)) {
        throw const ApiException(
          ApiFailure.validation,
          code: 'invalid_resume_date',
        );
      }
      if (mounted) {
        setState(() {
          _preview = result;
          _commandId = packageCommandId();
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = _packageError(context, error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_busy || _preview == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.repository.pausePackage(
        widget.orderId,
        _commandId!,
        _preview!,
        _preview!.pauseStartDate ?? _start,
        _resume,
        _reason.text.trim(),
      );
      if (mounted) Navigator.pop(context, result);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = _packageError(context, error);
          if (error.statusCode == 409) {
            _preview = null;
            _commandId = null;
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = _packageError(context, error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseResumeDate() async {
    if (_busy) return;
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    final date = await showDatePicker(
      context: context,
      initialDate: _resume.isAfter(_start)
          ? _resume
          : _start.add(const Duration(days: 1)),
      currentDate: widget.qatarNow(),
      firstDate: _start.add(const Duration(days: 1)),
      lastDate: packageRestartLimit(widget.qatarNow()),
      helpText: copy.packageResumeDate,
    );
    if (!mounted || date == null || date == _resume) return;
    setState(() {
      _resume = date;
      _preview = null;
      _commandId = null;
    });
    await _previewPause();
  }

  @override
  Widget build(BuildContext context) {
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    final preview = _preview;
    final muted = AppColors.darkGreen.withValues(alpha: .62);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        key: const ValueKey('pausePackageDialog'),
        backgroundColor: const Color(0xFFFCFDFC),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        titlePadding: const EdgeInsets.fromLTRB(16, 18, 10, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1ED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.emeraldGreen,
                    size: 28,
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F1ED),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.pause_circle_filled,
                        color: AppColors.emeraldGreen,
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.packagePause,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    copy.packagePauseSubtitle,
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              key: const ValueKey('closePausePackage'),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: _busy ? null : () => Navigator.pop(context),
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFE8F1ED),
              ),
              icon: const Icon(
                Icons.close,
                size: 17,
                color: AppColors.darkGreen,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE1E8E3)),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _dateCard(
                          copy.packagePauseStart,
                          _preview?.pauseStartDate ?? _start,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: AppColors.emeraldGreen,
                        ),
                      ),
                      Expanded(
                        child: Material(
                          color: const Color(0xFFE6F3DF),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            key: const ValueKey('pauseRestartDate'),
                            onTap: _busy ? null : _chooseResumeDate,
                            borderRadius: BorderRadius.circular(10),
                            child: _dateCard(copy.packageResumeDate, _resume),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF5F1),
                    border: Border.all(color: const Color(0xFFCEE2D8)),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 19,
                        color: AppColors.emeraldGreen,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          copy.packagePreserveDays,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  copy.packagePauseDetails,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  key: const ValueKey('pauseDetailsSummary'),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE1E8E3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _detailRow(
                        Icons.calendar_today_outlined,
                        copy.packageActualRestartDate,
                        _dateLabel(context, preview?.actualRestartDate),
                      ),
                      _detailRow(
                        Icons.pause_circle_outline,
                        copy.packageAffectedDays,
                        preview == null
                            ? '—'
                            : copy.packagePauseDayCount(preview.affectedDays),
                        valueKey: 'pauseAffectedDays',
                      ),
                      _detailRow(
                        Icons.sync,
                        copy.packageRemainingAfterResume,
                        copy.packagePauseDayCount(
                          preview?.remainingDays ?? _remainingDays,
                        ),
                        valueKey: 'pauseRemainingDays',
                      ),
                      if (preview != null &&
                          preview.rescheduledDays !=
                              (preview.remainingDays ?? _remainingDays))
                        _detailRow(
                          Icons.event_repeat_outlined,
                          copy.packageRescheduledDays,
                          copy.packagePauseDayCount(preview.rescheduledDays),
                        ),
                      if (preview != null && preview.committedDays > 0)
                        _detailRow(
                          Icons.event_available_outlined,
                          copy.packageCommittedDays,
                          copy.packagePauseDayCount(preview.committedDays),
                        ),
                      _detailRow(
                        Icons.calendar_month_outlined,
                        copy.packageExpectedEnd,
                        _dateLabel(context, preview?.endDate),
                        highlight: true,
                        valueKey: 'pauseExpectedEnd',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  copy.packageReason,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 7),
                TextField(
                  key: const ValueKey('pausePackageReason'),
                  controller: _reason,
                  enabled: !_busy,
                  minLines: 3,
                  maxLines: 4,
                  maxLength: 500,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGreen,
                  ),
                  decoration: InputDecoration(
                    hintText: copy.packagePauseReasonHint,
                    hintStyle: TextStyle(fontSize: 11, color: muted),
                    contentPadding: const EdgeInsets.all(12),
                    filled: true,
                    fillColor: Colors.white,
                    counterStyle: TextStyle(fontSize: 10, color: muted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: Color(0xFFE1E8E3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: Color(0xFFE1E8E3)),
                    ),
                  ),
                  onChanged: (_) {
                    if (_commandId != null) _commandId = packageCommandId();
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.jasper,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 43),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: AppColors.emeraldGreen,
                    side: const BorderSide(color: AppColors.emeraldGreen),
                    shape: const StadiumBorder(),
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(context.customerCopy('Cancel')),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                flex: 3,
                child: FilledButton(
                  key: const ValueKey('submitPausePackage'),
                  onPressed: _busy
                      ? null
                      : preview == null
                      ? _previewPause
                      : _confirm,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 43),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor: AppColors.emeraldGreen,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(
                    preview == null
                        ? copy.packagePreviewPause
                        : copy.packageConfirmPause,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateCard(String label, DateTime date) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
    child: Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 19,
          color: AppColors.emeraldGreen,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _dateLabel(context, date),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
    String? valueKey,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    decoration: BoxDecoration(
      color: highlight ? const Color(0xFFE6F3DF) : null,
      borderRadius: highlight ? BorderRadius.circular(6) : null,
      border: highlight
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFEEF1EE))),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.emeraldGreen),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              height: 1.25,
              color: AppColors.darkGreen,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            value,
            key: valueKey == null ? null : ValueKey(valueKey),
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 11,
              height: 1.25,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.emeraldGreen : AppColors.darkGreen,
            ),
          ),
        ),
      ],
    ),
  );
}
