import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({super.key});

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  String? _selectedCode;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final plans = ref.watch(mealPlansProvider(language));
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3E9),
      body: SafeArea(
        child: plans.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.emeraldGreen),
          ),
          error: (_, _) => _PlanLoadState(
            onRetry: () => ref.invalidate(mealPlansProvider(language)),
          ),
          data: (items) => items.isEmpty
              ? _PlanLoadState(
                  empty: true,
                  onRetry: () => ref.invalidate(mealPlansProvider(language)),
                )
              : _buildPlanList(context, items),
        ),
      ),
    );
  }

  Widget _buildPlanList(BuildContext context, List<MealPlanOption> plans) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(otpAuthControllerProvider);
    final selectedCode = plans.any((plan) => plan.code == _selectedCode)
        ? _selectedCode!
        : plans.first.code;
    final selectedPlan = plans.firstWhere((plan) => plan.code == selectedCode);
    return Column(
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
                    for (final plan in plans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _PlanCard(
                          plan: plan,
                          selected: selectedCode == plan.code,
                          onTap: () =>
                              setState(() => _selectedCode = plan.code),
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
              onPressed: () {
                final destination = PendingAuthDestination(
                  route: AppRoutes.home,
                  planCode: selectedPlan.code,
                  planName: selectedPlan.name,
                );
                if (authState.isAuthenticated) {
                  ref
                      .read(otpAuthControllerProvider.notifier)
                      .begin(destination);
                  context.go(AppRoutes.home);
                  return;
                }
                context.push(AppRoutes.phoneLogin, extra: destination);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final MealPlanOption plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: AppLocalizations.of(context).selectMealPlanSemantics(plan.name),
      child: InkWell(
        key: ValueKey('mealPlan-${plan.code}'),
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
              _PlanImage(imageUrl: plan.imageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.name,
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
                    if (plan.description case final description?) ...[
                      const SizedBox(height: 5),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.darkGreen.withValues(alpha: .62),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Detail(
                          icon: Icons.local_fire_department_outlined,
                          label: _calorieLabel(context, plan.dailyCaloriesKcal),
                        ),
                        _PlanPriceDetail(plan: plan),
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

  String _calorieLabel(BuildContext context, double? calories) =>
      calories == null
      ? 'Calories unavailable'
      : AppLocalizations.of(context).dailyCalories(calories.round());
}

class _PlanImage extends StatelessWidget {
  const _PlanImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final image = _resolveImageUrl(imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 104,
        height: 112,
        child: image.isEmpty
            ? const _ImagePlaceholder()
            : Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ImagePlaceholder(),
              ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE9F1E8),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: AppColors.emeraldGreen,
          size: 34,
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.icon,
    required this.label,
    this.muted = false,
    this.forceLtr = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool muted;
  final bool forceLtr;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: muted
              ? AppColors.darkGreen.withValues(alpha: .42)
              : AppColors.emeraldGreen,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          textDirection: forceLtr ? TextDirection.ltr : null,
          style: TextStyle(
            color: muted
                ? AppColors.darkGreen.withValues(alpha: .52)
                : AppColors.emeraldGreen,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PlanPriceDetail extends StatelessWidget {
  const _PlanPriceDetail({required this.plan});

  final MealPlanOption plan;

  @override
  Widget build(BuildContext context) {
    if (plan.isPriceLoading) {
      return Row(
        key: ValueKey('mealPlanPriceLoading-${plan.code}'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.payments_outlined,
            size: 14,
            color: AppColors.emeraldGreen,
          ),
          const SizedBox(width: 4),
          Container(
            width: 86,
            height: 11,
            decoration: BoxDecoration(
              color: AppColors.darkGreen.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      );
    }

    final l10n = AppLocalizations.of(context);
    final price = plan.dailyPrice;
    final currency = plan.currencyCode;
    final hasPrice = plan.hasActivePrice && price != null && currency != null;
    final label = hasPrice
        ? l10n.dailyPlanPrice(
            currency,
            formatMealPlanPriceAmount(
              price,
              Localizations.localeOf(context).toLanguageTag(),
            ),
          )
        : l10n.dailyPriceUnavailable;
    return _Detail(
      key: ValueKey('mealPlanDailyPrice-${plan.code}'),
      icon: Icons.payments_outlined,
      label: label,
      muted: !hasPrice,
      forceLtr: hasPrice,
    );
  }
}

class _PlanLoadState extends StatelessWidget {
  const _PlanLoadState({required this.onRetry, this.empty = false});

  final VoidCallback onRetry;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restaurant_menu_rounded,
              size: 46,
              color: AppColors.emeraldGreen,
            ),
            const SizedBox(height: 12),
            Text(
              empty
                  ? 'No meal plans are available yet.'
                  : 'Unable to load meal plans.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _resolveImageUrl(String? value) {
  final candidate = value?.trim() ?? '';
  if (candidate.isEmpty) return '';
  final parsed = Uri.tryParse(candidate);
  if (parsed != null && parsed.hasScheme) return candidate;
  return Uri.parse(AppEnvironment.apiBaseUrl).resolve(candidate).toString();
}
