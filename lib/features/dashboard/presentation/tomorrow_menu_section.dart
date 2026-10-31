import 'package:diet_time/app/localization/customer_copy.dart';
import 'package:diet_time/features/menu/domain/meal_nutrition.dart';
import 'package:diet_time/features/menu/presentation/meal_nutrition_view.dart';
import 'package:diet_time/features/plans/domain/meal_entitlement.dart';
import 'dart:async';

import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/dashboard/data/tomorrow_menu_repository.dart';
import 'package:diet_time/features/dashboard/data/upcoming_meals_repository.dart';
import 'package:diet_time/features/dashboard/domain/tomorrow_menu.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/features/dashboard/presentation/tomorrow_delivery_card.dart';
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
    this.scheduledOnly = false,
  });
  final String orderId;
  final String? orderReference;
  final ValueChanged<TomorrowMenu?>? onMenuLoaded;
  final bool scheduledOnly;

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
      _load(preserveDraft: true);
    }
  }

  @override
  void didUpdateWidget(covariant TomorrowMenuSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_submitting) {
      _load(preserveDraft: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({String? feedback, bool preserveDraft = false}) async {
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
      _accept(menu, preserveDraft: preserveDraft);
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      _update(() {
        _menu = null;
        _loading = false;
        _error =
            feedback ??
            switch (error) {
              ApiException(failure: ApiFailure.unauthorized) =>
                context.customerCopy(
                  'Your session has expired. Please sign in again.',
                ),
              ApiException(failure: ApiFailure.notFound) => context.customerCopy(
                'This order could not be loaded for your account. Refresh your dashboard or contact our team for help.',
              ),
              ApiException(failure: ApiFailure.network || ApiFailure.timeout) =>
                context.customerCopy(
                  'We could not connect to load your menu. Check your connection and try again.',
                ),
              _ => context.customerCopy(
                'The menu service could not load your order’s dishes. Please refresh or contact our team.',
              ),
            };
      });
      widget.onMenuLoaded?.call(null);
    }
  }

  void _accept(TomorrowMenu menu, {bool preserveDraft = false}) {
    final previous = _draft;
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
      if (preserveDraft &&
          previous != null &&
          previous.menu.dayId == menu.dayId &&
          previous.menu.subscriptionId == menu.subscriptionId &&
          !menu.readOnly) {
        _draft!.mealIds.clear();
        _draft!.snackIds.clear();
        for (final item in [...menu.meals, ...menu.snacks]) {
          if (previous.contains(item.id) && !_draft!.contains(item.id)) {
            _draft!.toggle(item);
          }
        }
      }
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
                backgroundColor: const Color(0xFFF8F6EF),
                bottomNavigationBar: _buildAction(routeContext),
                appBar: AppBar(
                  title: Text(
                    lookupAppLocalizations(
                      Localizations.localeOf(context),
                    ).deliveriesChoose,
                  ),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildPanel(routeContext),
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
      !_loading &&
      !_expired &&
      !_submitting &&
      _menu?.canConfirm == true &&
      _menu?.readOnly == false;

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
                context.customerCopy('Confirm your meals'),
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
              Text(
                context.customerCopy(
                  'Your selections cannot be changed after confirmation.',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.customerCopy('Confirm')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.customerCopy('Cancel')),
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
              'cutoff_passed' => context.customerCopy(
                'The 9:00 PM deadline has passed. Your automatic meals are being finalized.',
              ),
              'already_confirmed' => context.customerCopy(
                'Your meals have already been finalized. Here are your saved dishes.',
              ),
              'subscription_inactive' => context.customerCopy(
                'Your subscription is no longer active for this delivery.',
              ),
              'meal_unavailable' || 'invalid_selection' => context.customerCopy(
                'A dish is no longer available. Please review the refreshed menu.',
              ),
              _ => context.customerCopy(
                'We could not verify your confirmation. Please check your connection and refresh before trying again.',
              ),
            }
          : context.customerCopy(
              'Unable to confirm your meals. Please try again.',
            );
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
    if (widget.scheduledOnly && menu != null && !menu.scheduledForTomorrow) {
      return const SizedBox.shrink();
    }
    final reference = widget.orderReference?.trim().isNotEmpty == true
        ? widget.orderReference!.trim()
        : widget.orderId;
    return Column(
      key: ValueKey('tomorrowMenu-${widget.orderId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_loading && menu != null && _draft != null)
          TomorrowDeliveryCard(
            menu: menu,
            draft: _draft!,
            orderReference: reference,
            showDishes: _showConfirmed,
            expired: _expired,
            onToggleDishes: () =>
                _update(() => _showConfirmed = !_showConfirmed),
            onChoose:
                !_submitting &&
                    menu.dayId != null &&
                    !menu.readOnly &&
                    (menu.meals.isNotEmpty || menu.snacks.isNotEmpty)
                ? _openSelection
                : null,
            onRefresh: _submitting ? null : () => _load(),
          )
        else if (_loading)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Semantics(
                  label: copy.deliveriesLoading,
                  child: Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF3E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    );
  }

  Widget _buildAction(BuildContext context) {
    final menu = _menu;
    final draft = _draft;
    if (_loading || menu == null || draft == null || menu.readOnly) {
      return const SizedBox.shrink();
    }
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              draft.hasChanges
                  ? copy.chooserUnsaved
                  : menu.selected.isNotEmpty
                  ? copy.chooserSaved
                  : copy.deliveriesPending,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.darkGreen),
            ),
            const SizedBox(height: 6),
            FilledButton(
              key: const ValueKey('confirmTomorrowMeals'),
              onPressed: _editable && draft.complete ? _confirm : null,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.customerCopy('Confirm My Meals')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final menu = _menu;
    final draft = _draft;
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (menu == null || draft == null) {
      return Column(
        children: [
          if (_error != null) Text(_error!),
          TextButton(
            onPressed: () => _load(preserveDraft: true),
            child: Text(copy.deliveriesRefresh),
          ),
        ],
      );
    }
    final selected = menu.readOnly
        ? menu.selected
        : [
            ...menu.meals.where((m) => draft.mealIds.contains(m.id)),
            ...menu.snacks.where((m) => draft.snackIds.contains(m.id)),
          ];
    final count = menu.readOnly
        ? menu.savedMealCount + menu.savedSnackCount
        : draft.mealIds.length + draft.snackIds.length;
    final total = menu.mealCount + menu.snackCount;
    return Column(
      key: ValueKey('tomorrowMenu-${widget.orderId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          DateFormat(
            'EEEE, d MMMM',
            Localizations.localeOf(context).toLanguageTag(),
          ).format(menu.deliveryDate),
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          menu.planName,
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          MealEntitlement(
            menu.mealCount,
            menu.snackCount,
          ).label(Localizations.localeOf(context).languageCode),
        ),
        const SizedBox(height: 12),
        Text(
          copy.deliveriesProgress(count, total),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: total > 0 ? (count / total).clamp(0, 1) : 0,
          color: AppColors.emeraldGreen,
          backgroundColor: const Color(0xFFE0E9DE),
          borderRadius: BorderRadius.circular(8),
          minHeight: 6,
        ),
        const SizedBox(height: 8),
        if (menu.finalized)
          Text(
            context.customerCopy(
              menu.status == 'CUSTOMER_CONFIRMED'
                  ? 'Confirmed'
                  : 'Automatically finalized',
            ),
            style: const TextStyle(
              color: AppColors.emeraldGreen,
              fontWeight: FontWeight.w800,
            ),
          )
        else if (menu.canConfirm && !_expired) ...[
          Text(
            draft.complete
                ? copy.chooserReady
                : copy.chooserRemaining(
                    menu.mealCount - draft.mealIds.length,
                    menu.snackCount - draft.snackIds.length,
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            context.customerCopy(
              'Selection closes today at 9:00 PM Qatar time.',
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ] else if (!menu.readOnly)
          Text(menu.emptyReason ?? menu.reviewReason ?? menu.statusMessage),
        if (menu.readOnly) Text(copy.deliveriesStatus('LOCKED')),
        const SizedBox(height: 12),
        MealNutritionView(
          total: true,
          nutrition: MealNutrition.total(
            selected.map((m) => (nutrition: m.nutrition, quantity: m.quantity)),
          ),
        ),
        const SizedBox(height: 16),
        ..._mealGroups(menu, draft),
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: _submitting ? null : () => _load(preserveDraft: true),
            child: Text(copy.deliveriesRefresh),
          ),
        ],
      ],
    );
  }

  List<Widget> _mealGroups(TomorrowMenu menu, TomorrowMealDraft draft) {
    final types = <String, DailyMealType>{};
    final groups = <String, List<DailyMealItem>>{};
    final ungrouped = <String, List<DailyMealItem>>{};
    final items = menu.readOnly
        ? menu.selected
        : [...menu.meals, ...menu.snacks];
    for (final item in items) {
      if (item.mealTypes.isEmpty) (ungrouped[item.category] ??= []).add(item);
      for (final type in item.mealTypes) {
        types[type.id] = type;
        final items = groups[type.id] ??= [];
        if (!items.any((existing) => existing.id == item.id)) items.add(item);
      }
    }
    // Resolve ties using response order, without sorting by IDs or names.
    final ordered = types.values.toList();
    final positions = {
      for (var i = 0; i < ordered.length; i++) ordered[i].id: i,
    };
    ordered.sort((a, b) {
      final order = a.displayOrder.compareTo(b.displayOrder);
      return order != 0 ? order : positions[a.id]!.compareTo(positions[b.id]!);
    });
    return [
      for (final type in ordered) _group(type.name, groups[type.id]!, draft),
      // Older APIs without meal-type metadata retain their meal/snack grouping.
      for (final entry in ungrouped.entries)
        _group(
          context.customerCopy(entry.key == 'snack' ? 'Snacks' : 'Meals'),
          entry.value,
          draft,
        ),
    ];
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
                          ? context.customerCopy('Replace a meal')
                          : context.customerCopy('Replace a snack'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lookupAppLocalizations(
                        Localizations.localeOf(context),
                      ).chooserLimitHint,
                    ),
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
        Text(
          context.customerCopy(
            'No eligible dishes are currently configured. Our team will review this delivery.',
          ),
        ),
      for (final item in items)
        _MealCard(
          item: item,
          selected: draft.menu.readOnly
              ? draft.menu.selected.any((saved) => saved.id == item.id)
              : draft.contains(item.id),
          onTap: _editable ? () => _selectDraft(item, draft) : null,
        ),
      const SizedBox(height: 8),
    ],
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
        color: selected ? const Color(0xFFEDF8F1) : Colors.white,
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
                      if (selected)
                        Text(
                          lookupAppLocalizations(
                            Localizations.localeOf(context),
                          ).chooserSelected,
                          style: const TextStyle(
                            color: AppColors.emeraldGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      MealNutritionDetails(meal: item, compact: true),
                    ],
                  ),
                ),
                ...[
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
