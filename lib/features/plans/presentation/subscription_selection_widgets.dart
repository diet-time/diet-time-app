import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/presentation/package_discount_details.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

Duration selectionAnimationDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 180);

/// A compact, content-sized option shared by the meal and duration selectors.
class SubscriptionSelectionCard extends StatelessWidget {
  const SubscriptionSelectionCard({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.footer,
    this.width = 176,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? footer;
  final bool selected;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    enabled: onTap != null,
    child: AnimatedContainer(
      duration: selectionAnimationDuration(context),
      width: width,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE6F2E9) : const Color(0xFFFFFEFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? AppColors.emeraldGreen
              : AppColors.darkGreen.withValues(alpha: .13),
          width: 1.5,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: selected
                      ? AppColors.emeraldGreen
                      : AppColors.darkGreen.withValues(alpha: .25),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle?.isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppColors.darkGreen.withValues(alpha: .7),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                ?footer,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class PackageSelectionCard extends StatelessWidget {
  const PackageSelectionCard({
    required this.name,
    required this.selected,
    required this.onTap,
    this.description,
    this.package,
    super.key,
  });
  final String name;
  final String? description;
  final MealPlanPackage? package;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SubscriptionSelectionCard(
    title: name,
    subtitle: package == null
        ? description
        : '${package!.serviceDays} service days',
    footer: package == null ? null : PackageCardPrice(package: package!),
    selected: selected,
    onTap: onTap,
    width: 180,
  );
}

class DurationSelectionCard extends StatelessWidget {
  const DurationSelectionCard({
    required this.name,
    required this.deliveryDays,
    required this.selected,
    required this.onTap,
    required this.width,
    this.priceDetails,
    super.key,
  });
  final String name;
  final String deliveryDays;
  final Widget? priceDetails;
  final bool selected;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) => SubscriptionSelectionCard(
    title: name,
    subtitle: deliveryDays,
    footer: priceDetails,
    selected: selected,
    onTap: onTap,
    width: width,
  );
}

class SubscriptionPricingSummary extends StatelessWidget {
  const SubscriptionPricingSummary({
    required this.selection,
    required this.total,
    required this.priceKey,
    required this.onContinue,
    this.discountDetails,
    super.key,
  });
  final String selection;
  final String total;
  final String priceKey;
  final Widget? discountDetails;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final arabic = Directionality.of(context) == TextDirection.rtl;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .52,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: .07),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            arabic ? 'اشتراكك' : 'Your subscription',
                            style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selection,
                            key: const ValueKey('summaryServiceDays'),
                            style: TextStyle(
                              color: AppColors.darkGreen.withValues(alpha: .7),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Fade the current value only; never retain a stale selling price.
                          TweenAnimationBuilder<double>(
                            key: ValueKey(priceKey),
                            tween: Tween(begin: .65, end: 1),
                            duration: selectionAnimationDuration(context),
                            builder: (context, opacity, child) =>
                                Opacity(opacity: opacity, child: child),
                            child: Semantics(
                              liveRegion: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    total,
                                    key: const ValueKey('packageTotal'),
                                    style: const TextStyle(
                                      color: AppColors.darkGreen,
                                      fontSize: 28,
                                      height: 1.15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  ?discountDetails,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: onContinue == null
                            ? const [Color(0xFF899C93), Color(0xFF778A80)]
                            : const [
                                AppColors.emeraldGreen,
                                AppColors.darkGreen,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AppButton(
                      key: const ValueKey('detailsContinue'),
                      label: arabic ? 'متابعة ←' : 'Continue →',
                      backgroundColor: Colors.transparent,
                      onPressed: onContinue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PackageCardPrice extends StatelessWidget {
  const PackageCardPrice({required this.package, super.key});
  final MealPlanPackage package;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '${package.currencyCode} ${formatMealPlanPriceAmount(package.totalPrice, Localizations.localeOf(context).toLanguageTag())}',
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (package.hasDiscount)
          PackageDiscountDetails(package: package, showSavings: false),
      ],
    ),
  );
}
