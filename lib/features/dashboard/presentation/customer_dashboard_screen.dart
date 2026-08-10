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
        indicatorColor: AppColors.emeraldGreen.withValues(alpha: .14),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          _DashboardHeader(name: name),
          const SizedBox(height: 18),
          if (single != null) ...[
            const _SectionTitle('YOUR ACTIVE PLAN'),
            const SizedBox(height: 10),
            _PlanHeroCard(summary: single.order, detail: single.detail),
            if (_nextDelivery(single.detail) case final next?) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: _SectionTitle('UPCOMING DELIVERY')),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.menu),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('VIEW MENU'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _UpcomingDeliveryCard(date: next, order: single.detail),
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
          if (state is! DashboardWithoutActivePlan) ...[
            const SizedBox(height: 24),
            const _SectionTitle('QUICK ACTIONS'),
            const SizedBox(height: 10),
            _QuickActions(
              onPlan: single == null
                  ? null
                  : () => context.push(
                      AppRoutes.orderDetails,
                      extra: single.order.id,
                    ),
              onOrders: onViewAll,
              onNewPlan: () => _startNewOrder(context, ref),
            ),
          ],
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.darkGreen.withValues(alpha: .08),
              ),
            ),
            child: const Icon(
              Icons.menu_rounded,
              color: AppColors.darkGreen,
              size: 21,
            ),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.darkGreen,
                ),
              ),
              Positioned(
                right: 5,
                top: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.emeraldGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        '${_greeting()}, ${_displayName(name)} 👋',
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontSize: 23,
          letterSpacing: -.4,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Your meal plan is ready for you',
        style: TextStyle(
          color: AppColors.darkGreen.withValues(alpha: .56),
          fontSize: 13,
        ),
      ),
    ],
  );
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
          color: AppColors.emeraldGreen,
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

class _PlanHeroCard extends StatelessWidget {
  const _PlanHeroCard({required this.summary, required this.detail});

  final CustomerOrderSummary summary;
  final OrderConfirmation detail;

  @override
  Widget build(BuildContext context) {
    final next = _nextDelivery(detail);
    final address = detail.delivery.address;
    return Container(
      key: ValueKey('activePlan-${summary.id}'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF08765D), Color(0xFF064D3E)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldGreen.withValues(alpha: .24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: .16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.planName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail.meals
                          .map((meal) => '${meal.name} x ${meal.quantity}')
                          .join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: .78),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _HeroStatusPill(summary.status),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Divider(
              height: 1,
              color: AppColors.white.withValues(alpha: .18),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeroDetail(
                  icon: Icons.calendar_month_outlined,
                  value: _period(summary.startDate, summary.endDate),
                  caption: summary.planDurationName,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.white.withValues(alpha: .16),
              ),
              Expanded(
                child: _HeroDetail(
                  icon: Icons.wb_sunny_outlined,
                  value: next == null
                      ? 'Schedule ready'
                      : DateFormat('EEE, dd MMM').format(next),
                  caption:
                      '${detail.delivery.timeSlot.name} · ${_timeRange(detail.delivery.timeSlot)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _HeroDetail(
            icon: Icons.schedule_rounded,
            value: '${detail.delivery.daysPerWeek} Days / Week',
            caption: _weekdays(detail.delivery.days),
          ),
          const SizedBox(height: 12),
          _HeroDetail(
            icon: Icons.location_on_outlined,
            value: address.displayName,
            caption: [
              address.area,
              address.streetLine,
            ].where((value) => value.trim().isNotEmpty).join(' · '),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              key: ValueKey('viewOrder-${summary.id}'),
              onPressed: () =>
                  context.push(AppRoutes.orderDetails, extra: summary.id),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.darkGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: const Text(
                'VIEW PLAN',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDetail extends StatelessWidget {
  const _HeroDetail({
    required this.icon,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.white.withValues(alpha: .82), size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: .68),
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _HeroStatusPill extends StatelessWidget {
  const _HeroStatusPill(this.status);

  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFBFEA92),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status,
      style: const TextStyle(
        color: Color(0xFF205A36),
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({required this.summary, required this.detail});

  final CustomerOrderSummary summary;
  final OrderConfirmation? detail;

  @override
  Widget build(BuildContext context) => _SurfaceCard(
    key: ValueKey('activePlan-${summary.id}'),
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
          child: const Text('VIEW DETAILS'),
        ),
      ],
    ),
  );
}

class _UpcomingDeliveryCard extends StatelessWidget {
  const _UpcomingDeliveryCard({required this.date, required this.order});

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
            color: AppColors.teaGreen.withValues(alpha: .3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.emeraldGreen,
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
              if (order.meals.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final meal in order.meals.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen.withValues(alpha: .1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: AppColors.emeraldGreen,
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${meal.name}  × ${meal.quantity}',
                            style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onPlan,
    required this.onOrders,
    required this.onNewPlan,
  });

  final VoidCallback? onPlan;
  final VoidCallback onOrders;
  final VoidCallback onNewPlan;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _QuickAction(
          icon: Icons.badge_outlined,
          label: 'My Plan',
          onTap: onPlan,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _QuickAction(
          icon: Icons.local_shipping_outlined,
          label: 'Orders',
          onTap: onOrders,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _QuickAction(
          icon: Icons.add_circle_outline_rounded,
          label: 'New Plan',
          onTap: onNewPlan,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _QuickAction(
          icon: Icons.support_agent_rounded,
          label: 'Support',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Support will be available soon.')),
          ),
        ),
      ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkGreen.withValues(alpha: .08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.emeraldGreen, size: 22),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
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
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.darkGreen.withValues(alpha: .08)),
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

String _displayName(String? name) {
  final value = name?.trim();
  return value == null || value.isEmpty ? 'there' : value;
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
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
