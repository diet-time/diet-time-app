import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:flutter/material.dart';

class PackageDiscountDetails extends StatelessWidget {
  const PackageDiscountDetails({
    super.key,
    required this.package,
    this.showEffectivePrice = false,
  });
  final MealPlanPackage package;
  final bool showEffectivePrice;

  @override
  Widget build(BuildContext context) {
    if (!package.hasDiscount) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final arabic =
        Localizations.localeOf(context).languageCode == 'ar' ||
        Directionality.of(context) == TextDirection.rtl;
    String amount(double value) => formatMealPlanPriceAmount(value, locale);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showEffectivePrice)
            Text(
              '${package.currencyCode} ${amount(package.totalPrice)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.darkGreen,
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${package.currencyCode} ${amount(package.originalPrice)}',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  fontSize: 12,
                  color: AppColors.darkGreen.withValues(alpha: .65),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF1E3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  arabic
                      ? 'خصم ${amount(package.discountPercentage.roundToDouble())}٪'
                      : '${amount(package.discountPercentage.roundToDouble())}% OFF',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
            ],
          ),
          Text(
            arabic
                ? 'توفر ${package.currencyCode} ${amount(package.discountAmount)}'
                : 'You save ${package.currencyCode} ${amount(package.discountAmount)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.emeraldGreen,
            ),
          ),
        ],
      ),
    );
  }
}
