import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plans = [
      _Plan(
        title: l10n.weightLoss,
        description: l10n.weightLossDescription,
        image: 'assets/images/onboarding_1.png',
        calories: 1500,
        price: 349,
      ),
      _Plan(
        title: l10n.keto,
        description: l10n.ketoDescription,
        image: 'assets/images/onboarding_3.png',
        calories: 1800,
        price: 399,
      ),
      _Plan(
        title: l10n.highProtein,
        description: l10n.highProteinDescription,
        image: 'assets/images/onboarding_2.png',
        calories: 2200,
        price: 429,
      ),
      _Plan(
        title: l10n.balancedDiet,
        description: l10n.balancedDietDescription,
        image: 'assets/images/onboarding_4.png',
        calories: 2000,
        price: 379,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3E9),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 16),
                    sliver: SliverList.list(
                      children: [
                        Text(
                          l10n.choosePlanTitle,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: 29,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.55,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.choosePlanSubtitle,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.4),
                        ),
                        const SizedBox(height: 22),
                        ...List.generate(
                          plans.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _PlanCard(
                              plan: plans[index],
                              selected: _selected == index,
                              calories: l10n.dailyCalories(
                                plans[index].calories,
                              ),
                              price: l10n.weeklyPrice(plans[index].price),
                              onTap: () => setState(() => _selected = index),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: AppButton(
                  label: l10n.continueLabel,
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.calories,
    required this.price,
    required this.onTap,
  });

  final _Plan plan;
  final bool selected;
  final String calories;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.teaGreen.withValues(alpha: .26)
                : AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? AppColors.emeraldGreen
                  : AppColors.darkGreen.withValues(alpha: .08),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkGreen.withValues(alpha: .07),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  plan.image,
                  width: 104,
                  height: 112,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  key: ValueKey('selected'),
                                  color: AppColors.emeraldGreen,
                                  size: 23,
                                )
                              : const Icon(
                                  Icons.circle_outlined,
                                  key: ValueKey('unselected'),
                                  color: Color(0x3320352D),
                                  size: 23,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      plan.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(alpha: .62),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Detail(icon: Icons.bolt_rounded, label: calories),
                        _Detail(icon: Icons.payments_outlined, label: price),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.emeraldGreen),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.emeraldGreen,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Plan {
  const _Plan({
    required this.title,
    required this.description,
    required this.image,
    required this.calories,
    required this.price,
  });

  final String title;
  final String description;
  final String image;
  final int calories;
  final int price;
}
