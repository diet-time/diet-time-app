import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    ref.watch(otpAuthControllerProvider);
    final language = Localizations.localeOf(context).languageCode;
    final request = (plan: widget.plan, language: language);
    final configurations = ref.watch(mealPlanConfigurationsProvider(request));
    return _PageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const _DetailsHeader(),
        body: configurations.when(
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
                    _PlanHero(
                      plan: widget.plan,
                      startingPrice: _heroPrice(configurations),
                    ),
                    const SizedBox(height: 16),
                    const _SectionTitle(
                      titleEn: 'Choose your daily meals',
                      titleAr: 'اختر وجباتك اليومية',
                      subtitleEn:
                          'Select the meal combination that works for you.',
                      subtitleAr: 'اختر مجموعة الوجبات التي تناسبك.',
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 94,
                      child: ListView.separated(
                        key: const ValueKey('mealConfigurations'),
                        scrollDirection: Axis.horizontal,
                        itemCount: configurations.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final item = configurations[index];
                          return _ChoiceCard(
                            key: ValueKey('configuration-${item.id}'),
                            title: item.name,
                            subtitle: item.description,
                            selected: item.id == configuration.id,
                            onTap: () => setState(() {
                              _configurationId = item.id;
                              final keepsDuration = item.packages.any(
                                (candidate) =>
                                    candidate.selectionKey == _priceId,
                              );
                              if (!keepsDuration) {
                                _priceId = item.packages.first.selectionKey;
                              }
                            }),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SectionTitle(
                      titleEn: 'Choose duration',
                      titleAr: 'اختر المدة',
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        key: const ValueKey('packageDurations'),
                        children: [
                          for (
                            var index = 0;
                            index < configuration.packages.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(width: 10),
                            _ChoiceCard(
                              key: ValueKey(
                                'duration-${configuration.packages[index].selectionKey}',
                              ),
                              title: configuration.packages[index].name,
                              subtitle: _serviceDaysLabel(
                                context,
                                configuration.packages[index].serviceDays,
                              ),
                              selected:
                                  configuration.packages[index].selectionKey ==
                                  package.selectionKey,
                              compact: true,
                              onTap: () => setState(
                                () => _priceId =
                                    configuration.packages[index].selectionKey,
                              ),
                            ),
                          ],
                        ],
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
        _BottomAction(
          configuration: configuration,
          package: package,
          onContinue: () => _continue(package.mealPlanPriceId),
        ),
      ],
    );
  }

  Future<void> _continue(String mealPlanPriceId) async {
    widget.onContinue?.call(widget.plan.id, mealPlanPriceId);
    if (widget.onContinue != null) return;
    final authenticated = await ref
        .read(otpAuthControllerProvider.notifier)
        .restoreSession();
    if (!mounted) return;
    final destination = PendingAuthDestination(
      route: AppRoutes.home,
      planCode: widget.plan.code,
      planName: widget.plan.name,
      mealPlanTemplateId: widget.plan.id,
      mealPlanPriceId: mealPlanPriceId,
    );
    if (authenticated) {
      ref.read(otpAuthControllerProvider.notifier).begin(destination);
      context.go(AppRoutes.home);
    } else {
      context.push(AppRoutes.phoneLogin, extra: destination);
    }
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
      title: const Text(
        'Diet Time',
        style: TextStyle(
          color: AppColors.darkGreen,
          fontSize: 20,
          fontWeight: FontWeight.w900,
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
  const _PlanHero({required this.plan, this.startingPrice});

  final MealPlanOption plan;
  final MealPlanPackage? startingPrice;

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return Container(
      key: const ValueKey('planHero'),
      height: 190,
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
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 0,
            width: 205,
            child: _HeroImage(imageUrl: plan.imageUrl),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: const [
                    Color(0xFFF7F8EE),
                    Color(0xF2F0F5E9),
                    Color(0x1AF0F5E9),
                  ],
                  stops: const [0, .56, 1],
                ),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: .68,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 15, 10, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
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
                    const Spacer(),
                    if (plan.dailyCaloriesKcal case final calories?)
                      _HeroFact(
                        key: const ValueKey('heroCalories'),
                        icon: Icons.local_fire_department_outlined,
                        label: isArabic
                            ? 'تقريباً ${calories.round()} سعرة / يوم'
                            : 'Approx. ${calories.round()} kcal/day',
                      ),
                    if (startingPrice case final price?) ...[
                      const SizedBox(height: 5),
                      _HeroFact(
                        icon: Icons.payments_outlined,
                        label: isArabic
                            ? 'ابتداءً من ${price.currencyCode} ${_amount(context, price.dailyPrice)} / يوم'
                            : 'From ${price.currencyCode} ${_amount(context, price.dailyPrice)}/day',
                      ),
                    ],
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
                fit: BoxFit.contain,
                frameBuilder: (context, child, frame, _) => AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 240),
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
            fontWeight: FontWeight.w900,
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

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.compact = false,
    super.key,
  });
  final String title;
  final String? subtitle;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: BoxConstraints(
        minWidth: compact ? 116 : 270,
        maxWidth: compact ? 160 : 320,
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 12, 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE7F4E8) : AppColors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected
              ? AppColors.emeraldGreen
              : AppColors.darkGreen.withValues(alpha: .12),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selected) ...[
            const Icon(
              Icons.check_circle_rounded,
              size: 17,
              color: AppColors.emeraldGreen,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle case final value?) ...[
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.darkGreen.withValues(alpha: .58),
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Kept temporarily for compatibility with older golden-test branches.
// ignore: unused_element
class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.configuration, required this.package});
  final MealPlanConfiguration configuration;
  final MealPlanPackage package;

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return Container(
      key: const ValueKey('priceSummary'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.teaGreen.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'خطتك' : 'Your plan',
            style: TextStyle(
              color: AppColors.darkGreen.withValues(alpha: .58),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            configuration.name,
            key: const ValueKey('summaryConfiguration'),
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${package.name} · ${_serviceDaysLabel(context, package.serviceDays)}',
            key: const ValueKey('summaryServiceDays'),
            style: TextStyle(color: AppColors.darkGreen.withValues(alpha: .62)),
          ),
          const SizedBox(height: 20),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '${package.currencyCode} ${_amount(context, package.dailyPrice)} / ${isArabic ? 'يوم' : 'day'}',
              key: const ValueKey('dailyPrice'),
              style: const TextStyle(
                color: AppColors.emeraldGreen,
                fontSize: 29,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Divider(height: 30),
          Row(
            children: [
              Text(
                isArabic ? 'الإجمالي' : 'Total',
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '${package.currencyCode} ${_amount(context, package.totalPrice)}',
                  key: const ValueKey('packageTotal'),
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
                      : 'Your allergen preferences are saved',
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'سنستخدم معلومات الحساسية المسجلة عند عرض الوجبات المناسبة. راجع تفاصيل مسببات الحساسية لكل وجبة قبل الطلب.'
                      : 'We’ll use your recorded allergen information when showing suitable meal choices. Please review each meal’s allergen details before ordering.',
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

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.configuration,
    required this.package,
    required this.onContinue,
  });
  final MealPlanConfiguration configuration;
  final MealPlanPackage package;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
        color: const Color(0xE6F5F3E9),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${package.currencyCode} ${_amount(context, package.dailyPrice)} / ${isArabic ? 'يوم' : 'day'}',
                        key: const ValueKey('dailyPrice'),
                        style: const TextStyle(
                          color: AppColors.emeraldGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${package.currencyCode} ${_amount(context, package.totalPrice)}',
                        key: const ValueKey('packageTotal'),
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${package.name} · ${_serviceDaysLabel(context, package.serviceDays)} · ${configuration.name}',
                  key: const ValueKey('summaryServiceDays'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .58),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                AppButton(
                  key: const ValueKey('detailsContinue'),
                  label: isArabic ? 'متابعة ←' : 'Continue →',
                  onPressed: package.mealPlanPriceId.isEmpty
                      ? null
                      : onContinue,
                ),
              ],
            ),
          ),
        ),
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
      const SizedBox(height: 26),
      for (final width in [190.0, 340.0, 280.0, 360.0]) ...[
        _Skeleton(width: width, height: width == 360 ? 150 : 56),
        const SizedBox(height: 16),
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
            : 'Pricing is temporarily unavailable.',
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
                : 'Retry',
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
      Text(
        Directionality.of(context) == TextDirection.rtl
            ? 'لا توجد باقات متاحة حالياً لخطة الوجبات هذه.'
            : 'No packages are currently available for this meal plan.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 10),
      Center(
        child: OutlinedButton(
          key: const ValueKey('chooseAnotherPlan'),
          onPressed: () => context.pop(),
          child: Text(
            Directionality.of(context) == TextDirection.rtl
                ? 'اختر خطة أخرى'
                : 'Choose another plan',
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

MealPlanPackage? _heroPrice(List<MealPlanConfiguration> configurations) {
  final packages = [for (final item in configurations) ...item.packages];
  if (packages.isEmpty) return null;
  for (final package in packages) {
    if (package.serviceDays == 1) return package;
  }
  return packages.first;
}

String _serviceDaysLabel(BuildContext context, int days) =>
    Directionality.of(context) == TextDirection.rtl
    ? '$days أيام خدمة'
    : '$days service days';

String _amount(BuildContext context, double value) => formatMealPlanPriceAmount(
  value,
  Localizations.localeOf(context).toLanguageTag(),
);

String _resolveImageUrl(String? value) {
  final candidate = value?.trim() ?? '';
  if (candidate.isEmpty) return '';
  final parsed = Uri.tryParse(candidate);
  if (parsed != null && parsed.hasScheme) return candidate;
  return Uri.parse(AppEnvironment.apiBaseUrl).resolve(candidate).toString();
}
