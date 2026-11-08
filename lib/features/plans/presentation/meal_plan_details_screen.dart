import 'package:diet_time/app/localization/customer_copy.dart';
import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/meal_plan_image.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:diet_time/features/plans/presentation/subscription_selection_widgets.dart';
import 'package:flutter/material.dart';
import 'package:diet_time/core/performance/performance_trace.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:diet_time/features/personalization/presentation/customer_onboarding_coordinator.dart';

typedef MealPlanContinue =
    void Function(String mealPlanTemplateId, String mealPlanPriceId);

class MealPlanDetailsScreen extends ConsumerStatefulWidget {
  const MealPlanDetailsScreen({required this.plan, this.onContinue, super.key});

  final MealPlanOption plan;
  final MealPlanContinue? onContinue;

  @override
  ConsumerState<MealPlanDetailsScreen> createState() =>
      _MealPlanDetailsScreenState();
}

class _MealPlanDetailsScreenState extends ConsumerState<MealPlanDetailsScreen>
    with FirstContentTrace {
  String? _configurationId;
  String? _priceId;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final request = (plan: widget.plan, language: language);
    final configurations = ref.watch(mealPlanConfigurationsProvider(request));
    traceFirstContent('meal_plan_details', ready: configurations.hasValue);
    return _PageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const _DetailsHeader(),
        body: SafeArea(
          top: false,
          bottom: false,
          child: configurations.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => _LoadingBody(plan: widget.plan),
            error: (_, _) => _PricingError(
              plan: widget.plan,
              onRetry: () =>
                  ref.invalidate(mealPlanConfigurationsProvider(request)),
            ),
            data: (items) => items.isEmpty
                ? _EmptyPackages(plan: widget.plan)
                : _buildContent(items),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<MealPlanConfiguration> configurations) {
    final configuration = configurations.firstWhere(
      (item) => item.id == _configurationId,
      orElse: () => configurations.first,
    );
    final package = configuration.packages.firstWhere(
      (item) => item.selectionKey == _priceId,
      orElse: () => configuration.packages.first,
    );
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsetsDirectional.fromSTEB(18, 2, 18, 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PlanHero(plan: widget.plan),
                    const SizedBox(height: 16),
                    _SectionTitle(
                      icon: Icons.restaurant_outlined,
                      titleEn: 'Daily Meal Option',
                      titleAr: 'اختر وجباتك اليومية',
                    ),
                    const SizedBox(height: 8),
                    SubscriptionSelectionRow(
                      key: const ValueKey('mealConfigurations'),
                      builder: (width) => [
                        for (final item in configurations) ...[
                          if (item != configurations.first)
                            const SizedBox(width: 10),
                          PackageSelectionCard(
                            width: width,
                            key: ValueKey('configuration-${item.id}'),
                            name: item.displayName(
                              Localizations.localeOf(context).languageCode,
                            ),
                            description: item.description,
                            package:
                                item.packages
                                    .where(
                                      (p) =>
                                          p.isValid &&
                                          p.serviceDays == package.serviceDays,
                                    )
                                    .firstOrNull ??
                                item.packages
                                    .where((p) => p.isValid)
                                    .firstOrNull,
                            selected: item.id == configuration.id,
                            onTap: () => setState(() {
                              _configurationId = item.id;
                              final matching = item.packages.where(
                                (candidate) =>
                                    candidate.isValid &&
                                    candidate.name == package.name &&
                                    candidate.serviceDays ==
                                        package.serviceDays,
                              );
                              final valid = item.packages.where(
                                (p) => p.isValid,
                              );
                              _priceId = matching.isNotEmpty
                                  ? matching.first.selectionKey
                                  : valid.isNotEmpty
                                  ? valid.first.selectionKey
                                  : item.packages.first.selectionKey;
                            }),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(
                      icon: Icons.calendar_month_outlined,
                      titleEn: 'Choose Duration',
                      titleAr: 'اختر المدة',
                    ),
                    const SizedBox(height: 10),
                    SubscriptionSelectionRow(
                      key: const ValueKey('packageDurations'),
                      builder: (width) => [
                        for (final option in configuration.packages) ...[
                          if (option != configuration.packages.first)
                            const SizedBox(width: 10),
                          DurationSelectionCard(
                            key: ValueKey('duration-${option.selectionKey}'),
                            name: option.name,
                            priceDetails: option.isValid
                                ? PackageCardPrice(package: option)
                                : null,
                            deliveryDays: option.isValid
                                ? _serviceDaysLabel(context, option.serviceDays)
                                : Directionality.of(context) ==
                                      TextDirection.rtl
                                ? 'غير متاح حالياً'
                                : context.customerCopy('Currently unavailable'),
                            selected:
                                option.isValid &&
                                option.selectionKey == package.selectionKey,
                            width: width,
                            onTap: option.isValid
                                ? () => setState(
                                    () => _priceId = option.selectionKey,
                                  )
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SubscriptionPricingSummary(
          package: package,
          meals: configuration.displayName(
            Localizations.localeOf(context).languageCode,
          ),
          duration:
              '${package.name} (${_serviceDaysLabel(context, package.serviceDays)})',
          total: package.isValid
              ? '${package.currencyCode} ${_amount(context, package.totalPrice)}'
              : Directionality.of(context) == TextDirection.rtl
              ? 'السعر غير متاح'
              : context.customerCopy('Pricing unavailable'),
          priceKey: '${configuration.id}-${package.selectionKey}',
          onContinue: package.isValid
              ? () => _continue(configuration, package)
              : null,
        ),
      ],
    );
  }

  Future<void> _continue(
    MealPlanConfiguration configuration,
    MealPlanPackage package,
  ) async {
    if (!package.isValid) return;
    widget.onContinue?.call(widget.plan.id, package.mealPlanPriceId);
    if (widget.onContinue != null) return;
    if (!ref.read(customerOnboardingReadyProvider)) {
      context.go(AppRoutes.startPlan);
      return;
    }
    final selection = MealPlanPurchaseSelection(
      mealPlan: widget.plan,
      mealCombination: configuration,
      pricingOption: package,
    );
    ref.read(checkoutControllerProvider.notifier).selectPackage(selection);
    context.push(AppRoutes.checkoutEntry);
  }
}

class _DetailsHeader extends StatelessWidget implements PreferredSizeWidget {
  const _DetailsHeader();
  @override
  Size get preferredSize => const Size.fromHeight(44);
  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 44,
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    leading: Center(
      child: SizedBox.square(
        dimension: 32,
        child: IconButton(
          key: const ValueKey('detailsBack'),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(backgroundColor: const Color(0xFFE0F0E4)),
          onPressed: () => context.pop(),
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_right_rounded
                : Icons.chevron_left_rounded,
            size: 24,
            color: AppColors.darkGreen,
          ),
        ),
      ),
    ),
    title: Text(
      context.customerCopy('Diet Time'),
      style: const TextStyle(
        color: AppColors.darkGreen,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _PageBackground extends StatelessWidget {
  const _PageBackground({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const ValueKey('detailsBackground'),
    color: const Color(0xFFFFFCF9),
    child: child,
  );
}

class _PlanHero extends StatelessWidget {
  const _PlanHero({required this.plan});
  final MealPlanOption plan;
  @override
  Widget build(BuildContext context) {
    final arabic = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      key: const ValueKey('planHero'),
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF0DF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    arabic ? 'الخطوة 1 من 2' : 'Step 1 of 2',
                    style: const TextStyle(
                      fontSize: 9,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  arabic ? 'اختر خطتك' : 'Choose Your Plan',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.1,
                    letterSpacing: -.7,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  arabic
                      ? 'اختر وجباتك اليومية ومدة اشتراكك.'
                      : 'Select your daily meal option and subscription duration.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.25,
                    color: Color(0xFF7D827C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            height: 104,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                PositionedDirectional(
                  end: -18,
                  top: 6,
                  bottom: -4,
                  width: 94,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFE7F0E2),
                      borderRadius: BorderRadiusDirectional.only(
                        topStart: Radius.circular(50),
                        bottomStart: Radius.circular(60),
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: -17,
                  top: 37,
                  child: Transform.rotate(
                    angle: -.6,
                    child: const Icon(
                      Icons.eco,
                      color: Color(0xFF73AC80),
                      size: 27,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.darkGreen.withValues(alpha: .18),
                            blurRadius: 9,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _HeroImage(imageUrl: plan.imageUrl),
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

class _HeroImage extends StatelessWidget {
  const _HeroImage({this.imageUrl});
  final String? imageUrl;
  @override
  Widget build(BuildContext context) {
    final url = _resolveImageUrl(imageUrl);
    return ClipOval(
      key: const ValueKey('heroImageClip'),
      child: url.isEmpty
          ? const _MealImagePlaceholder()
          : Image.network(
              url,
              key: const ValueKey('heroImage'),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              frameBuilder: (_, child, frame, _) =>
                  frame == null ? const _MealImagePlaceholder() : child,
              errorBuilder: (_, _, _) => const _MealImagePlaceholder(),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.titleEn,
    required this.titleAr,
    required this.icon,
  });
  final String titleEn;
  final String titleAr;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 23,
        height: 23,
        decoration: BoxDecoration(
          color: const Color(0xFFEDF6EE),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, size: 18, color: AppColors.emeraldGreen),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          Directionality.of(context) == TextDirection.rtl ? titleAr : titleEn,
          style: const TextStyle(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: AppColors.darkGreen,
          ),
        ),
      ),
    ],
  );
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.plan});
  final MealPlanOption plan;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _PlanHero(plan: plan),
      const SizedBox(height: 20),
      for (var section = 0; section < 2; section++) ...[
        const _Skeleton(width: 160, height: 18),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var card = 0; card < 3; card++) ...[
                if (card > 0) const SizedBox(width: 10),
                _Skeleton(width: section == 0 ? 180 : 112, height: 112),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    ],
  );
}

class _PricingError extends StatelessWidget {
  const _PricingError({required this.plan, required this.onRetry});
  final MealPlanOption plan;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _PlanHero(plan: plan),
      const SizedBox(height: 28),
      const Icon(
        Icons.cloud_off_outlined,
        size: 38,
        color: AppColors.emeraldGreen,
      ),
      const SizedBox(height: 10),
      Text(
        Directionality.of(context) == TextDirection.rtl
            ? 'الأسعار غير متاحة مؤقتاً.'
            : context.customerCopy('Pricing is temporarily unavailable.'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: TextButton(
          key: const ValueKey('retryPricing'),
          onPressed: onRetry,
          child: Text(
            Directionality.of(context) == TextDirection.rtl
                ? 'إعادة المحاولة'
                : context.customerCopy('Retry'),
          ),
        ),
      ),
    ],
  );
}

class _EmptyPackages extends StatelessWidget {
  const _EmptyPackages({required this.plan});
  final MealPlanOption plan;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _PlanHero(plan: plan),
      const SizedBox(height: 28),
      const Icon(
        Icons.restaurant_menu_rounded,
        color: AppColors.emeraldGreen,
        size: 36,
      ),
      const SizedBox(height: 12),
      Text(
        Directionality.of(context) == TextDirection.rtl
            ? 'لا توجد باقات متاحة حالياً لخطة الوجبات هذه.'
            : context.customerCopy(
                'No packages are currently available for this meal plan.',
              ),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        Directionality.of(context) == TextDirection.rtl
            ? 'جرّب خطة أخرى للعثور على وجبات تناسبك.'
            : context.customerCopy(
                'Try another plan to find your daily meal routine.',
              ),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.darkGreen.withValues(alpha: .7),
          height: 1.5,
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: OutlinedButton(
          key: const ValueKey('chooseAnotherPlan'),
          onPressed: () => context.pop(),
          child: Text(
            Directionality.of(context) == TextDirection.rtl
                ? 'اختر خطة أخرى'
                : context.customerCopy('Choose another plan'),
          ),
        ),
      ),
    ],
  );
}

class _MealImagePlaceholder extends StatelessWidget {
  const _MealImagePlaceholder();
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/onboarding_1.png',
    fit: BoxFit.cover,
    alignment: const Alignment(0, -.1),
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.width, required this.height});
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.darkGreen.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
}

String _serviceDaysLabel(BuildContext context, int days) =>
    Directionality.of(context) == TextDirection.rtl
    ? '$days أيام خدمة'
    : '$days service days';

String _amount(BuildContext context, double value) => formatMealPlanPriceAmount(
  value,
  Localizations.localeOf(context).toLanguageTag(),
);

String _resolveImageUrl(String? value) => resolvePlanImageUrl(value);
