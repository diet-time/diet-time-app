import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PlanSummaryScreen extends ConsumerStatefulWidget {
  const PlanSummaryScreen({super.key});

  @override
  ConsumerState<PlanSummaryScreen> createState() => _PlanSummaryScreenState();
}

class _PlanSummaryScreenState extends ConsumerState<PlanSummaryScreen> {
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () =>
          ref.read(checkoutControllerProvider.notifier).loadDeliveryTimeSlots(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutControllerProvider);
    final selection = checkout.selection;
    final schedule = checkout.schedule;
    if (selection == null || schedule == null) {
      return _MissingCheckout(onBack: () => context.go(AppRoutes.plans));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const ValueKey('planSummaryBack'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Your Plan Details',
          style: TextStyle(
            color: AppColors.darkGreen,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PlanSummaryCard(
                        checkout: checkout,
                        locale: Localizations.localeOf(context).toLanguageTag(),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'DELIVERY ADDRESS & TIME SLOT',
                        style: TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 12,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DeliverySelectionCard(
                        checkout: checkout,
                        onChange: () => context.push(AppRoutes.customerAddress),
                      ),
                      if (_validationMessage case final message?) ...[
                        const SizedBox(height: 12),
                        _InlineMessage(message: message),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: const Color(0xF2F5F3E9),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: AppButton(
                    key: const ValueKey('placeOrder'),
                    label: 'Place Order',
                    onPressed: checkout.isReadyToContinue ? _placeOrder : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _placeOrder() {
    final checkout = ref.read(checkoutControllerProvider);
    final message = checkout.selectedAddress == null
        ? 'Please select a delivery address to continue.'
        : checkout.selectedDeliveryTimeSlot == null
        ? 'Please select a delivery time slot to continue.'
        : null;
    setState(() => _validationMessage = message);
    if (message == null) context.pushReplacement(AppRoutes.orderPlaced);
  }
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({required this.checkout, required this.locale});

  final CheckoutState checkout;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final selection = checkout.selection!;
    final schedule = checkout.schedule!;
    final price = selection.pricingOption;
    final date = DateFormat('dd MMM');
    return Container(
      key: const ValueKey('planSummaryCard'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.darkGreen.withValues(alpha: .1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.emeraldGreen,
            child: Row(
              children: [
                const Text(
                  'PLAN TOTAL',
                  style: TextStyle(
                    color: Color(0xFFD9F0E6),
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${formatMealPlanPriceAmount(selection.totalPrice, locale)} ${price.currencyCode}',
                  key: const ValueKey('summaryPlanTotal'),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryItem(label: 'PLAN', value: selection.mealPlan.name),
                _SummaryItem(
                  label: 'MEALS',
                  value: selection.mealCombination.name,
                ),
                _SummaryItem(
                  label: 'DELIVERY DAYS',
                  value: '${selection.deliveriesPerWeek} Days / Week',
                ),
                _SummaryItem(
                  label: 'DAYS',
                  value: selection.deliveryWeekdays
                      .map(_weekdayLabel)
                      .join(', '),
                ),
                _SummaryItem(
                  label: 'DURATION',
                  value: selection.pricingOption.name,
                ),
                _SummaryItem(
                  label: 'PLAN PERIOD',
                  value:
                      '${date.format(schedule.startDate)} - ${date.format(schedule.endDate)}',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 17),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.darkGreen.withValues(alpha: .52),
              fontSize: 10,
              letterSpacing: .7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DeliverySelectionCard extends StatelessWidget {
  const _DeliverySelectionCard({
    required this.checkout,
    required this.onChange,
  });

  final CheckoutState checkout;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final address = checkout.selectedAddress;
    final slot = checkout.selectedDeliveryTimeSlot;
    return Material(
      key: const ValueKey('deliverySelectionCard'),
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.darkGreen.withValues(alpha: .1)),
      ),
      child: InkWell(
        onTap: onChange,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: address == null
              ? Row(
                  children: [
                    const _RoundIcon(icon: Icons.location_on_outlined),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No delivery address selected',
                            style: TextStyle(
                              color: AppColors.darkGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Add Delivery Address',
                            style: TextStyle(
                              color: AppColors.emeraldGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _RoundIcon(icon: Icons.home_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            address.displayName,
                            style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Text(
                          'Change',
                          style: TextStyle(
                            color: AppColors.emeraldGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.emeraldGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(
                      address.area,
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address.streetLine,
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(alpha: .62),
                        fontSize: 12,
                      ),
                    ),
                    const Divider(height: 26),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: AppColors.emeraldGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: slot == null
                              ? const Text(
                                  'Select a delivery time slot',
                                  style: TextStyle(
                                    color: AppColors.emeraldGreen,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      slot.name,
                                      style: const TextStyle(
                                        color: AppColors.darkGreen,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      slot.timeRange,
                                      style: TextStyle(
                                        color: AppColors.darkGreen.withValues(
                                          alpha: .58,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: const BoxDecoration(
      color: Color(0xFFE7F4E8),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: AppColors.emeraldGreen),
  );
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFECE8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: const TextStyle(
        color: Color(0xFF9B351F),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _MissingCheckout extends StatelessWidget {
  const _MissingCheckout({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F3E9),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.emeraldGreen,
            ),
            const SizedBox(height: 14),
            const Text(
              'Choose a meal plan before reviewing your summary.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            AppButton(label: 'Browse Plans', onPressed: onBack),
          ],
        ),
      ),
    ),
  );
}

String _weekdayLabel(int weekday) => switch (weekday) {
  DateTime.monday => 'Mon',
  DateTime.tuesday => 'Tue',
  DateTime.wednesday => 'Wed',
  DateTime.thursday => 'Thu',
  DateTime.friday => 'Fri',
  DateTime.saturday => 'Sat',
  DateTime.sunday => 'Sun',
  _ => '',
};
