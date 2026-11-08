import 'package:diet_time/app/localization/customer_copy.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';

import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

Duration selectionAnimationDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 180);

/// Dimensions depend on viewport and accessibility settings, never on selection.
abstract final class SubscriptionCardLayout {
  static double titleHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(15) * 1.25 * 2;
  static double subtitleHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(12) * 1.35 * 2;
  static double priceHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(19) * 1.25;
  static double discountHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(12) * 1.3 + 8;
  static double footerHeight(BuildContext context) =>
      8 + priceHeight(context) + 4 + discountHeight(context);
  static double height(BuildContext context) =>
      27 +
      titleHeight(context) +
      5 +
      subtitleHeight(context) +
      footerHeight(context);
  static double width(BuildContext context, double available) {
    final scale = (MediaQuery.textScalerOf(context).scale(15) / 15).clamp(
      1.0,
      1.25,
    );
    return ((available - 10) / 2)
        .clamp(180.0 * scale, 240.0 * scale)
        .clamp(0.0, available);
  }
}

class SubscriptionSelectionRow extends StatelessWidget {
  const SubscriptionSelectionRow({required this.builder, super.key});
  final List<Widget> Function(double width) builder;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: builder(
          SubscriptionCardLayout.width(context, constraints.maxWidth),
        ),
      ),
    ),
  );
}

/// Equal slots keep labels, prices and indicators aligned across every option.
class SubscriptionSelectionCard extends StatelessWidget {
  const SubscriptionSelectionCard({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.footer,
    this.width = 180,
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
      height: SubscriptionCardLayout.height(context),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: SubscriptionCardLayout.titleHeight(context),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 15,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        selected ? Icons.check_circle : Icons.circle_outlined,
                        size: 17,
                        color: selected
                            ? AppColors.emeraldGreen
                            : const Color(0xFF9CAA99),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: SubscriptionCardLayout.subtitleHeight(context),
                  width: double.infinity,
                  child: Text(
                    subtitle ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.darkGreen.withValues(alpha: .7),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
                SizedBox(
                  height: SubscriptionCardLayout.footerHeight(context),
                  width: double.infinity,
                  child: footer,
                ),
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
    this.width = 180,
    super.key,
  });
  final String name;
  final String? description;
  final MealPlanPackage? package;
  final double width;
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
    width: width,
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
                            arabic
                                ? 'اشتراكك'
                                : context.customerCopy('Your subscription'),
                            style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height:
                                MediaQuery.textScalerOf(context).scale(12) *
                                1.35 *
                                3,
                            child: Text(
                              selection,
                              key: const ValueKey('summaryServiceDays'),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.darkGreen.withValues(
                                  alpha: .7,
                                ),
                                fontSize: 12,
                                height: 1.35,
                              ),
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
                                  SizedBox(
                                    height:
                                        MediaQuery.textScalerOf(
                                          context,
                                        ).scale(28) *
                                        1.15,
                                    width: double.infinity,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Text(
                                        total,
                                        key: const ValueKey('packageTotal'),
                                        maxLines: 1,
                                        style: const TextStyle(
                                          color: AppColors.darkGreen,
                                          fontSize: 28,
                                          height: 1.15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        SubscriptionCardLayout.discountHeight(
                                              context,
                                            ) *
                                            2 +
                                        14,
                                    width: double.infinity,
                                    child: discountDetails == null
                                        ? null
                                        : Align(
                                            alignment:
                                                AlignmentDirectional.topStart,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment:
                                                  AlignmentDirectional.topStart,
                                              child: discountDetails!,
                                            ),
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
                      label: arabic
                          ? 'متابعة ←'
                          : context.customerCopy('Continue →'),
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
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final arabic = Directionality.of(context) == TextDirection.rtl;
    String amount(double value) => formatMealPlanPriceAmount(value, locale);
    Widget fitted(Widget child) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: child,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: SubscriptionCardLayout.priceHeight(context),
            child: fitted(
              Text(
                '${package.currencyCode} ${amount(package.totalPrice)}',
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 19,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: SubscriptionCardLayout.discountHeight(context),
            child: package.hasDiscount
                ? Row(
                    children: [
                      Expanded(
                        child: fitted(
                          Text(
                            '${package.currencyCode} ${amount(package.originalPrice)}',
                            maxLines: 1,
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 12,
                              height: 1.3,
                              color: AppColors.darkGreen.withValues(alpha: .65),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerEnd,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDF1E3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                arabic
                                    ? 'خصم ${amount(package.discountPercentage.roundToDouble())}٪'
                                    : '${amount(package.discountPercentage.roundToDouble())}% OFF',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
