import 'dart:async';

import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/dashboard/data/tomorrow_menu_repository.dart';
import 'package:diet_time/features/dashboard/data/upcoming_meals_repository.dart';
import 'package:diet_time/features/dashboard/domain/tomorrow_menu.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TomorrowMenuSection extends ConsumerStatefulWidget {
  const TomorrowMenuSection({
    super.key,
    required this.orderId,
    this.orderReference,
    this.onMenuLoaded,
  });
  final String orderId;
  final String? orderReference;
  final ValueChanged<TomorrowMenu?>? onMenuLoaded;

  @override
  ConsumerState<TomorrowMenuSection> createState() =>
      _TomorrowMenuSectionState();
}

class _TomorrowMenuSectionState extends ConsumerState<TomorrowMenuSection>
    with WidgetsBindingObserver {
  TomorrowMenu? _menu;
  TomorrowMealDraft? _draft;
  String? _error;
  bool _loading = true;
  bool _submitting = false;
  bool _confirming = false;
  bool _expired = false;
  Timer? _refreshTimer;
  int _generation = 0;
  String? _language;
  bool _showConfirmed = false;
  StateSetter? _selectionRebuild;
  bool _selectionOpening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_language != language) {
      _language = language;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant TomorrowMenuSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_submitting) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({String? feedback}) async {
    final generation = ++_generation;
    _refreshTimer?.cancel();
    _update(() {
      _loading = true;
      _error = feedback;
    });
    try {
      final menu = await ref
          .read(tomorrowMenuRepositoryProvider)
          .get(widget.orderId, _language ?? 'en');
      if (!mounted || generation != _generation) return;
      _accept(menu);
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      _update(() {
        _menu = null;
        _loading = false;
        _error =
            feedback ??
            switch (error) {
              ApiException(failure: ApiFailure.unauthorized) =>
                'Your session has expired. Please sign in again.',
              ApiException(failure: ApiFailure.notFound) =>
                'This order could not be loaded for your account. Refresh your dashboard or contact our team with your order reference.',
              ApiException(failure: ApiFailure.network || ApiFailure.timeout) =>
                'We could not connect to load your menu. Check your connection and try again.',
              _ =>
                'The menu service could not load your order’s dishes. Please refresh or contact our team.',
            };
      });
      widget.onMenuLoaded?.call(null);
    }
  }

  void _accept(TomorrowMenu menu) {
    if (_menu?.dayId != menu.dayId ||
        _menu?.subscriptionId != menu.subscriptionId) {
      _showConfirmed = false;
    }
    if (menu.finalized && menu.dayId != null) {
      ref.invalidate(upcomingMealDaysProvider(widget.orderId));
      ref.invalidate(
        dailyMealMenuProvider((
          orderId: widget.orderId,
          dayId: menu.dayId!,
          language: _language ?? 'en',
        )),
      );
    }
    _update(() {
      _menu = menu;
      _draft = TomorrowMealDraft(menu);
      _loading = false;
      _expired = !menu.canConfirm;
    });
    widget.onMenuLoaded?.call(menu);
    _refreshTimer?.cancel();
    // Relative server timestamps schedule a refresh without trusting device time.
    final untilCutoff = menu.cutoffAt.difference(menu.serverNow);
    final untilMidnight = Duration(
      milliseconds: menu.serverNow
          .add(const Duration(hours: 3))
          .copyWith(
            hour: 0,
            minute: 0,
            second: 0,
            millisecond: 0,
            microsecond: 0,
          )
          .add(const Duration(days: 1))
          .difference(menu.serverNow.add(const Duration(hours: 3)))
          .inMilliseconds,
    );
    final delay = menu.canConfirm && untilCutoff > Duration.zero
        ? untilCutoff
        : const {
            'FINALIZATION_PENDING',
            'NEEDS_REVIEW',
            'MENU_NOT_CONFIGURED',
            'SERVICE_DAYS_MISSING',
            'SERVICE_DAY_INCOMPLETE',
          }.contains(menu.status)
        ? const Duration(seconds: 30)
        : untilMidnight;
    _refreshTimer = Timer(delay, () {
      if (!mounted) return;
      _update(() => _expired = true);
      if (!_submitting) _load();
    });
  }

  void _update(VoidCallback action) {
    setState(action);
    _selectionRebuild?.call(() {});
  }

  Future<void> _openSelection() async {
    if (_selectionOpening) return;
    _selectionOpening = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (routeContext) => StatefulBuilder(
            builder: (routeContext, refresh) {
              _selectionRebuild = refresh;
              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    lookupAppLocalizations(
                      Localizations.localeOf(context),
                    ).deliveriesChoose,
                  ),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildPanel(routeContext, fullSelection: true),
                ),
              );
            },
          ),
        ),
      );
    } finally {
      _selectionOpening = false;
      _selectionRebuild = null;
      if (mounted) setState(() {});
    }
  }

  bool get _editable =>
      !_loading && !_expired && !_submitting && _menu?.canConfirm == true;

  Future<void> _confirm() async {
    final menu = _menu;
    final draft = _draft;
    if (!_editable ||
        _confirming ||
        menu?.dayId == null ||
        draft?.complete != true) {
      return;
    }
    _confirming = true;
    final chosen = [
      ...menu!.meals,
      ...menu.snacks,
    ].where((item) => draft!.contains(item.id)).toList(growable: false);
    final approved = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Confirm your meals',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(DateFormat('EEEE, d MMMM').format(menu.deliveryDate)),
              const SizedBox(height: 12),
              for (final item in chosen)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• ${item.name}'),
                ),
              const SizedBox(height: 16),
              const Text(
                'Your selections cannot be changed after confirmation.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
    _confirming = false;
    if (!mounted || approved != true || !_editable || !identical(menu, _menu)) {
      return;
    }
    _update(() {
      _submitting = true;
      _error = null;
    });
    try {
      final saved = await ref
          .read(tomorrowMenuRepositoryProvider)
          .confirm(
            widget.orderId,
            menu.dayId!,
            _language ?? 'en',
            draft!.mealIds,
            draft.snackIds,
          );
      if (!mounted) return;
      _accept(saved);
    } on Object catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? switch (error.code) {
              'cutoff_passed' =>
                'The 9:00 PM deadline has passed. Your automatic meals are being finalized.',
              'already_confirmed' =>
                'Your meals have already been finalized. Here are your saved dishes.',
              'subscription_inactive' =>
                'Your subscription is no longer active for this delivery.',
              'meal_unavailable' || 'invalid_selection' =>
                'A dish is no longer available. Please review the refreshed menu.',
              _ =>
                'We could not verify your confirmation. Please check your connection and refresh before trying again.',
            }
          : 'Unable to confirm your meals. Please try again.';
      await _load(feedback: message);
    } finally {
      if (mounted) _update(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => _buildDeliveryCard(context);

  Widget _buildDeliveryCard(BuildContext context) {
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    final menu = _menu;
    final draft = _draft;
    final confirmed = menu?.finalized == true;
    final actionable =
        menu?.canConfirm == true && menu?.locked == false && !_expired;
    final accent = confirmed ? AppColors.emeraldGreen : const Color(0xFF946315);
    final reference = widget.orderReference?.trim().isNotEmpty == true
        ? widget.orderReference!.trim()
        : widget.orderId;
    final shortReference = reference.length > 16
        ? '…${reference.substring(reference.length - 12)}'
        : reference;
    final total = (menu?.mealCount ?? 0) + (menu?.snackCount ?? 0);
    final selected =
        (draft?.mealIds.length ?? 0) + (draft?.snackIds.length ?? 0);
    final images = [
      ...?menu?.selected,
      ...?menu?.meals,
      ...?menu?.snacks,
    ].where((item) => item.imageUrl?.trim().isNotEmpty == true);
    return Container(
      key: ValueKey('tomorrowMenu-${widget.orderId}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: confirmed ? const Color(0xFFF0F7F0) : const Color(0xFFFFFEFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: confirmed ? const Color(0xFFD9E7DA) : const Color(0xFFE8E3D8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: copy.deliveriesOrder(reference),
                  child: Text(
                    copy.deliveriesOrder(shortReference),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.darkGreen.withValues(alpha: .7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (menu != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: confirmed
                          ? const Color(0xFFDDEDE0)
                          : const Color(0xFFFFF1D8),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      confirmed
                          ? copy.deliveriesConfirmed
                          : actionable
                          ? copy.deliveriesActionNeeded
                          : copy.deliveriesWaiting,
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Semantics(
                label: copy.deliveriesLoading,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF3E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          else if (menu != null && draft != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _DeliveryThumbnail(imageUrl: images.firstOrNull?.imageUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.planName,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        copy.deliveriesPackage(menu.mealCount, menu.snackCount),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGreen.withValues(alpha: .7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (confirmed) ...[
              Text(
                copy.deliveriesAllConfirmed(menu.selected.length),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.emeraldGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              TextButton(
                key: const ValueKey('toggleConfirmedMeals'),
                onPressed: () =>
                    _update(() => _showConfirmed = !_showConfirmed),
                style:
                    TextButton.styleFrom(
                      alignment: AlignmentDirectional.centerStart,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 44),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      side: BorderSide.none,
                    ).copyWith(
                      backgroundBuilder: (_, _, child) =>
                          child ?? const SizedBox(),
                    ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _showConfirmed
                            ? copy.deliveriesHideDishes
                            : copy.deliveriesViewDishes,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _showConfirmed ? .5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                alignment: Alignment.topCenter,
                child: _showConfirmed
                    ? Column(
                        children: [
                          for (final item in menu.selected)
                            _CompactMealRow(item: item),
                        ],
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ] else if (menu.dayId != null) ...[
              if (actionable) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    key: ValueKey('deliveryProgress-${widget.orderId}'),
                    value: total == 0 ? 0 : (selected / total).clamp(0.0, 1.0),
                    minHeight: 4,
                    color: AppColors.emeraldGreen,
                    backgroundColor: const Color(0xFFEAECE1),
                    semanticsLabel: copy.deliveriesProgress(selected, total),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      copy.deliveriesProgress(selected, total),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    Text(
                      copy.deliveriesDeadline,
                      style: TextStyle(fontSize: 11, color: accent),
                    ),
                  ],
                ),
              ] else
                Text(
                  menu.emptyReason ??
                      menu.reviewReason ??
                      copy.deliveriesStatus(menu.status),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGreen,
                  ),
                ),
              if (!menu.locked &&
                  (menu.meals.isNotEmpty || menu.snacks.isNotEmpty)) ...[
                const SizedBox(height: 8),
                FilledButton(
                  key: const ValueKey('chooseTomorrowMeals'),
                  onPressed: _submitting ? null : _openSelection,
                  style:
                      FilledButton.styleFrom(
                        backgroundColor: AppColors.emeraldGreen,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size.fromHeight(44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        elevation: 0,
                        surfaceTintColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ).copyWith(
                        backgroundBuilder: (_, _, child) =>
                            child ?? const SizedBox(),
                      ),
                  child: Text(copy.deliveriesChoose),
                ),
              ],
            ] else ...[
              Text(
                menu.emptyReason ??
                    menu.reviewReason ??
                    copy.deliveriesStatus(menu.status),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGreen,
                ),
              ),
              if (menu.status == 'NOT_STARTED' &&
                  (menu.firstDeliveryDate ?? menu.orderStartDate) != null)
                Text(
                  copy.deliveriesFirstDelivery(
                    DateFormat(
                      'EEEE, d MMMM',
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'ar'
                          : null,
                    ).format((menu.firstDeliveryDate ?? menu.orderStartDate)!),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
            ],
            if (!menu.canConfirm && !confirmed && _error == null)
              TextButton(
                onPressed: _submitting ? null : () => _load(),
                child: Text(copy.deliveriesRefresh),
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            TextButton(
              onPressed: _loading || _submitting ? null : () => _load(),
              child: Text(copy.deliveriesRefresh),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPanel(BuildContext context, {bool fullSelection = false}) {
    final menu = _menu;
    final draft = _draft;
    return Container(
      key: ValueKey('tomorrowMenu-${widget.orderId}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tomorrow’s Menu',
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (_loading) ...[
            for (final width in [180.0, 120.0, double.infinity])
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: width,
                height: width == double.infinity ? 100 : 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF5EF),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
          ] else if (menu != null && draft != null) ...[
            Text(
              DateFormat('EEEE, d MMMM').format(menu.deliveryDate),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(menu.planName),
            if (widget.orderReference != null)
              Text('Order: ${widget.orderReference}'),
            if (fullSelection && menu.orderStatus != null)
              Text('Order status: ${menu.orderStatus!.replaceAll('_', ' ')}'),
            Text(
              '${menu.mealCount} Meals + ${menu.snackCount} Snack${menu.snackCount == 1 ? '' : 's'}',
            ),
            const SizedBox(height: 12),
            if (menu.status == 'NOT_STARTED' &&
                (menu.firstDeliveryDate ?? menu.orderStartDate) != null)
              Text(
                'First delivery: ${DateFormat('EEEE, d MMMM').format((menu.firstDeliveryDate ?? menu.orderStartDate)!)}',
              ),
            if (menu.finalized) ...[
              Row(
                children: [
                  Chip(
                    avatar: const Icon(
                      Icons.check_circle,
                      color: AppColors.darkGreen,
                      size: 18,
                    ),
                    backgroundColor: const Color(0xFFDDF3E6),
                    label: Text(
                      menu.status == 'CUSTOMER_CONFIRMED'
                          ? 'Confirmed'
                          : 'Automatically finalized',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${menu.selected.length} dishes'),
                ],
              ),
              if (!fullSelection)
                TextButton(
                  key: const ValueKey('toggleConfirmedMeals'),
                  onPressed: () =>
                      _update(() => _showConfirmed = !_showConfirmed),
                  child: Text(
                    _showConfirmed
                        ? 'Hide confirmed meals'
                        : 'View confirmed meals',
                  ),
                ),
              if (fullSelection || _showConfirmed)
                for (final item in menu.selected) _CompactMealRow(item: item),
            ] else ...[
              if (menu.canConfirm) const Text('Selection pending'),
              if (menu.dayId != null) ...[
                Text(
                  'Meals: ${draft.mealIds.length}/${menu.mealCount} selected',
                ),
                Text(
                  'Snacks: ${draft.snackIds.length}/${menu.snackCount} selected',
                ),
              ],
              if (menu.canConfirm && !_expired)
                const Text('Selection closes today at 9:00 PM Qatar time.')
              else
                Text(
                  menu.emptyReason ?? menu.reviewReason ?? menu.statusMessage,
                ),
              const SizedBox(height: 12),
              if (!fullSelection && menu.dayId != null)
                FilledButton(
                  key: const ValueKey('chooseTomorrowMeals'),
                  onPressed:
                      !menu.locked &&
                          (menu.meals.isNotEmpty || menu.snacks.isNotEmpty)
                      ? _openSelection
                      : null,
                  child: const Text('Choose your meals'),
                ),
              if (fullSelection) ...[
                if (!menu.locked &&
                    (menu.meals.isNotEmpty || menu.snacks.isNotEmpty)) ...[
                  _group('Meals', menu.meals, draft),
                  _group('Snacks', menu.snacks, draft),
                  FilledButton(
                    key: const ValueKey('confirmTomorrowMeals'),
                    onPressed: _editable && draft.complete ? _confirm : null,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirm My Meals'),
                  ),
                ] else
                  for (final item in menu.selected) _CompactMealRow(item: item),
              ],
            ],
            if (!menu.canConfirm && !menu.finalized && _error == null)
              TextButton(
                onPressed: _submitting ? null : () => _load(),
                child: const Text('Refresh menu'),
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: _loading || _submitting ? null : () => _load(),
              child: const Text('Refresh menu'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDraft(DailyMealItem item, TomorrowMealDraft draft) async {
    if (!_editable) return;
    if (draft.toggle(item)) {
      _update(() {});
      return;
    }
    final ids = item.category == 'meal' ? draft.mealIds : draft.snackIds;
    final options = item.category == 'meal'
        ? draft.menu.meals
        : draft.menu.snacks;
    final limit = item.category == 'meal'
        ? draft.menu.mealCount
        : draft.menu.snackCount;
    if (draft.contains(item.id) || limit == 0 || ids.length != limit) return;
    final previous = item.category == 'snack' && ids.length == 1
        ? ids.single
        : await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            builder: (context) => SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.category == 'meal'
                          ? 'Replace a meal'
                          : 'Replace a snack',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    for (final selected in options.where(
                      (option) => ids.contains(option.id),
                    ))
                      _MealCard(
                        item: selected,
                        selected: true,
                        onTap: () => Navigator.pop(context, selected.id),
                      ),
                  ],
                ),
              ),
            ),
          );
    if (!mounted ||
        !_editable ||
        !identical(draft.menu, _menu) ||
        previous == null) {
      return;
    }
    if (draft.replace(item, previous)) _update(() {});
  }

  Widget _group(
    String title,
    List<DailyMealItem> items,
    TomorrowMealDraft draft,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      if (items.isEmpty)
        const Text(
          'No eligible dishes are currently configured. Our team will review this delivery.',
        ),
      for (final item in items)
        _MealCard(
          item: item,
          selected: draft.contains(item.id),
          onTap: _editable ? () => _selectDraft(item, draft) : null,
        ),
      const SizedBox(height: 8),
    ],
  );
}

class _DeliveryThumbnail extends StatelessWidget {
  const _DeliveryThumbnail({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SizedBox.square(
      dimension: 48,
      child: ColoredBox(
        color: const Color(0xFFE4EDE0),
        child: imageUrl?.trim().isNotEmpty == true
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.restaurant_rounded,
                  size: 22,
                  color: AppColors.emeraldGreen,
                ),
              )
            : const Icon(
                Icons.restaurant_rounded,
                size: 22,
                color: AppColors.emeraldGreen,
              ),
      ),
    ),
  );
}

class _CompactMealRow extends StatelessWidget {
  const _CompactMealRow({required this.item});
  final DailyMealItem item;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 44,
            height: 44,
            child: item.imageUrl?.isNotEmpty == true
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.restaurant,
                      color: AppColors.emeraldGreen,
                    ),
                  )
                : const Icon(Icons.restaurant, color: AppColors.emeraldGreen),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${item.category == 'snack' ? lookupAppLocalizations(Localizations.localeOf(context)).deliveriesSnack : lookupAppLocalizations(Localizations.localeOf(context)).deliveriesMeal}${item.calories == null ? '' : ' · ${item.calories!.round()} kcal'}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.item, required this.selected, this.onTap});
  final DailyMealItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: onTap != null,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFEDF8F1) : const Color(0xFFFAF9F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.emeraldGreen : const Color(0xFFE6EBE6),
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 76,
                    height: 80,
                    child: item.imageUrl?.isNotEmpty == true
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.restaurant_rounded,
                              color: AppColors.emeraldGreen,
                            ),
                          )
                        : const Icon(
                            Icons.restaurant_rounded,
                            color: AppColors.emeraldGreen,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      if (item.description?.isNotEmpty == true)
                        Text(
                          item.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (item.calories != null)
                        Text(
                          '${item.calories!.round()} kcal',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.emeraldGreen,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: AppColors.emeraldGreen,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
