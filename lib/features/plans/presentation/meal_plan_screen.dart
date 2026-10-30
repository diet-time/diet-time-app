import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/meal_plan_image.dart';
import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
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
                              fontSize: 28,
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
              width: double.infinity,
              height: 50,
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
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: AppLocalizations.of(context).selectMealPlanSemantics(plan.name),
    child: Material(
      key: ValueKey('mealPlan-${plan.code}'),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.emeraldGreen : const Color(0xFFDDE3D8),
          width: selected ? 1.8 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 2.2,
              child: _PlanImage(imageUrl: plan.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (plan.description?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text(
                            plan.description!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF54665B),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    key: selected
                        ? const ValueKey('selected')
                        : const ValueKey('unselected'),
                    color: selected
                        ? AppColors.emeraldGreen
                        : const Color(0xFF8B9A8B),
                    size: 22,
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

class _PlanImage extends StatelessWidget {
  const _PlanImage({this.imageUrl});
  final String? imageUrl;
  @override
  Widget build(BuildContext context) {
    final url = _resolveImageUrl(imageUrl);
    const placeholder = ColoredBox(
      color: Color(0xFFEAF0E3),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 40,
          color: AppColors.emeraldGreen,
        ),
      ),
    );
    return url.isEmpty
        ? placeholder
        : Image.network(
            url,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, _, _) => placeholder,
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

String _resolveImageUrl(String? value) => resolvePlanImageUrl(value);
