import 'dart:async';

import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/dashboard/data/tomorrow_menu_repository.dart';
import 'package:diet_time/features/dashboard/domain/tomorrow_menu.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TomorrowMenuSection extends ConsumerStatefulWidget {
  const TomorrowMenuSection({super.key, required this.orderId});
  final String orderId;

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
    setState(() {
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
      setState(() {
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
    }
  }

  void _accept(TomorrowMenu menu) {
    setState(() {
      _menu = menu;
      _draft = TomorrowMealDraft(menu);
      _loading = false;
      _expired = !menu.canConfirm;
    });
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
      setState(() => _expired = true);
      if (!_submitting) _load();
    });
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
    setState(() {
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            if (menu.orderStatus != null)
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
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Chip(
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
              ),
              Text(
                menu.status == 'CUSTOMER_CONFIRMED'
                    ? 'Your meals are confirmed!'
                    : 'Your meals are ready for tomorrow.',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Text('Your selections for tomorrow have been saved.'),
            ] else if (menu.canConfirm && !_expired) ...[
              Text(
                'Choose ${menu.mealCount} meals and ${menu.snackCount} snack${menu.snackCount == 1 ? '' : 's'}.',
              ),
              const Text('Selection closes today at 9:00 PM Qatar time.'),
              const SizedBox(height: 12),
              Text('Meals: ${draft.mealIds.length}/${menu.mealCount} selected'),
              Text(
                'Snacks: ${draft.snackIds.length}/${menu.snackCount} selected',
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value:
                    (draft.mealIds.length + draft.snackIds.length) /
                    (menu.mealCount + menu.snackCount),
                color: AppColors.emeraldGreen,
                backgroundColor: const Color(0xFFEDF5EF),
              ),
            ] else ...[
              Text(menu.emptyReason ?? menu.reviewReason ?? menu.statusMessage),
            ],
            const SizedBox(height: 12),
            if (menu.canConfirm && !_expired) ...[
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
            ] else ...[
              for (final item in menu.selected)
                _MealCard(item: item, selected: true),
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
          onTap: _editable
              ? () {
                  final changed = draft.toggle(item);
                  if (changed) {
                    setState(() {});
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Remove a selected dish before choosing another.',
                        ),
                      ),
                    );
                  }
                }
              : null,
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
