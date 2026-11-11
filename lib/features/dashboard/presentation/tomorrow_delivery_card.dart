import 'dart:math' as math;
import 'package:diet_time/app/localization/customer_copy.dart';
import 'package:diet_time/features/menu/domain/meal_nutrition.dart';
import 'package:diet_time/features/menu/presentation/meal_nutrition_view.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/meal_plan_image.dart';
import 'package:diet_time/features/dashboard/domain/tomorrow_menu.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Presentation only: selection and confirmation stay in the order's controller.
class TomorrowDeliveryCard extends StatelessWidget {
  const TomorrowDeliveryCard({
    super.key,
    required this.menu,
    required this.draft,
    required this.orderReference,
    required this.showDishes,
    required this.expired,
    required this.onChoose,
    required this.onToggleDishes,
    required this.onRefresh,
    this.animateReminder = true,
    this.onReminderShown,
  });

  final TomorrowMenu menu;
  final TomorrowMealDraft draft;
  final String orderReference;
  final bool showDishes;
  final bool expired;
  final VoidCallback? onChoose;
  final VoidCallback onToggleDishes;
  final VoidCallback? onRefresh;
  final bool animateReminder;
  final VoidCallback? onReminderShown;

  @override
  Widget build(BuildContext context) {
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    final meals = menu.readOnly ? menu.savedMealCount : draft.mealIds.length;
    final snacks = menu.readOnly ? menu.savedSnackCount : draft.snackIds.length;
    final selected = meals + snacks;
    final total = menu.mealCount + menu.snackCount;
    final state = menu.deliveryState(
      mealsSelected: meals,
      snacksSelected: snacks,
      expired: expired,
    );
    final pending = state == TomorrowDeliveryState.selectionPending;
    final ready =
        state == TomorrowDeliveryState.readyToConfirm &&
        menu.scheduledForTomorrow;
    final confirmed = state == TomorrowDeliveryState.confirmed;
    final cutoff = DateFormat.jm(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(menu.cutoffAt.toUtc().add(const Duration(hours: 3)));
    final actionable =
        !menu.selectionBlockedByPendingPause && (pending || ready);
    final label = menu.selectionBlockedByPendingPause
        ? copy.packagePauseRequested
        : switch (state) {
            TomorrowDeliveryState.selectionPending => copy.deliveriesPending,
            TomorrowDeliveryState.readyToConfirm => copy.deliveriesReady,
            TomorrowDeliveryState.confirmed => copy.deliveriesConfirmed,
            TomorrowDeliveryState.automaticallySelected =>
              copy.deliveriesAutomatic,
            TomorrowDeliveryState.locked => copy.deliveriesLocked,
            TomorrowDeliveryState.unavailable => copy.deliveriesWaiting,
          };
    final accent = actionable || menu.selectionBlockedByPendingPause
        ? const Color(0xFF886018)
        : AppColors.emeraldGreen;
    final actionStyle = TextButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      foregroundColor: AppColors.emeraldGreen,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      elevation: 0,
      side: BorderSide.none,
    ).copyWith(backgroundBuilder: (_, _, child) => child ?? const SizedBox());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: menu.readOnly
            ? const Color(0xFFF2F7F0)
            : const Color(0xFFFFFEFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: menu.readOnly
              ? const Color(0xFFDDE7DA)
              : const Color(0xFFE8E3D8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                image: true,
                label: menu.planName,
                child: ExcludeSemantics(
                  child: MealPlanImage(imageUrl: menu.planImageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.planName,
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      copy.deliveriesPackage(menu.mealCount, menu.snackCount),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGreen.withValues(alpha: .78),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MealNutritionView(
            total: true,
            nutrition: MealNutrition.total(
              (menu.readOnly
                      ? menu.selected
                      : [
                          ...menu.meals,
                          ...menu.snacks,
                        ].where((m) => draft.contains(m.id)))
                  .map((m) => (nutrition: m.nutrition, quantity: m.quantity)),
            ),
          ),
          if (ready || confirmed) ...[
            const SizedBox(height: 8),
            if (ready)
              Text(
                copy.deliveriesProgress(selected, total),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.darkGreen,
                ),
              ),
            if (ready) const SizedBox(height: 6),
            _ConfirmationNotice(
              key: ValueKey('confirmationNotice-${menu.dayId}'),
              confirmed: confirmed,
              cutoff: cutoff,
              animate: animateReminder,
              onShown: onReminderShown,
              onReview: onChoose,
            ),
          ],
          if (menu.selectionBlockedByPendingPause) ...[
            const SizedBox(height: 8),
            Text(
              copy.packageMealSelectionPending,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF886018),
                height: 1.4,
              ),
            ),
          ] else if (pending && actionable) ...[
            const SizedBox(height: 8),
            Text(
              context.customerCopy('Choose your meals for tomorrow'),
              style: const TextStyle(fontSize: 12, color: AppColors.darkGreen),
            ),
            const SizedBox(height: 6),
            if (pending) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  key: ValueKey('deliveryProgress-${menu.subscriptionId}'),
                  minHeight: 3,
                  value: total == 0 ? 0 : (selected / total).clamp(0.0, 1.0),
                  color: AppColors.emeraldGreen,
                  backgroundColor: const Color(0xFFE7EBDF),
                  semanticsLabel: copy.deliveriesProgress(selected, total),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  copy.deliveriesProgress(selected, total),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.darkGreen,
                  ),
                ),
                Text(
                  '${context.customerCopy('Selection deadline')}: $cutoff',
                  style: TextStyle(fontSize: 11, color: accent),
                ),
              ],
            ),
          ] else if (!menu.readOnly && !ready) ...[
            const SizedBox(height: 8),
            Text(
              menu.emptyReason ??
                  menu.reviewReason ??
                  copy.deliveriesStatus(menu.status),
              style: const TextStyle(fontSize: 12, color: AppColors.darkGreen),
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
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              if (!ready && !confirmed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: actionable
                        ? const Color(0xFFFFF1D8)
                        : const Color(0xFFE2EDDF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (menu.readOnly)
                TextButton(
                  key: const ValueKey('toggleConfirmedMeals'),
                  onPressed: onToggleDishes,
                  style: actionStyle,
                  child: Text(
                    showDishes
                        ? copy.deliveriesHideDishes
                        : state == TomorrowDeliveryState.confirmed
                        ? copy.deliveriesViewConfirmed
                        : copy.deliveriesViewSelected,
                  ),
                )
              else if (onChoose != null && !ready)
                FilledButton(
                  key: const ValueKey('chooseTomorrowMeals'),
                  onPressed: onChoose,
                  style: actionStyle.copyWith(
                    backgroundColor: const WidgetStatePropertyAll(
                      AppColors.emeraldGreen,
                    ),
                    foregroundColor: const WidgetStatePropertyAll(
                      AppColors.white,
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    shadowColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                    surfaceTintColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                  ),
                  child: Text(
                    ready
                        ? copy.deliveriesReviewConfirm
                        : pending
                        ? context.customerCopy('Choose Meals')
                        : copy.deliveriesViewMenu,
                  ),
                )
              else if (!ready)
                TextButton(
                  onPressed: onRefresh,
                  style: actionStyle,
                  child: Text(copy.deliveriesRefresh),
                ),
            ],
          ),
          if (menu.readOnly)
            AnimatedSize(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              alignment: Alignment.topCenter,
              child: showDishes
                  ? Column(
                      children: [
                        for (final item in menu.selected)
                          _ReadOnlyDish(item: item),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
        ],
      ),
    );
  }
}

class _ConfirmationNotice extends StatefulWidget {
  const _ConfirmationNotice({
    super.key,
    required this.confirmed,
    required this.cutoff,
    required this.animate,
    required this.onShown,
    required this.onReview,
  });

  final bool confirmed, animate;
  final String cutoff;
  final VoidCallback? onShown, onReview;

  @override
  State<_ConfirmationNotice> createState() => _ConfirmationNoticeState();
}

class _ConfirmationNoticeState extends State<_ConfirmationNotice>
    with TickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: 1,
  );
  late final _breathing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final _check = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );
  bool _started = false;
  bool get _reducedMotion =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedMotion) {
      _entrance.stop();
      _entrance.value = 1;
      _breathing.stop();
      _breathing.value = 0;
      _check.stop();
      _check.value = 1;
    }
    if (_started) return;
    _started = true;
    if (!widget.confirmed) {
      widget.onShown?.call();
      if (widget.animate && !_reducedMotion) {
        _entrance.forward(from: 0);
        // Each controller iteration is one complete, gentle breathing cycle.
        _breathing.repeat(count: 2);
      }
    }
  }

  @override
  void didUpdateWidget(covariant _ConfirmationNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.confirmed && !oldWidget.confirmed) {
      _breathing.stop();
      _breathing.value = 0;
      _entrance.value = 1;
      if (!_reducedMotion) _check.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _breathing.dispose();
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF17684F);
    const amber = Color(0xFF895C25);
    final duration = _reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 250);
    return FadeTransition(
      opacity: _entrance,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .06),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_entrance),
        child: AnimatedContainer(
          duration: duration,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.confirmed
                ? const Color(0xFFE8F3EB)
                : const Color(0xFFFFF0D5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedSwitcher(
            duration: duration,
            child: widget.confirmed
                ? Row(
                    key: const ValueKey('mealsConfirmedIndicator'),
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: .75, end: 1.0).animate(_check),
                        child: FadeTransition(
                          opacity: _check,
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          context.customerCopy('Meals Confirmed'),
                          style: const TextStyle(
                            color: green,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('mealConfirmationReminder'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: amber,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              '${context.customerCopy('Confirm your meals by')} ${widget.cutoff}',
                              style: const TextStyle(
                                color: amber,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.customerCopy(
                          "Your meals are selected. Please confirm them to complete tomorrow's order.",
                        ),
                        style: const TextStyle(
                          color: amber,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _breathing,
                        builder: (context, child) {
                          final wave =
                              (1 - math.cos(_breathing.value * 2 * math.pi)) /
                              2;
                          return Transform.scale(
                            key: const ValueKey('mealConfirmationBreathing'),
                            scale: 1 + .012 * wave,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: green.withValues(alpha: .09 * wave),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: FilledButton(
                          key: const ValueKey('chooseTomorrowMeals'),
                          onPressed: widget.onReview,
                          style: FilledButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  context.customerCopy(
                                    'Review & Confirm Meals',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyDish extends StatelessWidget {
  const _ReadOnlyDish({required this.item});
  final DailyMealItem item;

  @override
  Widget build(BuildContext context) {
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox.square(
              dimension: 36,
              child: item.imageUrl?.isNotEmpty == true
                  ? Image.network(
                      item.imageUrl!,
                      cacheWidth: (36 * MediaQuery.devicePixelRatioOf(context))
                          .ceil(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.restaurant_outlined,
                        color: AppColors.emeraldGreen,
                      ),
                    )
                  : const Icon(
                      Icons.restaurant_outlined,
                      color: AppColors.emeraldGreen,
                    ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.category == 'snack'
                      ? copy.deliveriesSnack
                      : copy.deliveriesMeal,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.emeraldGreen,
                  ),
                ),
                MealNutritionDetails(meal: item),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
