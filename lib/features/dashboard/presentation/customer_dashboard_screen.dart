import 'dart:async';

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CustomerDashboardScreen extends ConsumerStatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  ConsumerState<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState
    extends ConsumerState<CustomerDashboardScreen> {
  int _tabIndex = 0;
  bool _loadScheduled = false;

  String? get _profileId {
    final profile = ref.read(personalizationControllerProvider);
    final authUser = ref.read(otpAuthControllerProvider).user;
    final checkout = ref.read(checkoutControllerProvider);
    return profile.profileId ??
        authUser?.customerProfileId ??
        checkout.customerProfileId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadScheduled) return;
    _loadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileId = _profileId;
      if (mounted && profileId != null) {
        unawaited(
          ref
              .read(customerDashboardControllerProvider.notifier)
              .load(profileId),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(personalizationControllerProvider);
    final state = ref.watch(customerDashboardControllerProvider);
    final pages = [
      _DashboardHome(
        state: state,
        name: profile.preferredName,
        onViewAll: () => setState(() => _tabIndex = 1),
      ),
      _CustomerOrders(state: state),
      _CustomerProfile(name: profile.preferredName),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      body: SafeArea(
        child: IndexedStack(index: _tabIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.jasper.withValues(alpha: .12),
        destinations: const [
          NavigationDestination(
            key: ValueKey('dashboardHomeTab'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'HOME',
          ),
          NavigationDestination(
            key: ValueKey('dashboardOrdersTab'),
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'ORDERS',
          ),
          NavigationDestination(
            key: ValueKey('dashboardProfileTab'),
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}

class _DashboardHome extends ConsumerWidget {
  const _DashboardHome({
    required this.state,
    required this.name,
    required this.onViewAll,
  });

  final CustomerDashboardState state;
  final String? name;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state is DashboardLoading) return const _DashboardSkeleton();
    if (state is DashboardError) {
      return _DashboardErrorView(
        message: (state as DashboardError).message,
        onRetry: () =>
            ref.read(customerDashboardControllerProvider.notifier).refresh(),
      );
    }
    final orders = _ordersFrom(state);
    final dashboardState = state;
    final single = dashboardState is DashboardWithActivePlan
        ? dashboardState
        : null;
    final multiple = dashboardState is DashboardWithMultipleActivePlans
        ? dashboardState
        : null;
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(customerDashboardControllerProvider.notifier).refresh(),
      color: AppColors.jasper,
      child: ListView(
        key: const ValueKey('customerDashboard'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text(
            _welcome(name),
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 22),
          if (single != null) ...[
            const _SectionTitle('YOUR ACTIVE PLAN'),
            const SizedBox(height: 10),
            _ActivePlanCard(
              summary: single.order,
              detail: single.detail,
              prominent: true,
            ),
            if (_nextDelivery(single.detail) case final next?) ...[
              const SizedBox(height: 22),
              const _SectionTitle('NEXT DELIVERY'),
              const SizedBox(height: 10),
              _NextDeliveryCard(date: next, order: single.detail),
            ],
          ] else if (multiple != null) ...[
            const _SectionTitle('MY ACTIVE PLANS'),
            const SizedBox(height: 10),
            for (final order in multiple.activeOrders) ...[
              _ActivePlanCard(
                summary: order,
                detail: multiple.details[order.id],
              ),
              const SizedBox(height: 12),
            ],
          ] else if (state is DashboardWithoutActivePlan) ...[
            const _NoActivePlanCard(),
          ],
          const SizedBox(height: 22),
          if (state is! DashboardWithoutActivePlan)
            AppButton(
              key: const ValueKey('orderAnotherPlan'),
              label: '+  ORDER ANOTHER PLAN',
              backgroundColor: AppColors.black,
              onPressed: () => _startNewOrder(context, ref),
            ),
          if (orders.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                _SectionTitle(
                  state is DashboardWithoutActivePlan
                      ? 'PREVIOUS ORDERS'
                      : 'MY ORDERS',
                ),
                const Spacer(),
                TextButton(onPressed: onViewAll, child: const Text('VIEW ALL')),
              ],
            ),
            const SizedBox(height: 8),
            _OrdersCard(orders: orders.take(3).toList(growable: false)),
          ],
        ],
      ),
    );
  }
}

class _NoActivePlanCard extends ConsumerWidget {
  const _NoActivePlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) => _SurfaceCard(
    key: const ValueKey('noActivePlan'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.restaurant_menu_rounded,
          color: AppColors.jasper,
          size: 38,
        ),
        const SizedBox(height: 14),
        const Text(
          'NO ACTIVE PLAN',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.darkGreen,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "You don't have an active meal plan right now.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.darkGreen.withValues(alpha: .62),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          key: const ValueKey('choosePlan'),
          label: 'CHOOSE A PLAN',
          backgroundColor: AppColors.black,
          onPressed: () => _startNewOrder(context, ref),
        ),
      ],
    ),
  );
}

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({
    required this.summary,
    required this.detail,
    this.prominent = false,
  });

  final CustomerOrderSummary summary;
  final OrderConfirmation? detail;
  final bool prominent;

  @override
  Widget build(BuildContext context) => _SurfaceCard(
    key: ValueKey('activePlan-${summary.id}'),
    accent: prominent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                summary.planName,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _StatusPill(summary.status),
          ],
        ),
        const SizedBox(height: 14),
        _InfoLine('PLAN PERIOD', _period(summary.startDate, summary.endDate)),
        if (detail != null) ...[
          _InfoLine(
            'MEALS',
            detail!.meals
                .map((meal) => '${meal.name} x ${meal.quantity}')
                .join('\n'),
          ),
          _InfoLine(
            'DELIVERY',
            '${detail!.delivery.daysPerWeek} Days / Week\n${_weekdays(detail!.delivery.days)}',
          ),
          _InfoLine(
            'DELIVERY TIME',
            '${detail!.delivery.timeSlot.name}\n${_timeRange(detail!.delivery.timeSlot)}',
          ),
          _InfoLine(
            'DELIVERY ADDRESS',
            [
              detail!.delivery.address.displayName,
              detail!.delivery.address.area,
            ].where((value) => value.isNotEmpty).join('\n'),
          ),
        ],
        const SizedBox(height: 4),
        OutlinedButton(
          key: ValueKey('viewOrder-${summary.id}'),
          onPressed: () =>
              context.push(AppRoutes.orderDetails, extra: summary.id),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkGreen,
            side: const BorderSide(color: AppColors.darkGreen),
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(prominent ? 'VIEW PLAN' : 'VIEW DETAILS'),
        ),
      ],
    ),
  );
}

class _NextDeliveryCard extends StatelessWidget {
  const _NextDeliveryCard({required this.date, required this.order});

  final DateTime date;
  final OrderConfirmation order;

  @override
  Widget build(BuildContext context) => _SurfaceCard(
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.jasper.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.jasper,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMM').format(date),
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.delivery.timeSlot.name} · ${_timeRange(order.delivery.timeSlot)}',
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .62),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OrdersCard extends StatelessWidget {
  const _OrdersCard({required this.orders});

  final List<CustomerOrderSummary> orders;

  @override
  Widget build(BuildContext context) => _SurfaceCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var index = 0; index < orders.length; index++) ...[
          _OrderRow(order: orders[index]),
          if (index != orders.length - 1)
            Divider(
              height: 1,
              color: AppColors.darkGreen.withValues(alpha: .1),
            ),
        ],
      ],
    ),
  );
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final CustomerOrderSummary order;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('order-${order.id}'),
    onTap: () => context.push(AppRoutes.orderDetails, extra: order.id),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.planName} · ${_period(order.startDate, order.endDate)}',
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatMealPlanPriceAmount(order.totalAmount, Localizations.localeOf(context).toLanguageTag())} ${order.currencyCode}',
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .62),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(order.status),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _CustomerOrders extends ConsumerWidget {
  const _CustomerOrders({required this.state});

  final CustomerDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state is DashboardLoading) return const _DashboardSkeleton();
    if (state is DashboardError) {
      return _DashboardErrorView(
        message: (state as DashboardError).message,
        onRetry: () =>
            ref.read(customerDashboardControllerProvider.notifier).refresh(),
      );
    }
    final orders = _ordersFrom(state);
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(customerDashboardControllerProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const Text(
            'My Orders',
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          if (orders.isEmpty)
            const _SurfaceCard(
              child: Text(
                'No orders yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.darkGreen),
              ),
            )
          else
            _OrdersCard(orders: orders),
        ],
      ),
    );
  }
}

class _CustomerProfile extends StatelessWidget {
  const _CustomerProfile({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
    children: [
      const Text(
        'Profile',
        style: TextStyle(
          color: AppColors.darkGreen,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 20),
      _SurfaceCard(
        child: Row(
          children: [
            const CircleAvatar(
              radius: 27,
              backgroundColor: AppColors.emeraldGreen,
              child: Icon(Icons.person_rounded, color: AppColors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name?.trim().isNotEmpty == true ? name!.trim() : 'Customer',
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('dashboardLoading'),
    padding: const EdgeInsets.all(20),
    children: const [
      _SkeletonBox(height: 36, width: 210),
      SizedBox(height: 28),
      _SkeletonBox(height: 18, width: 130),
      SizedBox(height: 10),
      _SkeletonBox(height: 280),
      SizedBox(height: 22),
      _SkeletonBox(height: 54),
    ],
  );
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkGreen.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

class _DashboardErrorView extends StatelessWidget {
  const _DashboardErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    key: const ValueKey('dashboardError'),
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 46,
            color: AppColors.jasper,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
        ],
      ),
    ),
  );
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.accent = false,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: accent
            ? AppColors.jasper.withValues(alpha: .35)
            : AppColors.darkGreen.withValues(alpha: .08),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.darkGreen.withValues(alpha: .05),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: AppColors.darkGreen.withValues(alpha: .58),
      fontSize: 12,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.darkGreen.withValues(alpha: .5),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              color: AppColors.darkGreen,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: _statusColor(status).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: _statusColor(status),
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

void _startNewOrder(BuildContext context, WidgetRef ref) {
  ref.read(checkoutControllerProvider.notifier).beginNewOrder();
  context.push(AppRoutes.plans);
}

List<CustomerOrderSummary> _ordersFrom(CustomerDashboardState state) =>
    switch (state) {
      DashboardWithActivePlan(:final orders) => orders,
      DashboardWithMultipleActivePlans(:final orders) => orders,
      DashboardWithoutActivePlan(:final orders) => orders,
      _ => const [],
    };

String _welcome(String? name) {
  final value = name?.trim();
  return value == null || value.isEmpty
      ? 'Welcome back'
      : 'Welcome back, $value';
}

String _period(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '—';
  return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}';
}

String _weekdays(List<int> days) {
  const labels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };
  return days.map((day) => labels[day]).whereType<String>().join(', ');
}

String _timeRange(OrderTimeSlot slot) =>
    '${_time(slot.startTime)} - ${_time(slot.endTime)}';

String _time(String value) {
  final parts = value.split(':');
  final hour = parts.isEmpty ? null : int.tryParse(parts[0]);
  final minute = parts.length < 2 ? null : int.tryParse(parts[1]);
  if (hour == null || minute == null) return value;
  return DateFormat('hh:mm a').format(DateTime(2000, 1, 1, hour, minute));
}

DateTime? _nextDelivery(OrderConfirmation order) {
  final start = order.delivery.startDate;
  final end = order.delivery.endDate;
  if (start == null || end == null || order.delivery.days.isEmpty) return null;
  final now = DateTime.now();
  var candidate = DateTime(now.year, now.month, now.day);
  final first = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  if (candidate.isBefore(first)) candidate = first;
  while (!candidate.isAfter(last)) {
    if (order.delivery.days.contains(candidate.weekday)) return candidate;
    candidate = candidate.add(const Duration(days: 1));
  }
  return null;
}

Color _statusColor(String status) => switch (status) {
  'ACTIVE' => AppColors.emeraldGreen,
  'CONFIRMED' => const Color(0xFF2467A7),
  'PAUSED' => const Color(0xFF9A6500),
  'CANCELLED' => AppColors.jasper,
  _ => AppColors.darkGreen,
};
