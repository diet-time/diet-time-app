import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:flutter/material.dart';

Duration selectionAnimationDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 180);
bool _arabic(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl;

/// Viewport and text scale determine dimensions; selections never do.
abstract final class SubscriptionCardLayout {
  static double titleHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(12) * 1.1 * 2;
  static double subtitleHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(10) * 1.1;
  static double priceHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(17) * 1.15;
  static double discountHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(9) * 1.1 + 4;
  static double footerHeight(BuildContext context) =>
      2 + priceHeight(context) + 1 + discountHeight(context);
  static double height(BuildContext context, {bool meal = false}) =>
      20 +
      (meal ? 15 : 0) +
      titleHeight(context) +
      subtitleHeight(context) +
      footerHeight(context);
  static double width(BuildContext context, double available) {
    final scale = (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(
      1.0,
      1.4,
    );
    return ((available - 10) / 2)
        .clamp(132.0 * scale, 335.0)
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

class SubscriptionSelectionCard extends StatelessWidget {
  const SubscriptionSelectionCard({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.footer,
    this.width = 180,
    this.meal = false,
    super.key,
  });
  final String title;
  final String? subtitle;
  final Widget? footer;
  final bool selected;
  final VoidCallback? onTap;
  final double width;
  final bool meal;
  @override
  Widget build(BuildContext context) {
    final indicator = Icon(
      selected ? Icons.check_circle : Icons.circle_outlined,
      size: 15,
      color: selected ? AppColors.emeraldGreen : const Color(0xFFAAB1AE),
    );
    final titleText = Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.darkGreen,
        fontSize: 12,
        height: 1.1,
        fontWeight: FontWeight.w800,
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      enabled: onTap != null,
      child: AnimatedContainer(
        duration: selectionAnimationDuration(context),
        width: width,
        height: SubscriptionCardLayout.height(context, meal: meal),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEDF7F1) : const Color(0xFFFFFEFE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.emeraldGreen : const Color(0xFFE1E4E1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGreen.withValues(alpha: .045),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (meal)
                    SizedBox(
                      height: 15,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.room_service_outlined,
                            size: 20,
                            color: AppColors.emeraldGreen,
                          ),
                          const Spacer(),
                          indicator,
                        ],
                      ),
                    ),
                  SizedBox(
                    height: SubscriptionCardLayout.titleHeight(context),
                    child: meal
                        ? Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: titleText,
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsetsDirectional.only(end: 6),
                                child: Icon(
                                  Icons.calendar_month_outlined,
                                  size: 17,
                                  color: AppColors.emeraldGreen,
                                ),
                              ),
                              Expanded(child: titleText),
                              const SizedBox(width: 3),
                              indicator,
                            ],
                          ),
                  ),
                  SizedBox(
                    height: SubscriptionCardLayout.subtitleHeight(context),
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: meal ? 0 : 23),
                      child: Text(
                        subtitle ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF727F77),
                          fontSize: 10,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: SubscriptionCardLayout.footerHeight(context),
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
    meal: true,
    subtitle: _arabic(context) ? 'يومياً' : 'per day',
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
    required this.meals,
    required this.duration,
    required this.total,
    required this.priceKey,
    required this.onContinue,
    required this.package,
    super.key,
  });
  final String meals;
  final String duration;
  final String total;
  final String priceKey;
  final MealPlanPackage package;
  final VoidCallback? onContinue;
  @override
  Widget build(BuildContext context) {
    final arabic = _arabic(context);
    final scaler = MediaQuery.textScalerOf(context);
    final summaryHeight =
        32 + scaler.scale(13) * 1.2 + scaler.scale(9) * 1.25 * 4;
    String amount(double value) => formatMealPlanPriceAmount(
      value,
      Localizations.localeOf(context).toLanguageTag(),
    );
    Widget line(IconData icon, String value, {Key? key}) => SizedBox(
      height: scaler.scale(9) * 1.25 * 2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: AppColors.emeraldGreen),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              key: key,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                height: 1.25,
                color: Color(0xFF586D61),
              ),
            ),
          ),
        ],
      ),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: summaryHeight,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF7F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 11,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              arabic ? 'اشتراكك' : 'Your Subscription',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            line(
                              Icons.room_service_outlined,
                              '$meals ${arabic ? '(يومياً)' : '(per day)'}',
                            ),
                            line(
                              Icons.calendar_month_outlined,
                              duration,
                              key: const ValueKey('summaryServiceDays'),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(
                        width: 20,
                        thickness: 1,
                        color: Color(0xFFD4E8DB),
                      ),
                      Expanded(
                        flex: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              arabic ? 'الإجمالي' : 'Total',
                              style: const TextStyle(
                                fontSize: 10,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkGreen,
                              ),
                            ),
                            const SizedBox(height: 3),
                            SizedBox(
                              height: scaler.scale(22) * 1.15,
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey(priceKey),
                                tween: Tween(begin: .65, end: 1),
                                duration: selectionAnimationDuration(context),
                                builder: (_, opacity, child) =>
                                    Opacity(opacity: opacity, child: child),
                                child: Semantics(
                                  liveRegion: true,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      total,
                                      key: const ValueKey('packageTotal'),
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        height: 1.15,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.darkGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Expanded(
                              child: package.hasDiscount
                                  ? FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Row(
                                        children: [
                                          Text(
                                            '${package.currencyCode} ${amount(package.originalPrice)}',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Color(0xFF849086),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD4EED7),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              arabic
                                                  ? 'توفر ${package.currencyCode} ${amount(package.discountAmount)}'
                                                  : 'You save ${package.currencyCode} ${amount(package.discountAmount)}',
                                              style: const TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.darkGreen,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: onContinue == null
                          ? const [Color(0xFF899C93), Color(0xFF778A80)]
                          : const [AppColors.emeraldGreen, AppColors.darkGreen],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkGreen.withValues(alpha: .2),
                        blurRadius: 9,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    key: const ValueKey('detailsContinue'),
                    height: 44 + (scaler.scale(14) - 14).clamp(0, 20),
                    child: FilledButton(
                      onPressed: onContinue,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            arabic ? 'متابعة' : 'Continue',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            arabic
                                ? Icons.arrow_back_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
    String amount(double value) => formatMealPlanPriceAmount(
      value,
      Localizations.localeOf(context).toLanguageTag(),
    );
    Widget fitted(Widget child) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: child,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 2),
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
                  fontSize: 17,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),
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
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 9,
                              color: Color(0xFF839087),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDF1E3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _arabic(context)
                                    ? 'خصم ${amount(package.discountPercentage.roundToDouble())}٪'
                                    : '${amount(package.discountPercentage.roundToDouble())}% OFF',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 9,
                                  height: 1.1,
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
