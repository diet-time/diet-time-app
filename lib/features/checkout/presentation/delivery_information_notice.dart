import 'package:diet_time/app/localization/customer_copy.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class DeliveryInformationNotice extends StatelessWidget {
  const DeliveryInformationNotice({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('deliveryInformationNotice'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.emeraldGreen.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: AppColors.emeraldGreen,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.customerCopy('Delivery Information'),
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.customerCopy(
                  'Delivery charges may apply based on your location and distance. Any applicable charges will be communicated before payment.',
                ),
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
