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

  void _failure() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lookupAppLocalizations(
            Localizations.localeOf(context),
          ).packageScheduleChanged,
        ),
      ),
    );
    ref.invalidate(packageManagementProvider(widget.orderId));
  }

  Future<void> _pause() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final data = await repository.getPackageManagement(widget.orderId);
      if (!mounted) return;
      final dates = data.eligibleDates.where(data.allowsPauseDate).toList();
      if (dates.isEmpty) {
        _failure();
        return;
      }
      final first = data.earliestRestartDate();
      final last = data.latestRestartDate();
      if (first.isAfter(last)) {
        _failure();
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
      await showDialog<PackageManagement>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PauseDialog(
          orderId: widget.orderId,
          start: first,
          initialResume: restart,
          repository: repository,
          qatarNow: data.qatarNow,
        ),
      );
      // A committed command can lose its network response. Refresh after dismissing an error too.
      if (mounted) _changed();
    } catch (_) {
      _failure();
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
      }
    } catch (_) {
      _failure();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    ref.listen(packageManagementProvider(widget.orderId), (_, next) {
      if (next.value case final data?) {
        _refreshAtBoundary(data);
      }
    });
    return Card(
      key: ValueKey('packageManagement-${widget.orderId}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: ref
            .watch(packageManagementProvider(widget.orderId))
            .when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy.packageLoadFailure),
                  TextButton(
                    onPressed: () => ref.invalidate(
                      packageManagementProvider(widget.orderId),
                    ),
                    child: Text(context.customerCopy('Retry')),
                  ),
                ],
              ),
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    [
                      copy.packageManage,
                      widget.planName,
                    ].whereType<String>().join(' · '),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  if (data.currentPause != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      data.status == 'PAUSED'
                          ? copy.packagePaused
                          : copy.packagePauseScheduled,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.emeraldGreen,
                      ),
                    ),
                    _line(
                      copy.packagePauseStart,
                      _dateLabel(context, data.currentPause!.start),
                    ),
                    _line(
                      copy.packageResumeDate,
                      _dateLabel(context, data.currentPause!.resume),
                    ),
                  ],
                  _line(copy.packageRemainingDays, '${data.remainingDays}'),
                  _line(
                    copy.packageNextDelivery,
                    _dateLabel(context, data.nextDelivery),
                  ),
                  _line(
                    copy.packageExpectedEnd,
                    _dateLabel(context, data.endDate),
                  ),
                  if (data.eligibleDates.isNotEmpty)
                    _line(
                      copy.packageEarliestPauseDate,
                      _dateLabel(context, data.eligibleDates.first),
                    ),
                  if (data.currentPause == null) ...[
                    FilledButton.icon(
                      key: ValueKey('pausePackage-${widget.orderId}'),
                      onPressed:
                          !_busy && data.eligibleDates.any(data.allowsPauseDate)
                          ? _pause
                          : null,
                      icon: const Icon(Icons.pause_circle_outline),
                      label: Text(copy.packagePause),
                    ),
                    if (data.eligibleDates.isEmpty)
                      Text(
                        copy.packageUnavailable,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ] else if (data.canResumeEarly)
                    OutlinedButton(
                      onPressed: _busy ? null : () => _resume(data),
                      child: Text(copy.packageResumeEarly),
                    ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
  );
}

class _PauseDialog extends StatefulWidget {
  const _PauseDialog({
    required this.orderId,
    required this.start,
    required this.initialResume,
    required this.repository,
    required this.qatarNow,
  });
  final String orderId;
  final DateTime start;
  final DateTime initialResume;
  final OrdersRepository repository;
  final DateTime Function() qatarNow;
  @override
  State<_PauseDialog> createState() => _PauseDialogState();
}

class _PauseDialogState extends State<_PauseDialog> {
  late DateTime _resume = widget.initialResume;
  final _reason = TextEditingController();
  PackagePausePreview? _preview;
  String? _error, _commandId;
  bool _busy = false;
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
      final result = await widget.repository.previewPause(
        widget.orderId,
        widget.start,
        _resume,
      );
      if (mounted) {
        setState(() {
          _preview = result;
          _commandId = packageCommandId();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = lookupAppLocalizations(
            Localizations.localeOf(context),
          ).packageScheduleChanged,
        );
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
        widget.start,
        _resume,
        _reason.text.trim(),
      );
      if (mounted) Navigator.pop(context, result);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = lookupAppLocalizations(
            Localizations.localeOf(context),
          ).packageScheduleChanged;
          if (error.statusCode == 409) {
            _preview = null;
            _commandId = null;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = lookupAppLocalizations(
            Localizations.localeOf(context),
          ).packageScheduleChanged,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(copy.packagePause),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _resume,
                          currentDate: widget.qatarNow(),
                          firstDate: widget.start,
                          lastDate: packageRestartLimit(widget.qatarNow()),
                          helpText: copy.packageResumeDate,
                        );
                        if (mounted && date != null) {
                          setState(() {
                            _resume = date;
                            _preview = null;
                            _commandId = null;
                          });
                        }
                      },
                child: Text(
                  '${copy.packageResumeDate}: ${_dateLabel(context, _resume)}',
                ),
              ),
              Text(copy.packagePreserveDays),
              const SizedBox(height: 12),
              TextField(
                controller: _reason,
                enabled: !_busy,
                maxLength: 500,
                decoration: InputDecoration(labelText: copy.packageReason),
                onChanged: (_) {
                  if (_commandId != null) _commandId = packageCommandId();
                },
              ),
              if (_preview case final preview?) ...[
                Text('${copy.packageAffectedDays}: ${preview.affectedDays}'),
                Text(
                  '${copy.packageRescheduledDays}: ${preview.rescheduledDays}',
                ),
                if (preview.committedDays > 0)
                  Text(
                    '${copy.packageCommittedDays}: ${preview.committedDays}',
                  ),
                Text(
                  '${copy.packageExpectedEnd}: ${_dateLabel(context, preview.endDate)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(context.customerCopy('Cancel')),
          ),
          if (_preview == null)
            FilledButton(
              onPressed: _busy ? null : _previewPause,
              child: Text(copy.packagePreviewPause),
            )
          else
            FilledButton(
              onPressed: _busy ? null : _confirm,
              child: Text(copy.packageConfirmPause),
            ),
        ],
      ),
    );
  }
}
