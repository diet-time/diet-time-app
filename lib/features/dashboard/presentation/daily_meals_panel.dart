import 'package:diet_time/features/plans/domain/meal_entitlement.dart';
import 'dart:async';

import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/dashboard/data/upcoming_meals_repository.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DailyMealsPanel extends ConsumerStatefulWidget {
  const DailyMealsPanel({
    required this.request,
    required this.date,
    required this.planName,
    super.key,
  });
  final DailyMenuRequest request;
  final DateTime date;
  final String planName;

  @override
  ConsumerState<DailyMealsPanel> createState() => _DailyMealsPanelState();
}

class _DailyMealsPanelState extends ConsumerState<DailyMealsPanel> {
  Timer? _deadlineTimer;
  DateTime? _scheduledCutoff;

  @override
  void dispose() {
    _deadlineTimer?.cancel();
    super.dispose();
  }

  void _watchDeadline(DailyMealMenu menu) {
    if (_scheduledCutoff == menu.cutoffAt) return;
    _deadlineTimer?.cancel();
    _scheduledCutoff = menu.cutoffAt;
    if (menu.cutoffAt == null || menu.deadlinePassed) return;
    _deadlineTimer = Timer(
      menu.cutoffAt!.toUtc().difference(DateTime.now().toUtc()),
      () {
        if (!mounted) return;
        setState(() {});
        ref.invalidate(dailyMealMenuProvider(widget.request));
        ref.invalidate(upcomingMealDaysProvider(widget.request.orderId));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(dailyMealMenuProvider(widget.request));
    return result.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => const MealMenuLoading(),
      error: (error, _) => MealMenuMessage(
        message:
            error is ApiException && error.failure == ApiFailure.unauthorized
            ? 'Please sign in again to view your meals.'
            : 'We couldn’t load your meals for this day. Please try again.',
        onRetry: () => ref.invalidate(dailyMealMenuProvider(widget.request)),
      ),
      data: (menu) {
        // Treat cross-date responses as invalid rather than displaying another menu.
        if (DateUtils.dateOnly(menu.date) != DateUtils.dateOnly(widget.date)) {
          return MealMenuMessage(
            message: 'The menu for this date could not be confirmed.',
            onRetry: () =>
                ref.invalidate(dailyMealMenuProvider(widget.request)),
          );
        }
        _watchDeadline(menu);
        final cutoff = menu.cutoffAt?.toUtc().add(const Duration(hours: 3));
        return Column(
          key: ValueKey('dailyMenu-${menu.dayId}'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.planName} · ${MealEntitlement(menu.mealCount, menu.snackCount).label(Localizations.localeOf(context).languageCode)}',
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F2E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealDayStatusLabel(menu.status),
                    style: const TextStyle(
                      color: AppColors.emeraldGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    menu.editable
                        ? 'We’ve selected your meals for this day. You can change them before the selection deadline.'
                        : menu.deadlinePassed && menu.canEdit
                        ? 'The selection deadline has passed. Your meals are locked for kitchen preparation.'
                        : menu.lockReason ??
                              'Your meals are read-only for this day.',
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  if (cutoff != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Selection deadline: ${DateFormat('d MMM, h:mm a').format(cutoff)} Qatar time',
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your meals for this day',
              style: TextStyle(
                color: AppColors.darkGreen,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (menu.selected.isEmpty)
              const MealMenuMessage(
                message:
                    'Your meals are being reviewed by our team. Please check back shortly.',
              ),
            for (final selection in menu.selected) ...[
              DailyMealCard(
                key: ValueKey('assigned-${selection.id}'),
                meal: selection.meal,
                status: selection.source == 'automatic'
                    ? 'Selected for you'
                    : 'Your choice',
                onChange: menu.editable
                    ? () => _changeMeal(menu, selection)
                    : null,
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Future<void> _changeMeal(
    DailyMealMenu menu,
    AssignedDailyMeal selection,
  ) async {
    final chosenIds = menu.selected
        .where((s) => s.id != selection.id)
        .map((s) => s.meal.id)
        .toSet();
    final options = menu.alternatives
        .where(
          (m) =>
              m.category == selection.meal.category &&
              m.id != selection.meal.id &&
              !chosenIds.contains(m.id),
        )
        .toList();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFBFAF7),
      builder: (_) => _ReplacementSheet(
        request: widget.request,
        menu: menu,
        selection: selection,
        options: options,
      ),
    );
    if (!mounted || saved != true) return;
    ref.invalidate(dailyMealMenuProvider(widget.request));
    ref.invalidate(upcomingMealDaysProvider(widget.request.orderId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your meal change has been saved.')),
    );
  }
}

class _ReplacementSheet extends ConsumerStatefulWidget {
  const _ReplacementSheet({
    required this.request,
    required this.menu,
    required this.selection,
    required this.options,
  });
  final DailyMenuRequest request;
  final DailyMealMenu menu;
  final AssignedDailyMeal selection;
  final List<DailyMealItem> options;

  @override
  ConsumerState<_ReplacementSheet> createState() => _ReplacementSheetState();
}

class _ReplacementSheetState extends ConsumerState<_ReplacementSheet> {
  DailyMealItem? _chosen;
  bool _saving = false;
  String? _error;
  bool _refreshRequired = false;
  Timer? _cutoffTimer;

  @override
  void initState() {
    super.initState();
    final cutoff = widget.menu.cutoffAt;
    if (cutoff != null && cutoff.toUtc().isAfter(DateTime.now().toUtc())) {
      _cutoffTimer = Timer(cutoff.toUtc().difference(DateTime.now().toUtc()), () {
        if (!mounted) return;
        setState(() {
          _refreshRequired = true;
          _error =
              'The selection deadline has passed. Close this sheet to view your saved meals.';
        });
      });
    }
  }

  @override
  void dispose() {
    _cutoffTimer?.cancel();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _chosen == null || !widget.menu.editable) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(upcomingMealsRepositoryProvider)
          .replace(
            widget.request,
            widget.selection,
            _chosen!,
            widget.menu.revision,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _refreshRequired =
            error is ApiException &&
            (error.statusCode == 409 || error.statusCode == 422);
        _error = error is ApiException && error.statusCode == 409
            ? 'Your choices or selection deadline have changed. Close this sheet and refresh the day.'
            : error is ApiException && error.statusCode == 422
            ? 'That meal is no longer available. Please choose another option or refresh the day.'
            : 'We couldn’t save this change. Your saved meals are unchanged. Please try again.';
      });
      if (_refreshRequired) {
        ref.invalidate(dailyMealMenuProvider(widget.request));
        ref.invalidate(upcomingMealDaysProvider(widget.request.orderId));
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .85,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Change meal',
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.options.isEmpty
                  ? const Center(
                      child: Text(
                        'There are no other eligible dishes for this selection on this day.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: widget.options.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = widget.options[index];
                        return Semantics(
                          selected: item.optionId == _chosen?.optionId,
                          child: DailyMealCard(
                            key: ValueKey('alternative-${item.optionId}'),
                            meal: item,
                            status: item.optionId == _chosen?.optionId
                                ? 'Selected replacement'
                                : 'Available for this day',
                            selected: item.optionId == _chosen?.optionId,
                            onSelect: _saving || _refreshRequired
                                ? null
                                : () => setState(() => _chosen = item),
                          ),
                        );
                      },
                    ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _error!,
                  key: const ValueKey('mealSaveError'),
                  style: const TextStyle(color: AppColors.jasper),
                ),
              ),
            const SizedBox(height: 10),
            SafeArea(
              top: false,
              child: FilledButton(
                key: const ValueKey('saveMealChanges'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emeraldGreen,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed:
                    _chosen == null ||
                        _saving ||
                        _refreshRequired ||
                        !widget.menu.editable
                    ? null
                    : _save,
                child: Text(_saving ? 'Saving changes…' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DailyMealCard extends StatelessWidget {
  const DailyMealCard({
    required this.meal,
    required this.status,
    this.onChange,
    this.onSelect,
    this.selected = false,
    super.key,
  });
  final DailyMealItem meal;
  final String status;
  final VoidCallback? onChange;
  final VoidCallback? onSelect;
  final bool selected;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFE7F2E9) : AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: selected
            ? AppColors.emeraldGreen
            : AppColors.darkGreen.withValues(alpha: .09),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: meal.imageUrl?.isNotEmpty == true
                        ? Image.network(
                            Uri.parse(
                              AppEnvironment.apiBaseUrl,
                            ).resolve(meal.imageUrl!).toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _MealPlaceholder(),
                          )
                        : const _MealPlaceholder(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.category == 'snack' ? 'Snack' : 'Meal',
                        style: const TextStyle(
                          color: AppColors.emeraldGreen,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meal.name,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (meal.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          meal.description!,
                          style: TextStyle(
                            color: AppColors.darkGreen.withValues(alpha: .7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (meal.calories != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          '${meal.calories!.round()} kcal',
                          style: const TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: const TextStyle(
                color: AppColors.emeraldGreen,
                fontSize: 12,
              ),
            ),
            if (onChange != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: onChange,
                  child: const Text('Change Meal'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _MealPlaceholder extends StatelessWidget {
  const _MealPlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE7F2E9),
    child: Icon(Icons.restaurant_outlined, color: AppColors.emeraldGreen),
  );
}

class MealMenuLoading extends StatelessWidget {
  const MealMenuLoading({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading meals for the selected day',
    child: Column(
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.darkGreen.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
      ],
    ),
  );
}

class MealMenuMessage extends StatelessWidget {
  const MealMenuMessage({required this.message, this.onRetry, super.key});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.darkGreen, height: 1.5),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

String mealDayStatusLabel(String status) => switch (status) {
  'auto_selected' => 'Automatically Selected',
  'customized' => 'Customized',
  'locked' => 'Locked',
  'delivered' => 'Delivered',
  'needs_review' => 'Our team is reviewing this day',
  _ => 'Selection pending',
};
