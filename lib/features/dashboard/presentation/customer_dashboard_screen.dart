import 'package:diet_time/app/localization/customer_copy.dart';
import 'package:diet_time/features/language/presentation/dashboard_language_switcher.dart';
import 'dart:async';
import 'package:diet_time/features/app_tour/app_tour_controller.dart';
import 'package:diet_time/features/app_tour/app_tour_host.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/checkout/domain/order_status.dart';
import 'package:diet_time/features/dashboard/presentation/tomorrow_deliveries_section.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/dashboard/domain/customer_account_profile.dart';
import 'package:diet_time/features/dashboard/presentation/customer_profile_tab.dart';
import 'package:diet_time/features/dashboard/presentation/customer_profile_controller.dart';
import 'package:diet_time/features/dashboard/presentation/order_details_screen.dart';
import 'package:diet_time/features/dashboard/presentation/customer_delivery_calendar.dart';
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
    extends ConsumerState<CustomerDashboardScreen>
    with WidgetsBindingObserver {
  Timer? _orderRefresh;
  int _tabIndex = 0;
  bool _profileLoadQueued = false;
  String? _tourDestination;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _orderRefresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        unawaited(
          ref.read(customerDashboardControllerProvider.notifier).refresh(),
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(customerDashboardControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _orderRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref.read(customerDashboardControllerProvider.notifier).refresh(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(personalizationControllerProvider);
    final state = ref.watch(customerDashboardControllerProvider);
    ref.listen(
      customerProfileControllerProvider.select((value) => value.requiresLogin),
      (_, requiresLogin) {
        if (requiresLogin) _goToPhoneLogin();
      },
    );
    _ensureProfileLoaded();
    ref.watch(appTourControllerProvider);
    ref.read(appTourControllerProvider.notifier).navigate = _tourNavigate;
    final ready =
        state is DashboardNoOrders ||
        state is DashboardWithoutActivePlan ||
        state is DashboardWithActivePlan ||
        state is DashboardWithMultipleActivePlans;
    if (ready && _tabIndex == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            GoRouter.maybeOf(
                  context,
                )?.routerDelegate.currentConfiguration.lastOrNull?.route.path ==
                AppRoutes.home) {
          ref.read(appTourControllerProvider.notifier).maybeStart();
        }
      });
    }
    final pages = [
      _DashboardHome(
        state: state,
        name: profile.preferredName,
        onViewAll: () => setState(() => _tabIndex = 1),
      ),
      _CustomerOrders(state: state),
      _DashboardCalendar(state: state),
      CustomerProfileTab(
        onBack: () => setState(() => _tabIndex = 0),
        onEditAddress: _editAddress,
        onEditProfile: _openCustomerProfile,
        onQuestionnaire: _openQuestionnaire,
        onLogout: _confirmLogout,
        tourSetting: const AppTourSetting(),
      ),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      body: SafeArea(
        child: IndexedStack(index: _tabIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('dashboardNavigation'),
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.emeraldGreen.withValues(alpha: .14),
        destinations: [
          NavigationDestination(
            key: ValueKey('dashboardHomeTab'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: context.customerCopy('HOME'),
          ),
          NavigationDestination(
            key: ValueKey('dashboardOrdersTab'),
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: context.customerCopy('ORDERS'),
          ),
          NavigationDestination(
            key: ValueKey('dashboardCalendarTab'),
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: context.customerCopy('CALENDAR'),
          ),
          NavigationDestination(
            key: ValueKey('dashboardProfileTab'),
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: context.customerCopy('PROFILE'),
          ),
        ],
      ),
    );
  }

  Future<void> _tourNavigate(String destination) async {
    if (!mounted || !ref.read(otpAuthControllerProvider).isAuthenticated) {
      return;
    }
    final router = GoRouter.of(context);
    // Return through the existing stack; never create another dashboard route.
    final expectedPath = switch (destination) {
      'menu' => AppRoutes.menu,
      'plans' => AppRoutes.plans,
      'orderDetails' => AppRoutes.orderDetails,
      _ => AppRoutes.home,
    };
    if (_tourDestination == destination &&
        router.routerDelegate.currentConfiguration.lastOrNull?.route.path ==
            expectedPath) {
      return;
    }
    if (_tourDestination != null &&
        !['home', 'orders', 'calendar', 'profile'].contains(_tourDestination) &&
        router.canPop()) {
      router.pop();
    }
    _tourDestination = destination;
    if (!mounted) return;
    setState(
      () => _tabIndex = switch (destination) {
        'orders' => 1,
        'calendar' => 2,
        'profile' => 3,
        _ => 0,
      },
    );
    if (destination == 'menu') {
      unawaited(context.push(AppRoutes.menu, extra: 'dashboard'));
    }
    if (destination == 'plans') unawaited(context.push(AppRoutes.plans));
    if (destination == 'orderDetails') {
      final orders = dashboardPlanOrders(
        ref.read(customerDashboardControllerProvider),
      );
      if (orders.isNotEmpty) {
        unawaited(context.push(AppRoutes.orderDetails, extra: orders.first.id));
      }
    }
  }

  void _ensureProfileLoaded() {
    if (_tabIndex != 3 || _profileLoadQueued) return;
    final state = ref.read(customerProfileControllerProvider);
    if (state.hasLoaded || state.isLoading) return;
    _profileLoadQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(customerProfileControllerProvider.notifier).load();
      _profileLoadQueued = false;
    });
  }

  Future<void> _editProfile(CustomerAccountProfile account) async {
    final updated = await context.push<bool>(
      AppRoutes.editCustomerProfile,
      extra: account,
    );
    if (updated == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.customerCopy('Profile updated successfully')),
          ),
        );
    }
  }

  Future<void> _openCustomerProfile() async {
    var account = ref.read(customerProfileControllerProvider).profile;
    if (account == null) {
      await ref
          .read(customerProfileControllerProvider.notifier)
          .load(force: true);
      if (!mounted) return;
      account = ref.read(customerProfileControllerProvider).profile;
    }
    if (account == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.customerCopy('Unable to load your profile.')),
          ),
        );
      return;
    }
    await _editProfile(account);
  }

  Future<void> _editAddress() async {
    await context.push(AppRoutes.customerAddress);
    if (!mounted) return;
    await ref.read(checkoutControllerProvider.notifier).loadAddresses();
  }

  Future<void> _openQuestionnaire() async {
    final updated = await context.push<bool>(AppRoutes.customerQuestionnaire);
    if (updated == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.customerCopy('Questionnaire updated successfully'),
            ),
          ),
        );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.customerCopy('Logout')),
        content: Text(context.customerCopy('Are you sure you want to logout?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.customerCopy('Cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(context.customerCopy('Logout')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(customerProfileControllerProvider.notifier).logout();
    if (mounted) _goToPhoneLogin();
  }

  void _goToPhoneLogin() => context.go(
    AppRoutes.phoneLogin,
    extra: const PendingAuthDestination(route: AppRoutes.authenticatedLanding),
  );
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
    if (state is DashboardAuthenticationFailure) {
      return _DashboardErrorView(
        message: context.customerCopy(
          'Your session has expired. Please sign in again.',
        ),
        actionLabel: context.customerCopy('SIGN IN'),
        onRetry: () => context.go(
          AppRoutes.phoneLogin,
          extra: const PendingAuthDestination(
            route: AppRoutes.authenticatedLanding,
          ),
        ),
      );
    }
    if (state is DashboardProfileNotFound) {
      return _DashboardErrorView(
        message: context.customerCopy(
          'Your customer profile could not be found.',
        ),
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
    final plans = dashboardPlanOrders(state);
    final details = {
      if (single != null) single.order.id: single.detail,
      if (multiple != null) ...multiple.details,
    };
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(customerDashboardControllerProvider.notifier).refresh(),
      color: AppColors.jasper,
      child: ListView(
        key: const ValueKey('customerDashboard'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          Wrap(
            key: const ValueKey('dashboardHeaderControls'),
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                key: const ValueKey('dashboardMenuButton'),
                onPressed: () =>
                    context.push(AppRoutes.menu, extra: 'dashboard'),
                icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                label: Text(
                  lookupAppLocalizations(
                    Localizations.localeOf(context),
                  ).menuButton,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  foregroundColor: AppColors.emeraldGreen,
                  backgroundColor: AppColors.white,
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    color: AppColors.emeraldGreen.withValues(alpha: .18),
                  ),
                ),
              ),
              const DashboardLanguageSwitcher(),
            ],
          ),
          const SizedBox(height: 8),
          _ReferenceDashboardHeader(
            name: name,
            subtitle: _dashboardSubtitle(context, state),
          ),
          const SizedBox(height: 18),
          if (plans.isNotEmpty) ...[
            Row(
              children: [
                Expanded(child: _SectionTitle(copy.dashboardMyPlans)),
                const Spacer(),
                Text(
                  copy.dashboardPlanCount(plans.length),
                  key: const ValueKey('dashboardPlanCount'),
                  style: const TextStyle(
                    color: AppColors.emeraldGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (plans.length == 1)
              _ReferencePlanCard(
                summary: plans.single,
                detail: details[plans.single.id],
              )
            else
              _MultiPlanCarousel(orders: plans, details: details),
            if (single != null || multiple != null) ...[
              const SizedBox(height: 16),
              TomorrowDeliveriesSection(
                orders: single != null
                    ? [single.order]
                    : multiple!.activeOrders,
              ),
            ],
          ] else if (state is DashboardWithoutActivePlan ||
              state is DashboardNoOrders) ...[
            const _NoActivePlanCard(),
          ],
          const SizedBox(height: 22),
          if (plans.isNotEmpty)
            OutlinedButton.icon(
              key: const ValueKey('orderAnotherPlan'),
              onPressed: () => _startNewOrder(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.darkGreen,
                minimumSize: const Size.fromHeight(46),
                side: BorderSide(
                  color: AppColors.emeraldGreen.withValues(alpha: .5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 17),
              label: Text(
                context.customerCopy('ORDER ANOTHER PLAN'),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ),
          if (plans.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionTitle(context.customerCopy('QUICK ACTIONS')),
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
                Expanded(
                  child: _SectionTitle(
                    plans.isEmpty
                        ? context.customerCopy('PREVIOUS ORDERS')
                        : context.customerCopy('MY ORDERS'),
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: Text(context.customerCopy('VIEW ALL')),
                ),
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

class _ReferenceDashboardHeader extends StatelessWidget {
  const _ReferenceDashboardHeader({required this.name, required this.subtitle});

  final String? name;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting(context)}, ${_displayName(name)} 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 20,
                  letterSpacing: -.35,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 10),
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.darkGreen.withValues(alpha: .07)),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGreen.withValues(alpha: .05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.darkGreen,
                size: 21,
              ),
            ),
            PositionedDirectional(
              end: 7,
              top: 6,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.emeraldGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ignore: unused_element
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.name, required this.subtitle});

  final String? name;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
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
        '${_greeting(context)}, ${_displayName(name)} 👋',
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontSize: 23,
          letterSpacing: -.4,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
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
        Text(
          context.customerCopy('NO ACTIVE PLAN'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.darkGreen,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.customerCopy("You don't have an active meal plan right now."),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.darkGreen.withValues(alpha: .62),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          key: const ValueKey('choosePlan'),
          label: context.customerCopy('CHOOSE A PLAN'),
          backgroundColor: AppColors.black,
          onPressed: () => _startNewOrder(context, ref),
        ),
      ],
    ),
  );
}

double _activePlanCardHeight(BuildContext context) =>
    164 +
    (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(
          0,
          double.infinity,
        ) *
        10;

class _ReferencePlanCard extends ConsumerWidget {
  const _ReferencePlanCard({required this.summary, this.detail});
  final CustomerOrderSummary summary;
  final OrderConfirmation? detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = lookupAppLocalizations(Localizations.localeOf(context));
    final pending = const {
      'PENDING_APPROVAL',
      'PENDING',
    }.contains(summary.status);
    final (background, icon) = switch (summary.status) {
      'PENDING_APPROVAL' ||
      'PENDING' => (const Color(0xFF8B642D), Icons.schedule_rounded),
      'ON_HOLD' ||
      'PAUSED' => (const Color(0xFF9B503A), Icons.pause_circle_outline),
      _ => (const Color(0xFF075A43), Icons.check_circle_outline),
    };
    final package = (detail?.entitlement ?? summary.entitlement)?.label(
      Localizations.localeOf(context).languageCode,
    );
    final status = context.customerCopy(
      pending ? 'Pending' : summary.statusLabel,
    );
    Future<void> openDetails() async {
      await context.push(AppRoutes.orderDetails, extra: summary.id);
      if (context.mounted) {
        unawaited(
          ref.read(customerDashboardControllerProvider.notifier).refresh(),
        );
      }
    }

    Widget line(String value, {int maxLines = 1, double size = 11}) => Text(
      value,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: AppColors.white, fontSize: size),
    );
    return Material(
      key: ValueKey('activePlan-${summary.id}'),
      color: background,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openDetails,
        child: SizedBox(
          height: _activePlanCardHeight(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        summary.planName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: Container(
                        key: ValueKey('planStatus-${summary.id}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 13, color: AppColors.white),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                status,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                line(
                  package?.isNotEmpty == true
                      ? package!
                      : summary.planDurationName,
                  size: 12,
                ),
                line(context.customerCopy(summary.fulfillmentLabel)),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: line(
                        _period(
                          summary.startDate,
                          summary.endDate,
                          locale: Localizations.localeOf(context).languageCode,
                        ),
                        maxLines: 2,
                        size: 10,
                      ),
                    ),
                    TextButton(
                      key: ValueKey('viewOrder-${summary.id}'),
                      onPressed: openDetails,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(copy.deliveriesViewDetails),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
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
                      detail.entitlement.label(
                        Localizations.localeOf(context).languageCode,
                      ),
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
                  caption:
                      '${summary.planDurationName} · ${context.customerCopy(summary.fulfillmentLabel)}${summary.takeawayBranch == null ? '' : ' · ${summary.takeawayBranch!.name}'}',
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
                      ? context.customerCopy('Schedule ready')
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
            value: lookupAppLocalizations(
              Localizations.localeOf(context),
            ).customerDaysPerWeek(detail.delivery.daysPerWeek),
            caption: _weekdays(context, detail.delivery.days),
          ),
          const SizedBox(height: 12),
          _HeroDetail(
            icon: Icons.location_on_outlined,
            value: detail.isTakeaway
                ? context.customerCopy('Takeaway')
                : address.displayName,
            caption: detail.isTakeaway
                ? context.customerCopy('Collect from Diet Time')
                : [
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
              label: Text(
                context.customerCopy('VIEW PLAN'),
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
      orderStatusLabel(status),
      style: const TextStyle(
        color: Color(0xFF205A36),
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _MultiPlanCarousel extends StatefulWidget {
  const _MultiPlanCarousel({required this.orders, required this.details});

  final List<CustomerOrderSummary> orders;
  final Map<String, OrderConfirmation> details;

  @override
  State<_MultiPlanCarousel> createState() => _MultiPlanCarouselState();
}

class _MultiPlanCarouselState extends State<_MultiPlanCarousel> {
  late final PageController _controller = PageController(viewportFraction: .93);
  int _page = 0;

  @override
  void didUpdateWidget(covariant _MultiPlanCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= widget.orders.length) {
      _page = widget.orders.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(_page);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: _activePlanCardHeight(context),
        child: PageView.builder(
          key: const ValueKey('activePlansCarousel'),
          controller: _controller,
          padEnds: false,
          itemCount: widget.orders.length,
          onPageChanged: (page) => setState(() => _page = page),
          itemBuilder: (context, index) {
            final order = widget.orders[index];
            return Padding(
              padding: EdgeInsetsDirectional.only(
                end: index == widget.orders.length - 1 ? 0 : 10,
              ),
              child: _ReferencePlanCard(
                summary: order,
                detail: widget.details[order.id],
              ),
            );
          },
        ),
      ),
      if (widget.orders.length > 1) ...[
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < widget.orders.length; index++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: index == _page ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _page
                      ? AppColors.emeraldGreen
                      : AppColors.teaGreen,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
      ],
    ],
  );
}

// ignore: unused_element
class _CompactPlanCard extends StatelessWidget {
  const _CompactPlanCard({required this.summary, required this.detail});

  final CustomerOrderSummary summary;
  final OrderConfirmation? detail;

  @override
  Widget build(BuildContext context) {
    final delivery = detail?.delivery;
    final meals = detail?.meals ?? const <OrderMeal>[];
    return Container(
      key: ValueKey('activePlan-${summary.id}'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF08765D), Color(0xFF064D3E)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldGreen.withValues(alpha: .2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: .15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppColors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  summary.planName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _HeroStatusPill(summary.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            meals.isEmpty
                ? summary.planDurationName
                : detail!.entitlement.label(
                    Localizations.localeOf(context).languageCode,
                  ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: .74),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              color: AppColors.white.withValues(alpha: .16),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _HeroDetail(
                  icon: Icons.calendar_month_outlined,
                  value: _period(summary.startDate, summary.endDate),
                  caption:
                      '${summary.planDurationName} · ${context.customerCopy(summary.fulfillmentLabel)}${summary.takeawayBranch == null ? '' : ' · ${summary.takeawayBranch!.name}'}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroDetail(
                  icon: Icons.schedule_rounded,
                  value: delivery == null
                      ? context.customerCopy('Schedule ready')
                      : lookupAppLocalizations(
                          Localizations.localeOf(context),
                        ).customerDaysPerWeek(delivery.daysPerWeek),
                  caption: delivery == null
                      ? ''
                      : _weekdays(context, delivery.days),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatMealPlanPriceAmount(summary.totalAmount, Localizations.localeOf(context).toLanguageTag())} ${summary.currencyCode}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              FilledButton.icon(
                key: ValueKey('viewOrder-${summary.id}'),
                onPressed: () =>
                    context.push(AppRoutes.orderDetails, extra: summary.id),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.darkGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: Text(
                  context.customerCopy('DETAILS'),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
          label: context.customerCopy('My Plan'),
          onTap: onPlan,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _QuickAction(
          icon: Icons.local_shipping_outlined,
          label: context.customerCopy('Orders'),
          onTap: onOrders,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _QuickAction(
          icon: Icons.add_circle_outline_rounded,
          label: context.customerCopy('New Plan'),
          onTap: onNewPlan,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _QuickAction(
          icon: Icons.support_agent_rounded,
          label: context.customerCopy('Support'),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.customerCopy('Support will be available soon.'),
              ),
            ),
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
    onTap: () => _openReviewedOrder(context, order.id),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
          Flexible(child: _StatusPill(order.status)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _CustomerOrders extends ConsumerStatefulWidget {
  const _CustomerOrders({required this.state});

  final CustomerDashboardState state;

  @override
  ConsumerState<_CustomerOrders> createState() => _CustomerOrdersState();
}

class _DashboardCalendar extends ConsumerWidget {
  const _DashboardCalendar({required this.state});

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
    if (state is DashboardAuthenticationFailure) {
      return _DashboardErrorView(
        message: context.customerCopy(
          'Your session has expired. Please sign in again.',
        ),
        actionLabel: context.customerCopy('SIGN IN'),
        onRetry: () => context.go(
          AppRoutes.phoneLogin,
          extra: const PendingAuthDestination(
            route: AppRoutes.authenticatedLanding,
          ),
        ),
      );
    }
    if (state is DashboardProfileNotFound) {
      return _DashboardErrorView(
        message: context.customerCopy(
          'Your customer profile could not be found.',
        ),
        onRetry: () =>
            ref.read(customerDashboardControllerProvider.notifier).refresh(),
      );
    }
    final orders = _ordersFrom(
      state,
    ).where((o) => o.isCurrent || o.isCompleted).toList();
    if (orders.isNotEmpty) {
      return CustomerDeliveryCalendar(
        orders: orders,
        knownOrders: switch (state) {
          DashboardWithActivePlan(:final detail) => {detail.id: detail},
          DashboardWithMultipleActivePlans(:final details) => details,
          _ => const {},
        },
      );
    }
    return ListView(
      key: const ValueKey('emptyDashboardCalendar'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
      children: [
        Text(
          context.customerCopy('Delivery Calendar'),
          style: TextStyle(
            color: AppColors.darkGreen,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        _SurfaceCard(
          child: Column(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.emeraldGreen,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                context.customerCopy('No active delivery calendar'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.customerCopy(
                  'Your delivery dates will appear here when a meal plan is active.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkGreen.withValues(alpha: .58),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomerOrdersState extends ConsumerState<_CustomerOrders> {
  String _filter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state is DashboardLoading) return const _DashboardSkeleton();
    if (state is DashboardError) {
      return _DashboardErrorView(
        message: state.message,
        onRetry: () =>
            ref.read(customerDashboardControllerProvider.notifier).refresh(),
      );
    }
    if (state is DashboardAuthenticationFailure) {
      return _DashboardErrorView(
        message: context.customerCopy(
          'Your session has expired. Please sign in again.',
        ),
        actionLabel: context.customerCopy('SIGN IN'),
        onRetry: () => context.go(
          AppRoutes.phoneLogin,
          extra: const PendingAuthDestination(
            route: AppRoutes.authenticatedLanding,
          ),
        ),
      );
    }
    if (state is DashboardProfileNotFound) {
      return _DashboardErrorView(
        message: context.customerCopy(
          'Your customer profile could not be found.',
        ),
        onRetry: () =>
            ref.read(customerDashboardControllerProvider.notifier).refresh(),
      );
    }
    final orders = _ordersFrom(state);
    final filtered = _filter == 'ALL'
        ? orders
        : orders.where((order) => order.status == _filter).toList();
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(customerDashboardControllerProvider.notifier).refresh(),
      child: ListView(
        key: const ValueKey('tourOrdersList'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.customerCopy('My Orders'),
                      style: TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      context.customerCopy('All your meal orders in one place'),
                      style: TextStyle(color: Color(0xFF81908B), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.darkGreen.withValues(alpha: .07),
                  ),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.darkGreen,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in [
                  ('ALL', context.customerCopy('All Orders')),
                  (
                    'PENDING_APPROVAL',
                    context.customerCopy('Pending Confirmation'),
                  ),
                  ('ON_HOLD', context.customerCopy('On Hold')),
                  ('REJECTED', context.customerCopy('Rejected')),
                  ('CONFIRMED', context.customerCopy('Confirmed')),
                  ('PENDING', context.customerCopy('Pending')),
                  ('CANCELLED', context.customerCopy('Cancelled')),
                ]) ...[
                  _OrderFilterChip(
                    label: filter.$2,
                    count: filter.$1 == 'ALL'
                        ? orders.length
                        : orders
                              .where((order) => order.status == filter.$1)
                              .length,
                    selected: _filter == filter.$1,
                    onTap: () => setState(() => _filter = filter.$1),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _SurfaceCard(
              child: Text(
                context.customerCopy('No orders found for this status.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.darkGreen),
              ),
            )
          else
            for (final order in filtered) ...[
              _DetailedOrderCard(order: order),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _OrderFilterChip extends StatelessWidget {
  const _OrderFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(99),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.emeraldGreen : AppColors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: selected
              ? AppColors.emeraldGreen
              : AppColors.darkGreen.withValues(alpha: .08),
        ),
      ),
      child: Text(
        '$label ($count)',
        style: TextStyle(
          color: selected ? AppColors.white : AppColors.darkGreen,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _DetailedOrderCard extends ConsumerWidget {
  const _DetailedOrderCard({required this.order});

  final CustomerOrderSummary order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(orderDetailsProvider(order.id)).value;
    final delivery = detail?.delivery;
    final mealSummary = (detail?.entitlement ?? order.entitlement)?.label(
      Localizations.localeOf(context).languageCode,
    );
    return InkWell(
      key: ValueKey('detailedOrder-${order.id}'),
      onTap: () => _openReviewedOrder(context, order.id),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.darkGreen.withValues(alpha: .06)),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGreen.withValues(alpha: .045),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppColors.teaGreen.withValues(alpha: .24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: AppColors.emeraldGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.planName,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _period(order.startDate, order.endDate),
                        style: TextStyle(
                          color: AppColors.darkGreen.withValues(alpha: .58),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(order.status),
                const SizedBox(width: 3),
                const Icon(Icons.more_horiz_rounded, size: 18),
              ],
            ),
            if (delivery != null || mealSummary != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  if (delivery != null)
                    _OrderFact(
                      icon: Icons.calendar_today_outlined,
                      text: lookupAppLocalizations(
                        Localizations.localeOf(context),
                      ).customerDaysPerWeek(delivery.daysPerWeek),
                    ),
                  if (mealSummary != null)
                    _OrderFact(
                      icon: Icons.restaurant_outlined,
                      text: mealSummary,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '${formatMealPlanPriceAmount(order.totalAmount, Localizations.localeOf(context).toLanguageTag())} ${order.currencyCode}',
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Divider(
                height: 1,
                color: AppColors.darkGreen.withValues(alpha: .07),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.placedAt == null
                        ? context.customerCopy('Order placed')
                        : 'Ordered on ${DateFormat('dd MMM yyyy').format(order.placedAt!)}',
                    style: TextStyle(
                      color: AppColors.darkGreen.withValues(alpha: .54),
                      fontSize: 9,
                    ),
                  ),
                ),
                Text(
                  context.customerCopy('View Details  →'),
                  style: TextStyle(
                    color: AppColors.emeraldGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderFact extends StatelessWidget {
  const _OrderFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppColors.darkGreen.withValues(alpha: .55), size: 13),
      const SizedBox(width: 5),
      Text(
        text,
        style: TextStyle(
          color: AppColors.darkGreen.withValues(alpha: .72),
          fontSize: 9,
          fontWeight: FontWeight.w700,
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
  const _DashboardErrorView({
    required this.message,
    required this.onRetry,
    this.actionLabel = 'TRY AGAIN',
  });

  final String message;
  final VoidCallback onRetry;
  final String actionLabel;

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
            context.customerCopy(message),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.customerCopy(actionLabel)),
          ),
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

// Kept as a small reusable detail treatment for future dashboard sections.
// ignore: unused_element
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
      status == 'PENDING_APPROVAL'
          ? lookupAppLocalizations(
              Localizations.localeOf(context),
            ).dashboardPendingApproval
          : context.customerCopy(orderStatusLabel(status)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
      DashboardNoOrders() => const [],
      _ => const [],
    };

String _displayName(String? name) {
  final value = name?.trim();
  return value == null || value.isEmpty ? 'there' : value;
}

String _greeting(BuildContext context) {
  final hour = DateTime.now().hour;
  if (hour < 12) return context.customerCopy('Good morning');
  if (hour < 17) return context.customerCopy('Good afternoon');
  return context.customerCopy('Good evening');
}

String _dashboardSubtitle(
  BuildContext context,
  CustomerDashboardState state,
) => switch (state) {
  DashboardWithMultipleActivePlans(:final activeOrders) =>
    lookupAppLocalizations(
      Localizations.localeOf(context),
    ).customerActivePlans(activeOrders.length),
  DashboardWithActivePlan() => context.customerCopy('Your meal plan is active'),
  DashboardWithoutActivePlan() => context.customerCopy('Ready when you are'),
  DashboardNoOrders() => context.customerCopy('Ready when you are'),
  _ => context.customerCopy('Your meal plans at a glance'),
};

String _period(DateTime? start, DateTime? end, {String? locale}) {
  if (start == null || end == null) return '—';
  final dateLocale = locale == 'en' ? null : locale;
  return '${DateFormat('dd MMM', dateLocale).format(start)} - ${DateFormat('dd MMM', dateLocale).format(end)}';
}

String _weekdays(BuildContext context, List<int> days) {
  final labels = {
    1: context.customerCopy('Mon'),
    2: context.customerCopy('Tue'),
    3: context.customerCopy('Wed'),
    4: context.customerCopy('Thu'),
    5: context.customerCopy('Fri'),
    6: context.customerCopy('Sat'),
    7: context.customerCopy('Sun'),
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

Future<void> _openReviewedOrder(BuildContext context, String id) async {
  await context.push(AppRoutes.orderDetails, extra: id);
  if (context.mounted) {
    await ProviderScope.containerOf(
      context,
    ).read(customerDashboardControllerProvider.notifier).refresh();
  }
}
