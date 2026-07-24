import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BrowseMenuScreen extends StatelessWidget {
  const BrowseMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meals = [
      _Meal(
        image: 'assets/images/onboarding_1.png',
        name: l10n.mealGrilledChicken,
        detail: l10n.mealGrilledChickenDetail,
        calories: 480,
      ),
      _Meal(
        image: 'assets/images/onboarding_3.png',
        name: l10n.mealSalmon,
        detail: l10n.mealSalmonDetail,
        calories: 520,
      ),
      _Meal(
        image: 'assets/images/onboarding_2.png',
        name: l10n.mealKeto,
        detail: l10n.mealKetoDetail,
        calories: 450,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3E9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth < 600 ? 20.0 : 48.0;
            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          28,
                          horizontal,
                          0,
                        ),
                        sliver: SliverList.list(
                          children: [
                            _Entrance(
                              delay: 0,
                              child: Text(
                                l10n.browseMenuTitle,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.6,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _Entrance(
                              delay: 70,
                              child: Text(
                                l10n.browseMenuSubtitle,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(height: 1.45),
                              ),
                            ),
                            const SizedBox(height: 28),
                            _Entrance(
                              delay: 110,
                              child: Text(
                                l10n.popularMeals,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: constraints.maxHeight < 650 ? 270 : 330,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: meals.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 14),
                                itemBuilder: (context, index) => _Entrance(
                                  delay: 150 + (index * 70),
                                  child: _MealCard(
                                    meal: meals[index],
                                    calorieLabel: l10n.kcal(
                                      meals[index].calories,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: AppButton(
                      label: l10n.browseMenu,
                      onPressed: () => context.go(AppRoutes.plans),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.calorieLabel});

  final _Meal meal;
  final String calorieLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 244,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: .10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Hero(
              tag: 'meal-${meal.name}',
              child: Image.asset(meal.image, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  meal.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .60),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teaGreen.withValues(alpha: .28),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    calorieLabel,
                    style: const TextStyle(
                      color: AppColors.emeraldGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

class _Entrance extends StatelessWidget {
  const _Entrance({required this.delay, required this.child});

  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _Meal {
  const _Meal({
    required this.image,
    required this.name,
    required this.detail,
    required this.calories,
  });

  final String image;
  final String name;
  final String detail;
  final int calories;
}
