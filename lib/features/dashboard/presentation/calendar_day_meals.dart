import 'dart:math' as math;

import 'package:diet_time/app/localization/customer_copy.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/features/dashboard/presentation/calendar_meal_status.dart';
import 'package:diet_time/features/menu/domain/guest_home_models.dart';
import 'package:diet_time/features/menu/domain/meal_nutrition.dart';
import 'package:diet_time/features/menu/presentation/meal_detail_viewer.dart';
import 'package:diet_time/features/menu/presentation/meal_nutrition_view.dart';
import 'package:diet_time/features/plans/domain/meal_entitlement.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarDayMeals extends StatelessWidget {
  const CalendarDayMeals({
    super.key,
    required this.menu,
    required this.planName,
    required this.onReview,
    required this.onChange,
    this.showNutrition = true,
  });
  final DailyMealMenu menu;
  final bool showNutrition;
  final String planName;
  final VoidCallback onReview;
  final ValueChanged<AssignedDailyMeal>? onChange;

  @override
  Widget build(BuildContext context) {
    final status = calendarMealStatus(
      date: menu.date,
      status: menu.status,
      selectionStatus: menu.selectionStatus,
      deliveryStatus: menu.deliveryStatus,
      locked: menu.selectionLocked,
      editable: menu.editable,
      deadlinePassed: menu.deadlinePassed,
    );
    final message = switch (status) {
      CalendarMealStatus.actionNeeded =>
        '${context.customerCopy('Confirm your meals before')} ${menu.cutoffAt == null ? '—' : DateFormat.jm(Localizations.localeOf(context).toLanguageTag()).format(menu.cutoffAt!.toUtc().add(const Duration(hours: 3)))} ${context.customerCopy('Qatar time')}.',
      CalendarMealStatus.confirmed => context.customerCopy(
        'Your meals are confirmed.',
      ),
      CalendarMealStatus.selectedForYou => context.customerCopy(
        'Meals selected for you. The default selection will be used unless you confirm your own choices.',
      ),
      CalendarMealStatus.scheduled => context.customerCopy(
        'Meal selection will open closer to this date.',
      ),
      CalendarMealStatus.closed => context.customerCopy(
        'Meal selection is closed for this day.',
      ),
      CalendarMealStatus.noMeals => context.customerCopy(
        'No meals are scheduled for this day.',
      ),
    };
    return Column(
      key: ValueKey('dailyMenu-${menu.dayId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          planName,
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          MealEntitlement(
            menu.mealCount,
            menu.snackCount,
          ).label(Localizations.localeOf(context).languageCode),
          style: const TextStyle(fontSize: 12, color: AppColors.darkGreen),
        ),
        if (const {
              'DELIVERED',
              'COLLECTED',
            }.contains(menu.deliveryStatus.toUpperCase()) ||
            const {
              'DELIVERED',
              'COLLECTED',
            }.contains(menu.status.toUpperCase()))
          Text(
            context.customerCopy(
              menu.deliveryStatus.toUpperCase() == 'COLLECTED' ||
                      menu.status.toUpperCase() == 'COLLECTED'
                  ? 'Collected'
                  : 'Delivered',
            ),
            style: const TextStyle(fontSize: 11, color: AppColors.emeraldGreen),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: status == CalendarMealStatus.actionNeeded
                ? const Color(0xFFFFF0D5)
                : const Color(0xFFF0F5EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(status.icon, size: 17, color: status.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.customerCopy(status.label),
                      style: TextStyle(
                        color: status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  color: status.color,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              if (status == CalendarMealStatus.actionNeeded) ...[
                const SizedBox(height: 8),
                _ReviewAction(
                  key: ValueKey('calendarReview-${menu.dayId}'),
                  onPressed: onReview,
                ),
              ],
            ],
          ),
        ),
        if (status != CalendarMealStatus.noMeals) ...[
          const SizedBox(height: 10),
          if (showNutrition) CalendarNutritionSummary(meals: menu.selected),
          const SizedBox(height: 8),
          if (menu.selected.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                context.customerCopy(
                  'No meals are available for this day yet.',
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGreen,
                ),
              ),
            ),
          for (final selection in menu.selected)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _MealRow(
                key: ValueKey('assigned-${selection.id}'),
                selection: selection,
                confirmed: status == CalendarMealStatus.confirmed,
                onChange: onChange == null ? null : () => onChange!(selection),
              ),
            ),
        ],
      ],
    );
  }
}

class CalendarNutritionSummary extends StatelessWidget {
  const CalendarNutritionSummary({super.key, required this.meals});
  final Iterable<AssignedDailyMeal> meals;
  @override
  Widget build(BuildContext context) {
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    final total = MealNutrition.total(
      meals.map(
        (s) => (nutrition: s.meal.nutrition, quantity: s.meal.quantity),
      ),
    );
    return Container(
      key: const ValueKey('tourDailyNutrition'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E9E2)),
      ),
      child: total.complete
          ? MealNutritionView(total: true, nutrition: total)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.dailyNutritionTotal,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  copy.nutritionTotalsIncomplete,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF657B72),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    super.key,
    required this.selection,
    required this.confirmed,
    this.onChange,
  });
  final AssignedDailyMeal selection;
  final bool confirmed;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final meal = selection.meal;
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    final category = meal.mealTypes.isNotEmpty
        ? meal.mealTypes
              .map((type) => type.name)
              .where((name) => name.trim().isNotEmpty)
              .join(', ')
        : meal.category == 'snack'
        ? copy.deliveriesSnack
        : copy.deliveriesMeal;
    final calories = meal.nutrition.calories;
    final selectedLabel = confirmed
        ? context.customerCopy('Confirmed')
        : selection.source == 'automatic'
        ? context.customerCopy('Selected for You')
        : context.customerCopy('Your choice');
    final image = meal.imageUrl?.trim();
    final placeholder = const ColoredBox(
      color: Color(0xFFE7F2E9),
      child: Icon(
        Icons.restaurant_outlined,
        color: AppColors.emeraldGreen,
        size: 22,
      ),
    );
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3E9E2)),
      ),
      child: InkWell(
        onTap: () => showMealDetailViewer(
          context: context,
          initialIndex: 0,
          meals: [
            GuestMeal(
              id: meal.id,
              code: '',
              name: meal.name,
              description: meal.description,
              imageUrl: image,
              mealTime: GuestMealTime(code: meal.category, name: category),
              nutrition: GuestMealNutrition(
                calories: calories,
                protein: meal.nutrition.protein,
                carbs: meal.nutrition.carbs,
                fat: meal.nutrition.fat,
                fiber: meal.nutrition.fiber,
              ),
              tags: const [],
              allergens: const [],
              isAvailable: true,
              displayOrder: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: SizedBox.square(
                  dimension: 48,
                  child: image?.isNotEmpty == true
                      ? Image.network(
                          Uri.parse(
                            AppEnvironment.apiBaseUrl,
                          ).resolve(image!).toString(),
                          fit: BoxFit.cover,
                          cacheWidth:
                              (48 * MediaQuery.devicePixelRatioOf(context))
                                  .ceil(),
                          errorBuilder: (_, _, _) => placeholder,
                        )
                      : placeholder,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$category · ${calories == null ? copy.nutritionUnavailable : copy.kcal(calories.round())}',
                      style: const TextStyle(
                        color: Color(0xFF657B72),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selectedLabel,
                      style: const TextStyle(
                        color: AppColors.emeraldGreen,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (onChange != null)
                IconButton(
                  key: const ValueKey('tourChangeMeal'),
                  onPressed: onChange,
                  tooltip: context.customerCopy('Change Meal'),
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.emeraldGreen,
                    size: 20,
                  ),
                )
              else
                Icon(
                  confirmed
                      ? Icons.check_circle_outline
                      : Icons.chevron_right_rounded,
                  size: 17,
                  color: AppColors.emeraldGreen,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewAction extends StatefulWidget {
  const _ReviewAction({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  State<_ReviewAction> createState() => _ReviewActionState();
}

class _ReviewActionState extends State<_ReviewAction>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      _controller.stop();
      _controller.value = 0;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.repeat(count: 2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => Transform.scale(
      scale: 1 + .006 * (1 - math.cos(_controller.value * 2 * math.pi)),
      child: child,
    ),
    child: FilledButton(
      onPressed: widget.onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF17684F),
        minimumSize: const Size(0, 44),
      ),
      child: Text(context.customerCopy('Review & Confirm')),
    ),
  );
}
