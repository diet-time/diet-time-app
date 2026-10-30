import 'package:diet_time/features/plans/presentation/meal_plan_start_date_screen.dart';
import 'dart:async';

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:diet_time/features/plans/presentation/package_discount_details.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
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
  bool _preparedOrderOptions = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => Future.wait([
        ref.read(checkoutControllerProvider.notifier).loadDeliveryTimeSlots(),
        ref.read(checkoutControllerProvider.notifier).loadAddresses(),
        ref.read(checkoutControllerProvider.notifier).loadBranches(),
      ]),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preparedOrderOptions) return;
    _preparedOrderOptions = true;
    final language = Localizations.localeOf(context).toLanguageTag();
    Future<void>.microtask(
      () => ref
          .read(checkoutControllerProvider.notifier)
          .prepareForOrder(language: language),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutControllerProvider);
    final selection = checkout.selection;
    if (selection == null) {
      return _MissingCheckout(onBack: () => context.go(AppRoutes.plans));
    }
    final summaryMessage = checkout.isResolvingOrderOptions
        ? 'Verifying your selected plan...'
        : checkout.placementError ?? checkout.placeOrderValidationMessage;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const ValueKey('planSummaryBack'),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.plans),
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
                      const SizedBox(height: 16),
                      Text(
                        checkout.fulfillmentLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (!checkout.isDeliveryEnabled)
                        const Text(
                          'This package is available for takeaway only.',
                        )
                      else
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'TAKEAWAY',
                              label: Text('Takeaway'),
                            ),
                            ButtonSegment(
                              value: 'HOME_DELIVERY',
                              label: Text('Home Delivery'),
                            ),
                          ],
                          selected: {
                            checkout.isTakeaway ? 'TAKEAWAY' : 'HOME_DELIVERY',
                          },
                          onSelectionChanged: checkout.isPlacingOrder
                              ? null
                              : (values) => ref
                                    .read(checkoutControllerProvider.notifier)
                                    .selectFulfillmentMethod(values.single),
                        ),
                      if (checkout.isTakeaway) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'COLLECTION BRANCH',
                          style: TextStyle(
                            color: AppColors.darkGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (checkout.isLoadingBranches)
                          const LinearProgressIndicator(),
                        if (checkout.branchError != null)
                          TextButton(
                            onPressed: () => ref
                                .read(checkoutControllerProvider.notifier)
                                .loadBranches(),
                            child: Text(checkout.branchError!),
                          ),
                        if (!checkout.isLoadingBranches &&
                            checkout.branchError == null &&
                            checkout.branches.isEmpty)
                          const Text(
                            'No takeaway branches are currently available.',
                          ),
                        for (final branch in checkout.branches)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Material(
                              color: checkout.selectedBranch?.id == branch.id
                                  ? const Color(0xFFE6F2E9)
                                  : AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color:
                                      checkout.selectedBranch?.id == branch.id
                                      ? AppColors.emeraldGreen
                                      : const Color(0xFFD9DFD5),
                                ),
                              ),
                              child: ListTile(
                                key: ValueKey('branch-${branch.id}'),
                                leading: Icon(
                                  checkout.selectedBranch?.id == branch.id
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: AppColors.emeraldGreen,
                                ),
                                title: Text(
                                  branch.name,
                                  style: const TextStyle(
                                    color: AppColors.darkGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle:
                                    branch.address?.trim().isNotEmpty == true
                                    ? Text(branch.address!)
                                    : null,
                                onTap: checkout.isPlacingOrder
                                    ? null
                                    : () => ref
                                          .read(
                                            checkoutControllerProvider.notifier,
                                          )
                                          .selectBranch(branch),
                              ),
                            ),
                          ),
                      ],
                      if (!checkout.isTakeaway) ...[
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
                          onChange: () =>
                              context.push(AppRoutes.customerAddress),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Material(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          key: const ValueKey('checkoutStartDate'),
                          leading: const Icon(
                            Icons.calendar_month_outlined,
                            color: AppColors.emeraldGreen,
                          ),
                          title: const Text('Start Date'),
                          subtitle: Text(
                            checkout.schedule == null
                                ? 'Select your service dates'
                                : '${DateFormat('dd MMM yyyy').format(checkout.schedule!.startDate)} – ${DateFormat('dd MMM yyyy').format(checkout.schedule!.endDate)}\n${checkout.schedule!.serviceDates.length} service days',
                          ),
                          trailing: const Icon(Icons.expand_more),
                          onTap: checkout.isPlacingOrder
                              ? null
                              : () async {
                                  final schedule =
                                      await showMealPlanStartDatePanel(
                                        context: context,
                                        selection: selection,
                                        currentSchedule: checkout.schedule,
                                      );
                                  if (schedule != null && mounted) {
                                    ref
                                        .read(
                                          checkoutControllerProvider.notifier,
                                        )
                                        .begin(selection, schedule);
                                  }
                                },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        key: const ValueKey('checkoutOrderTotal'),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F1E4),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFCEDFCE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Total',
                              style: TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${selection.pricingOption.currencyCode} ${formatMealPlanPriceAmount(selection.totalPrice, Localizations.localeOf(context).toLanguageTag())}',
                              key: const ValueKey('checkoutFinalAmount'),
                              style: const TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (selection.pricingOption.hasDiscount)
                              PackageDiscountDetails(
                                package: selection.pricingOption,
                              ),
                          ],
                        ),
                      ),
                      if (summaryMessage case final message?) ...[
                        const SizedBox(height: 12),
                        _InlineMessage(
                          message: message,
                          onRetry:
                              checkout.mealPlanPriceId?.trim().isNotEmpty !=
                                      true &&
                                  !checkout.isResolvingOrderOptions
                              ? () => ref
                                    .read(checkoutControllerProvider.notifier)
                                    .prepareForOrder(
                                      language: Localizations.localeOf(
                                        context,
                                      ).toLanguageTag(),
                                    )
                              : null,
                        ),
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
                    label: 'PLACE ORDER',
                    loadingLabel: checkout.isPlacingOrder
                        ? 'PLACING ORDER...'
                        : 'PREPARING ORDER...',
                    isLoading:
                        checkout.isPlacingOrder ||
                        checkout.isResolvingOrderOptions,
                    backgroundColor: AppColors.darkGreen,
                    onPressed:
                        checkout.isPlacingOrder ||
                            checkout.isResolvingOrderOptions
                        ? null
                        : _placeOrder,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    final profileId = ref.read(checkoutControllerProvider).customerProfileId;
    final confirmation = await ref
        .read(checkoutControllerProvider.notifier)
        .placeOrder(language: Localizations.localeOf(context).toLanguageTag());
    if (confirmation != null && mounted) {
      ref.invalidate(customerDashboardControllerProvider);
      // /home can reuse its existing widget after another purchase, so its
      // initState will not run again when the controller is invalidated.
      unawaited(
        ref
            .read(customerDashboardControllerProvider.notifier)
            .initialize(profileId: profileId, force: true),
      );
      context.go(AppRoutes.home);
    }
  }
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({required this.checkout, required this.locale});

  final CheckoutState checkout;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final selection = checkout.selection!;

    final price = selection.pricingOption;
    return Container(
      key: const ValueKey('planSummaryCard'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkGreen.withValues(alpha: .1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            selection.mealPlan.name,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            selection.mealCombination.entitlementLabel(
              Localizations.localeOf(context).languageCode,
            ),
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${price.name} · ${selection.serviceDays} service days',
            style: TextStyle(color: AppColors.darkGreen.withValues(alpha: .7)),
          ),
        ],
      ),
    );
  }
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
  const _InlineMessage({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFECE8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF9B351F),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onRetry case final onRetry?)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
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
