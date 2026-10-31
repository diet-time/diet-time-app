import 'package:diet_time/app/localization/customer_copy.dart';
import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/features/plans/presentation/package_discount_details.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/meal_plan_image.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:diet_time/features/plans/presentation/subscription_selection_widgets.dart';
import 'package:flutter/material.dart';
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

class _MealPlanDetailsScreenState extends ConsumerState<MealPlanDetailsScreen> {
  String? _configurationId;
  String? _priceId;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final request = (plan: widget.plan, language: language);
    final configurations = ref.watch(mealPlanConfigurationsProvider(request));
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
    final profile = ref.watch(personalizationControllerProvider);
    final hasRecordedAllergens =
        profile.allergensConfirmed &&
        profile.allergens.any(
          (value) => value.toUpperCase() != 'NONE' && value.isNotEmpty,
        );
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PlanHero(plan: widget.plan),
                    const SizedBox(height: 16),
                    _SectionTitle(
                      titleEn: context.customerCopy('Choose your meals'),
                      titleAr: 'اختر وجباتك اليومية',
                      subtitleEn: context.customerCopy(
                        "Pick how many meals you'd like each day.",
                      ),
                      subtitleAr: 'اختر مجموعة الوجبات التي تناسبك.',
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      key: const ValueKey('mealConfigurations'),
                      scrollDirection: Axis.horizontal,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final item in configurations) ...[
                              if (item != configurations.first)
                                const SizedBox(width: 10),
                              PackageSelectionCard(
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
                                              p.serviceDays ==
                                                  package.serviceDays,
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
                      ),
                    ),
                    if (configurations.length > 1)
                      Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          context.customerCopy(
                            'Swipe to explore meal packages →',
                          ),
                          style: TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _SectionTitle(
                      titleEn: context.customerCopy('Choose your duration'),
                      titleAr: 'اختر المدة',
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final count = configuration.packages.length;
                        final scale = MediaQuery.textScalerOf(context).scale(1);
                        final fit =
                            count <= 3 &&
                            constraints.maxWidth / count >= 104 * scale;
                        final width = fit
                            ? ((constraints.maxWidth - (count - 1) * 10) /
                                      count)
                                  .clamp(104.0, 180.0)
                            : 146.0 * scale.clamp(1, 1.5);
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: IntrinsicHeight(
                            child: Row(
                              key: const ValueKey('packageDurations'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final option
                                    in configuration.packages) ...[
                                  if (option != configuration.packages.first)
                                    const SizedBox(width: 10),
                                  DurationSelectionCard(
                                    key: ValueKey(
                                      'duration-${option.selectionKey}',
                                    ),
                                    name: option.name,
                                    priceDetails: option.isValid
                                        ? PackageCardPrice(package: option)
                                        : null,
                                    deliveryDays: option.isValid
                                        ? _serviceDaysLabel(
                                            context,
                                            option.serviceDays,
                                          )
                                        : Directionality.of(context) ==
                                              TextDirection.rtl
                                        ? 'غير متاح حالياً'
                                        : context.customerCopy(
                                            'Currently unavailable',
                                          ),
                                    selected:
                                        option.isValid &&
                                        option.selectionKey ==
                                            package.selectionKey,
                                    width: width,
                                    onTap: option.isValid
                                        ? () => setState(
                                            () =>
                                                _priceId = option.selectionKey,
                                          )
                                        : null,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      Directionality.of(context) == TextDirection.rtl
                          ? 'المدد المتاحة لباقة الوجبات المختارة.'
                          : context.customerCopy(
                              'Swipe to explore package durations →',
                            ),
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(alpha: .7),
                        fontSize: 12,
                      ),
                    ),
                    if (hasRecordedAllergens) ...[
                      const SizedBox(height: 14),
                      const _AllergenInformation(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        SubscriptionPricingSummary(
          discountDetails: package.hasDiscount
              ? PackageDiscountDetails(package: package)
              : null,
          selection:
              '${configuration.displayName(Localizations.localeOf(context).languageCode)} · ${package.name} · ${_serviceDaysLabel(context, package.serviceDays)}',
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
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        key: const ValueKey('detailsBack'),
        onPressed: () => context.pop(),
        icon: Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.arrow_forward_rounded
              : Icons.arrow_back_rounded,
        ),
      ),
      title: Text(
        context.customerCopy('Diet Time'),
        style: TextStyle(
          color: AppColors.darkGreen,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PageBackground extends StatelessWidget {
  const _PageBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('detailsBackground'),
      color: const Color(0xFFF5F3E9),
      child: child,
    );
  }
}

class _PlanHero extends StatelessWidget {
  const _PlanHero({required this.plan});

  final MealPlanOption plan;

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return Container(
      key: const ValueKey('planHero'),
      constraints: const BoxConstraints(minHeight: 180),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7EF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.emeraldGreen.withValues(alpha: .55),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _HeroImage(imageUrl: plan.imageUrl)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: const [
                    Color(0xFFF7F8EE),
                    Color(0xE8F0F5E9),
                    Color(0x73F0F5E9),
                  ],
                  stops: const [0, .52, 1],
                ),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? .88
                  : .70,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 15, 10, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    if (plan.description case final description?) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.darkGreen.withValues(alpha: .68),
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (plan.dailyCaloriesKcal case final calories?)
                      _HeroFact(
                        key: const ValueKey('heroCalories'),
                        icon: Icons.local_fire_department_outlined,
                        label: isArabic
                            ? 'تقريباً ${calories.round()} سعرة / يوم'
                            : 'Approx. ${calories.round()} kcal/day',
                      ),
                  ],
                ),
              ),
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
    return ClipRRect(
      key: const ValueKey('heroImageClip'),
      borderRadius: BorderRadius.circular(21),
      child: SizedBox.expand(
        child: url.isEmpty
            ? const _MealImagePlaceholder()
            : Image.network(
                url,
                key: const ValueKey('heroImage'),
                fit: BoxFit.cover,
                alignment: AlignmentDirectional.centerEnd,
                frameBuilder: (context, child, frame, _) => AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: selectionAnimationDuration(context),
                  child: frame == null ? const _ImageSkeleton() : child,
                ),
                errorBuilder: (_, _, _) => const _MealImagePlaceholder(),
              ),
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.icon, required this.label, super.key});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: AppColors.emeraldGreen),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.emeraldGreen,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.titleEn,
    required this.titleAr,
    this.subtitleEn,
    this.subtitleAr,
  });
  final String titleEn;
  final String titleAr;
  final String? subtitleEn;
  final String? subtitleAr;

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final subtitle = isArabic ? subtitleAr : subtitleEn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? titleAr : titleEn,
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.darkGreen.withValues(alpha: .62),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _AllergenInformation extends StatelessWidget {
  const _AllergenInformation();
  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return Container(
      key: const ValueKey('allergenInformation'),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6EC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.emeraldGreen),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'تم حفظ تفضيلات مسببات الحساسية لديك'
                      : context.customerCopy(
                          'Your allergen preferences are saved',
                        ),
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'سنستخدم معلومات الحساسية المسجلة عند عرض الوجبات المناسبة. راجع تفاصيل مسببات الحساسية لكل وجبة قبل الطلب.'
                      : context.customerCopy(
                          'We’ll use your recorded allergen information when showing suitable meal choices. Please review each meal’s allergen details before ordering.',
                        ),
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .66),
                    fontSize: 12,
                    height: 1.35,
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

class _ImageSkeleton extends StatelessWidget {
  const _ImageSkeleton();
  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: Color(0xFFDDEBDD));
}

class _MealImagePlaceholder extends StatelessWidget {
  const _MealImagePlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFDDEBDD),
    child: Center(
      child: Icon(
        Icons.restaurant_rounded,
        size: 42,
        color: AppColors.emeraldGreen,
      ),
    ),
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
