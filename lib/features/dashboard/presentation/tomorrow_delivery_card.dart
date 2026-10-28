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
  });

  final TomorrowMenu menu;
  final TomorrowMealDraft draft;
  final String orderReference;
  final bool showDishes;
  final bool expired;
  final VoidCallback? onChoose;
  final VoidCallback onToggleDishes;
  final VoidCallback? onRefresh;

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
    final ready = state == TomorrowDeliveryState.readyToConfirm;
    final actionable = pending || ready;
    final label = switch (state) {
      TomorrowDeliveryState.selectionPending => copy.deliveriesPending,
      TomorrowDeliveryState.readyToConfirm => copy.deliveriesReady,
      TomorrowDeliveryState.confirmed => copy.deliveriesConfirmed,
      TomorrowDeliveryState.automaticallySelected => copy.deliveriesAutomatic,
      TomorrowDeliveryState.locked => copy.deliveriesLocked,
      TomorrowDeliveryState.unavailable => copy.deliveriesWaiting,
    };
    final reference = menu.orderNumber?.trim().isNotEmpty == true
        ? menu.orderNumber!.trim()
        : orderReference;
    final secondary = reference == menu.subscriptionId
        ? '#${reference.length > 8 ? reference.substring(reference.length - 8) : reference}'
        : reference;
    final accent = actionable
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
                    Tooltip(
                      message: copy.deliveriesOrder(reference),
                      child: Text(
                        copy.deliveriesOrder(secondary),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.darkGreen.withValues(alpha: .62),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actionable) ...[
            const SizedBox(height: 8),
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
                  copy.deliveriesDeadline,
                  style: TextStyle(fontSize: 11, color: accent),
                ),
              ],
            ),
          ] else if (!menu.readOnly) ...[
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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
              else if (onChoose != null)
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
                        ? copy.deliveriesChoose
                        : copy.deliveriesViewMenu,
                  ),
                )
              else
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
