import 'dart:async';

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OrderPlacedScreen extends ConsumerWidget {
  const OrderPlacedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmation = ref.watch(
      checkoutControllerProvider.select((state) => state.orderConfirmation),
    );
    if (confirmation == null) return const _MissingConfirmation();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      children: [
                        Container(
                          key: const ValueKey('orderPlacedIcon'),
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            color: AppColors.emeraldGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.white,
                            size: 54,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Order Confirmed!',
                          key: ValueKey('orderPlacedTitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Your ${confirmation.plan.name} Plan is ready.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.darkGreen.withValues(alpha: .64),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 26),
                        _ConfirmationCard(confirmation: confirmation),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                color: const Color(0xF2F8F6EF),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: AppButton(
                      key: const ValueKey('orderPlacedHome'),
                      label: 'GO TO DASHBOARD',
                      backgroundColor: AppColors.black,
                      onPressed: () => _goToDashboard(context, ref),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({required this.confirmation});

  final OrderConfirmation confirmation;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final delivery = confirmation.delivery;
    final address = delivery.address;
    final slot = delivery.timeSlot;
    return Container(
      key: const ValueKey('orderConfirmationCard'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.darkGreen.withValues(alpha: .1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: .06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Detail(label: 'ORDER NUMBER', value: confirmation.orderNumber),
          _Detail(label: 'PLAN', value: confirmation.plan.name),
          _Detail(
            label: 'PLAN PERIOD',
            value: _period(delivery.startDate, delivery.endDate),
          ),
          _Detail(
            label: 'FIRST DELIVERY',
            value: _firstDelivery(delivery.startDate),
          ),
          _Detail(
            label: slot.name,
            value: _timeRange(slot.startTime, slot.endTime),
          ),
          _Detail(
            label: 'DELIVERY TO',
            value: [
              address.displayName,
              address.area,
              address.streetLine,
            ].where((value) => value.trim().isNotEmpty).join('\n'),
          ),
          _Detail(
            label: 'TOTAL',
            value:
                '${formatMealPlanPriceAmount(confirmation.pricing.totalAmount, locale)} ${confirmation.pricing.currencyCode}',
          ),
          _Detail(
            label: 'STATUS',
            value: _titleCase(confirmation.status),
            isLast: true,
            accent: true,
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.label,
    required this.value,
    this.isLast = false,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool isLast;
  final bool accent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.darkGreen.withValues(alpha: .52),
            fontSize: 10,
            letterSpacing: .8,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: accent ? AppColors.emeraldGreen : AppColors.darkGreen,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _MissingConfirmation extends ConsumerWidget {
  const _MissingConfirmation();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: const Color(0xFFF8F6EF),
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
              'Order confirmation is unavailable.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'GO TO DASHBOARD',
              backgroundColor: AppColors.black,
              onPressed: () => _goToDashboard(context, ref),
            ),
          ],
        ),
      ),
    ),
  );
}

void _goToDashboard(BuildContext context, WidgetRef ref) {
  final profileId = ref.read(checkoutControllerProvider).customerProfileId;
  ref.invalidate(customerDashboardControllerProvider);
  if (profileId?.trim().isNotEmpty == true) {
    unawaited(
      ref
          .read(customerDashboardControllerProvider.notifier)
          .load(profileId!.trim(), force: true),
    );
  }
  context.go(AppRoutes.home);
}

String _period(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '—';
  final format = DateFormat('dd MMM');
  return '${format.format(start)} - ${format.format(end)}';
}

String _firstDelivery(DateTime? date) =>
    date == null ? '—' : DateFormat('EEEE, d MMMM').format(date);

String _timeRange(String start, String end) =>
    '${_time(start)} - ${_time(end)}';

String _time(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return value;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return value;
  return DateFormat('hh:mm a').format(DateTime(2000, 1, 1, hour, minute));
}

String _titleCase(String value) {
  final normalized = value.replaceAll('_', ' ').trim().toLowerCase();
  if (normalized.isEmpty) return 'Confirmed';
  return normalized
      .split(' ')
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
