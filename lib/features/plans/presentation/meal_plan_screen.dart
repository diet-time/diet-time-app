import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/config/app_environment.dart';
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
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3E9),
      body: SafeArea(
        child: Column(
          children: [
            if (canPop)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  key: const ValueKey('mealPlanBackButton'),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                  color: AppColors.darkGreen,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            Expanded(
              child: plans.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.emeraldGreen,
                  ),
                ),
                error: (_, _) => _PlanLoadState(
                  onRetry: () => ref.invalidate(mealPlansProvider(language)),
                ),
                data: (items) => items.isEmpty
                    ? _PlanLoadState(
                        empty: true,
                        onRetry: () =>
                            ref.invalidate(mealPlansProvider(language)),
                      )
                    : _buildPlanList(context, items, showBackButton: canPop),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanList(
    BuildContext context,
    List<MealPlanOption> plans, {
    required bool showBackButton,
  }) {
    final l10n = AppLocalizations.of(context);
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
                padding: EdgeInsets.fromLTRB(
                  13,
                  showBackButton ? 4 : 24,
                  13,
                  8,
                ),
                sliver: SliverList.list(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        l10n.choosePlanTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontSize: 34,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.05,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child: Text(
                        l10n.choosePlanSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.darkGreen.withValues(alpha: .82),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final plan in plans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
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
          padding: const EdgeInsets.fromLTRB(6, 3, 6, 13),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SizedBox(
              height: 47,
              child: FilledButton(
                onPressed: () =>
                    context.push(AppRoutes.planDetails, extra: selectedPlan),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emeraldGreen,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text(
                  l10n.continueLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          height: 153,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF1F7ED) : AppColors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? AppColors.emeraldGreen
                  : AppColors.darkGreen.withValues(alpha: .08),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkGreen.withValues(alpha: .09),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: 0,
                width: 210,
                child: _PlanImage(imageUrl: plan.imageUrl),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 17, 10, 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  key: ValueKey('selected'),
                                  color: AppColors.emeraldGreen,
                                  size: 22,
                                )
                              : Icon(
                                  Icons.circle_outlined,
                                  key: const ValueKey('unselected'),
                                  color: AppColors.darkGreen.withValues(
                                    alpha: .22,
                                  ),
                                  size: 22,
                                ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: 16,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (plan.description case final description?) ...[
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 180,
                                child: Text(
                                  description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.darkGreen.withValues(
                                      alpha: .58,
                                    ),
                                    fontSize: 10.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            SizedBox(
                              width: 190,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _Detail(
                                      icon:
                                          Icons.local_fire_department_outlined,
                                      label: _calorieLabel(
                                        context,
                                        plan.dailyCaloriesKcal,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 31,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    color: AppColors.darkGreen.withValues(
                                      alpha: .14,
                                    ),
                                  ),
                                  Expanded(child: _PlanPriceDetail(plan: plan)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: AlignmentDirectional.centerStart,
        end: AlignmentDirectional.centerEnd,
        colors: [Colors.transparent, Colors.black, Colors.black],
        stops: [0, .28, 1],
      ).createShader(bounds, textDirection: Directionality.of(context)),
      child: image.isEmpty
          ? const _ImagePlaceholder()
          : Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ImagePlaceholder(),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: muted
              ? AppColors.darkGreen.withValues(alpha: .42)
              : AppColors.emeraldGreen,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            textDirection: forceLtr ? TextDirection.ltr : null,
            maxLines: 2,
            style: TextStyle(
              color: muted
                  ? AppColors.darkGreen.withValues(alpha: .52)
                  : AppColors.emeraldGreen,
              fontSize: 9.5,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
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
            width: 48,
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
