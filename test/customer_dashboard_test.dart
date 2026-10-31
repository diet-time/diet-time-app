import 'support/ordering_customer.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/app/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_screen.dart';
import 'package:diet_time/features/dashboard/presentation/order_details_screen.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final count in [1, 2]) {
    testWidgets(
      'My Plan works for $count pending plans with one New Plan action',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final orders = [
          for (var i = 0; i < count; i++)
            _reviewSummary('pending-$i', 'PENDING_APPROVAL'),
        ];
        String? selectedId;
        final router = GoRouter(
          initialLocation: AppRoutes.home,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) => const CustomerDashboardScreen(),
            ),
            GoRoute(
              path: AppRoutes.orderDetails,
              builder: (_, state) {
                selectedId = state.extra as String;
                return const Scaffold(body: Text('Selected plan details'));
              },
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerDashboardControllerProvider.overrideWith(
                () => _DashboardControllerForTest(
                  DashboardWithoutActivePlan(orders),
                ),
              ),
              ordersRepositoryProvider.overrideWithValue(
                _FakeOrdersRepository(orders),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('dashboardMyPlan')),
        );
        await tester.pumpAndSettle();
        expect(find.text('ORDER ANOTHER PLAN'), findsNothing);
        expect(find.byKey(const ValueKey('orderAnotherPlan')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('dashboardMyPlan')));
        await tester.pumpAndSettle();
        if (count == 1) {
          expect(selectedId, 'pending-0');
          expect(find.text('Selected plan details'), findsOneWidget);
        } else {
          expect(
            tester
                .widget<NavigationBar>(
                  find.byKey(const ValueKey('dashboardNavigation')),
                )
                .selectedIndex,
            1,
          );
          expect(
            find.byKey(const ValueKey('detailedOrder-pending-0')),
            findsOneWidget,
          );
          expect(find.text('ORD-pending-0'), findsNothing);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'dashboard does not poll while idle and still allows explicit refresh',
    (tester) async {
      final controller = _RecordingDashboardController();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(() => controller),
          ],
          child: const MaterialApp(home: CustomerDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.initializeCalls, 1);
      await tester.pump(const Duration(seconds: 61));
      await tester.pump();
      expect(controller.refreshCalls, 0);
      await controller.refresh();
      expect(controller.refreshCalls, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('order details do not refetch every thirty seconds', (
    tester,
  ) async {
    final repository = _FakeOrdersRepository([
      _reviewSummary('pending', 'PENDING_APPROVAL'),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OrderDetailsScreen(orderId: 'pending'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final calls = repository.getOrderCalls;
    expect(calls, greaterThan(0));
    await tester.pump(const Duration(seconds: 61));
    await tester.pump();
    expect(repository.getOrderCalls, calls);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'plan presentation deduplicates purchases without granting fulfillment',
    () {
      final pending = _reviewSummary('purchase', 'PENDING_APPROVAL');
      final confirmed = _reviewSummary('confirmed', 'CONFIRMED', blocked: true);
      final active = _reviewSummary('active', 'ACTIVE');
      final hold = _reviewSummary('hold', 'ON_HOLD');
      final orders = [
        pending,
        pending,
        confirmed,
        active,
        hold,
        _reviewSummary('rejected', 'REJECTED'),
        _reviewSummary('cancelled', 'CANCELLED'),
        _reviewSummary('completed', 'COMPLETED'),
      ];
      final state = DashboardWithActivePlan(
        order: active,
        detail: _detail(active),
        orders: orders,
      );
      final plans = dashboardPlanOrders(state);
      expect(plans.map((p) => p.id), [
        'active',
        'purchase',
        'confirmed',
        'hold',
      ]);
      expect(pending.isCurrent, isFalse);
      expect(hold.isCurrent, isFalse);
      expect(confirmed.isCurrent, isFalse);
      expect(active.isCurrent, isTrue);
      expect(pending.paymentLabel, 'Unpaid');
      final rejected = CustomerOrderSummary.fromJson({
        'id': active.id,
        'status': 'REJECTED',
        'review': {'rowVersion': 2},
      });
      expect(
        dashboardPlanOrders(
          DashboardWithActivePlan(
            order: active,
            detail: _detail(active),
            orders: [rejected],
          ),
        ).isEmpty,
        isTrue,
      );
    },
  );

  test(
    'rejected orders explain the outcome even when a legacy reason is missing',
    () {
      final rejected = _reviewSummary('declined', 'REJECTED');
      expect(rejected.statusLabel, 'Rejected');
      expect(rejected.reviewMessage, contains('declined by Diet Time'));
      expect(
        _detail(rejected).reviewMessage,
        contains('declined by Diet Time'),
      );
      expect(rejected.isCurrent, isFalse);
    },
  );

  test(
    'refresh reflects staff approval and rejection using the same purchase ID',
    () async {
      final orders = [_reviewSummary('purchase', 'PENDING_APPROVAL')];
      final container = ProviderContainer(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(
            _FakeOrdersRepository(orders),
          ),
          checkoutControllerProvider.overrideWith(_NoopCheckoutController.new),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        customerDashboardControllerProvider.notifier,
      );
      await controller.load('profile');
      expect(
        container.read(customerDashboardControllerProvider),
        isA<DashboardWithoutActivePlan>(),
      );
      expect(
        dashboardPlanOrders(
          container.read(customerDashboardControllerProvider),
        ).single.status,
        'PENDING_APPROVAL',
      );
      orders[0] = _reviewSummary('purchase', 'CONFIRMED');
      await controller.refresh();
      expect(
        container.read(customerDashboardControllerProvider),
        isA<DashboardWithActivePlan>(),
      );
      expect(
        dashboardPlanOrders(
          container.read(customerDashboardControllerProvider),
        ).single.id,
        'purchase',
      );
      orders[0] = _reviewSummary('purchase', 'REJECTED');
      await controller.refresh();
      expect(
        dashboardPlanOrders(
          container.read(customerDashboardControllerProvider),
        ),
        isEmpty,
      );
      expect(
        (container.read(customerDashboardControllerProvider)
                as DashboardWithoutActivePlan)
            .orders
            .single
            .status,
        'REJECTED',
      );
    },
  );

  for (final locale in ['en', 'ar']) {
    testWidgets(
      'pending plan fits narrow $locale dashboard with large text and opens existing details',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final pending = _reviewSummary('pending', 'PENDING_APPROVAL');
        final appRouter = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const CustomerDashboardScreen(),
            ),
            GoRoute(
              path: AppRoutes.orderDetails,
              builder: (_, state) =>
                  OrderDetailsScreen(orderId: state.extra! as String),
            ),
          ],
        );
        addTearDown(appRouter.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerDashboardControllerProvider.overrideWith(
                () => _DashboardControllerForTest(
                  DashboardWithoutActivePlan([pending]),
                ),
              ),
              ordersRepositoryProvider.overrideWithValue(
                _FakeOrdersRepository([pending]),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: appRouter,
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = find.byKey(const ValueKey('activePlan-pending'));
        expect(card, findsOneWidget);
        expect(find.byKey(const ValueKey('noActivePlan')), findsNothing);
        expect(find.byType(ListTile), findsNothing);
        expect(find.byKey(const ValueKey('planPayment-pending')), findsNothing);
        final copy = lookupAppLocalizations(Locale(locale));
        expect(
          find.descendant(
            of: card,
            matching: find.text(copy.dashboardPendingApproval),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: card,
            matching: find.text(copy.dashboardAwaitingConfirmation),
          ),
          findsNothing,
        );
        expect(
          find.descendant(of: card, matching: find.text(pending.orderNumber)),
          findsNothing,
        );
        expect(
          find.descendant(
            of: card,
            matching: find.textContaining(pending.takeawayBranch!.name),
          ),
          findsNothing,
        );
        expect(
          find.descendant(of: card, matching: find.text(pending.paymentLabel)),
          findsNothing,
        );
        expect(tester.widget<Material>(card).color, const Color(0xFF8B642D));
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(const ValueKey('viewOrder-pending')),
        );
        await tester.tap(find.byKey(const ValueKey('viewOrder-pending')));
        await tester.pumpAndSettle();
        expect(find.byType(OrderDetailsScreen), findsOneWidget);
        expect(
          tester
              .widget<OrderDetailsScreen>(find.byType(OrderDetailsScreen))
              .orderId,
          'pending',
        );
        expect(find.text(copy.dashboardPendingApproval), findsOneWidget);
        expect(find.text('ORD-pending'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'pending and active plans share carousel with distinct status and unchanged meal eligibility',
    (tester) async {
      final active = _reviewSummary('active', 'ACTIVE');
      final pending = _reviewSummary('pending', 'PENDING_APPROVAL');
      final controller = _DashboardControllerForTest(
        DashboardWithActivePlan(
          order: active,
          detail: _detail(active),
          orders: [pending, active, pending],
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(() => controller),
          ],
          child: const MaterialApp(home: CustomerDashboardScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('My Plans'), findsOneWidget);
      expect(find.text('2 PLANS'), findsOneWidget);
      final activeCard = find.byKey(const ValueKey('activePlan-active'));
      expect(
        tester.widget<Material>(activeCard).color,
        const Color(0xFF075A43),
      );
      expect(
        find.descendant(of: activeCard, matching: find.text('Active')),
        findsOneWidget,
      );
      await tester.drag(
        find.byKey(const ValueKey('activePlansCarousel')),
        const Offset(-700, 0),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('viewOrder-pending')).hitTestable(),
        findsOneWidget,
      );
      expect(find.byType(ListTile), findsNothing);
      controller.show(
        DashboardWithActivePlan(
          order: active,
          detail: _detail(active),
          orders: [active, _reviewSummary('pending', 'REJECTED')],
        ),
      );
      await tester.pump();
      expect(find.text('1 PLAN'), findsOneWidget);
      expect(find.byKey(const ValueKey('activePlan-pending')), findsNothing);
      expect(find.byKey(const ValueKey('activePlansCarousel')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'approval recolors the same minimal card without changing its dimensions or payment state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final pending = _reviewSummary('purchase', 'PENDING_APPROVAL');
      final controller = _DashboardControllerForTest(
        DashboardWithoutActivePlan([pending]),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(() => controller),
          ],
          child: const MaterialApp(home: CustomerDashboardScreen()),
        ),
      );
      await tester.pump();
      final card = find.byKey(const ValueKey('activePlan-purchase'));
      final originalSize = tester.getSize(card);
      expect(originalSize.height, lessThan(170));
      expect(tester.widget<Material>(card).color, const Color(0xFF8B642D));
      expect(
        find.descendant(of: card, matching: find.text('Pending Approval')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Takeaway')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text(pending.entitlement!.label('en')),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(of: card, matching: find.text(pending.planName)),
            )
            .style
            ?.color,
        Colors.white,
      );
      for (final status in ['CONFIRMED', 'ACTIVE', 'ON_HOLD']) {
        final updated = _reviewSummary('purchase', status);
        controller.show(
          status == 'ON_HOLD'
              ? DashboardWithoutActivePlan([updated])
              : DashboardWithActivePlan(
                  order: updated,
                  detail: _detail(updated),
                  orders: [updated],
                ),
        );
        await tester.pump();
        expect(card, findsOneWidget);
        expect(find.text('1 PLAN'), findsOneWidget);
        expect(tester.getSize(card), originalSize);
        expect(
          tester.widget<Material>(card).color,
          status == 'ON_HOLD'
              ? const Color(0xFF9B503A)
              : const Color(0xFF075A43),
        );
        expect(
          find.descendant(of: card, matching: find.text(updated.statusLabel)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text(updated.orderNumber)),
          findsNothing,
        );
        expect(
          find.descendant(of: card, matching: find.text(updated.paymentLabel)),
          findsNothing,
        );
        expect(
          find.descendant(
            of: card,
            matching: find.textContaining(updated.takeawayBranch!.name),
          ),
          findsNothing,
        );
        expect(updated.paymentStatus, pending.paymentStatus);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'held and confirmed cards use minimal styling and pagination survives rejection',
    (tester) async {
      final active = _reviewSummary('active', 'ACTIVE');
      final confirmed = _reviewSummary('confirmed', 'CONFIRMED', blocked: true);
      final hold = _reviewSummary('hold', 'ON_HOLD');
      final controller = _DashboardControllerForTest(
        DashboardWithActivePlan(
          order: active,
          detail: _detail(active),
          orders: [active, confirmed, hold],
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(() => controller),
          ],
          child: const MaterialApp(home: CustomerDashboardScreen()),
        ),
      );
      await tester.pump();
      final carousel = find.byKey(const ValueKey('activePlansCarousel'));
      await tester.drag(carousel, const Offset(-700, 0));
      await tester.pumpAndSettle();
      final confirmedCard = find.byKey(const ValueKey('activePlan-confirmed'));
      expect(
        tester.widget<Material>(confirmedCard).color,
        const Color(0xFF075A43),
      );
      expect(find.byKey(const ValueKey('planPayment-confirmed')), findsNothing);
      await tester.drag(carousel, const Offset(-700, 0));
      await tester.pumpAndSettle();
      final heldCard = find.byKey(const ValueKey('activePlan-hold'));
      expect(tester.widget<Material>(heldCard).color, const Color(0xFF9B503A));
      expect(
        find.descendant(of: heldCard, matching: find.text('On Hold')),
        findsOneWidget,
      );
      controller.show(
        DashboardWithActivePlan(
          order: active,
          detail: _detail(active),
          orders: [active, confirmed, _reviewSummary('hold', 'REJECTED')],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 PLANS'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('viewOrder-confirmed')).hitTestable(),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('activePlan-hold')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dashboard initialization runs once across widget rebuilds', (
    tester,
  ) async {
    final dashboard = _RecordingDashboardController();
    final container = ProviderContainer(
      overrides: [
        customerDashboardControllerProvider.overrideWith(() => dashboard),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CustomerDashboardScreen()),
      ),
    );
    await tester.pump();
    expect(dashboard.initializeCalls, 1);

    container
        .read(personalizationControllerProvider.notifier)
        .replace(
          const CustomerProfile(
            preferredName: 'Noor',
            profileId: 'late-profile-id',
          ),
        );
    await tester.pump();
    await tester.pump();

    expect(dashboard.initializeCalls, 1);
    expect(find.byKey(const ValueKey('noActivePlan')), findsOneWidget);
  });

  testWidgets('green active-plan dashboard fits a compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final summary = _summary('active', 'ACTIVE', DateTime(2026, 8, 11));
    final detail = _detail(summary);
    final state = DashboardWithActivePlan(
      order: summary,
      detail: detail,
      orders: [summary],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerDashboardControllerProvider.overrideWith(
            () => _DashboardControllerForTest(state),
          ),
        ],
        child: const MaterialApp(home: CustomerDashboardScreen()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('activePlan-active')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('QUICK ACTIONS'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('QUICK ACTIONS'), findsOneWidget);
    expect(find.textContaining('ORDER ANOTHER PLAN'), findsNothing);
    expect(find.byKey(const ValueKey('orderAnotherPlan')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple active plans use a compact swipeable carousel', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final orders = [
      _summary('active', 'ACTIVE', DateTime(2026, 8, 11)),
      _summary('confirmed', 'CONFIRMED', DateTime(2026, 9, 1)),
    ];
    final state = DashboardWithMultipleActivePlans(
      activeOrders: orders,
      details: {for (final order in orders) order.id: _detail(order)},
      orders: orders,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerDashboardControllerProvider.overrideWith(
            () => _DashboardControllerForTest(state),
          ),
        ],
        child: const MaterialApp(home: CustomerDashboardScreen()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('activePlansCarousel')), findsOneWidget);
    expect(find.text('2 PLANS'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('activePlan-active'))).height,
      lessThan(170),
    );
    await tester.drag(
      find.byKey(const ValueKey('activePlansCarousel')),
      const Offset(-330, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('viewOrder-confirmed')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar bottom destination shows active delivery calendar', (
    tester,
  ) async {
    final summary = _summary('active', 'ACTIVE', DateTime(2026, 8, 11));
    final state = DashboardWithActivePlan(
      order: summary,
      detail: _detail(summary),
      orders: [summary],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerDashboardControllerProvider.overrideWith(
            () => _DashboardControllerForTest(state),
          ),
        ],
        child: const MaterialApp(home: CustomerDashboardScreen()),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('dashboardCalendarTab')));
    await tester.pump();

    expect(find.text('Upcoming Meals'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('upcomingDeliveriesScreen')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('dashboardProfileTab')), findsOneWidget);
  });

  testWidgets('structured order details fit a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final summary = _summary('active', 'CONFIRMED', DateTime(2026, 8, 11));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(
            _FakeOrdersRepository([summary]),
          ),
        ],
        child: const MaterialApp(home: OrderDetailsScreen(orderId: 'active')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('orderDetailsHeader')), findsOneWidget);
    expect(find.text('ORDER NUMBER'), findsNothing);
    expect(find.text('ORD-active'), findsNothing);
    expect(find.text('PAYMENT STATUS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('orders tab filters backend orders by status', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final orders = [
      _summary('confirmed', 'CONFIRMED', DateTime(2026, 8, 11)),
      _summary('pending', 'PENDING', DateTime(2026, 8, 15)),
      _summary('cancelled', 'CANCELLED', DateTime(2026, 8, 20)),
    ];
    final state = DashboardWithoutActivePlan(orders);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerDashboardControllerProvider.overrideWith(
            () => _DashboardControllerForTest(state),
          ),
          ordersRepositoryProvider.overrideWithValue(
            _FakeOrdersRepository(orders),
          ),
        ],
        child: const MaterialApp(home: CustomerDashboardScreen()),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('dashboardOrdersTab')));
    await tester.pumpAndSettle();

    expect(find.text('All Orders (3)'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('detailedOrder-confirmed')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Confirmed (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmed (1)'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('detailedOrder-confirmed')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('detailedOrder-pending')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'completed customer with no current orders gets no-active-plan state',
    () async {
      final repository = _FakeOrdersRepository([
        _summary('completed', 'COMPLETED', DateTime(2026, 7, 1)),
      ]);
      final container = ProviderContainer(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(customerDashboardControllerProvider.notifier)
          .load('profile-id');

      final state = container.read(customerDashboardControllerProvider);
      expect(state, isA<DashboardWithoutActivePlan>());
      expect((state as DashboardWithoutActivePlan).orders, hasLength(1));
    },
  );

  test(
    'multiple current plans are retained and sorted by status priority',
    () async {
      final repository = _FakeOrdersRepository([
        _summary('paused', 'PAUSED', DateTime(2026, 9, 1)),
        _summary('confirmed', 'CONFIRMED', DateTime(2026, 8, 20)),
        _summary('active', 'ACTIVE', DateTime(2026, 8, 11)),
        _summary('cancelled', 'CANCELLED', DateTime(2026, 7, 1)),
      ]);
      final container = ProviderContainer(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(customerDashboardControllerProvider.notifier)
          .load('profile-id');

      final state = container.read(customerDashboardControllerProvider);
      expect(state, isA<DashboardWithMultipleActivePlans>());
      final active = (state as DashboardWithMultipleActivePlans).activeOrders;
      expect(active.map((order) => order.status), [
        'ACTIVE',
        'CONFIRMED',
        'PAUSED',
      ]);
      expect(
        state.details.keys,
        containsAll(['active', 'confirmed', 'paused']),
      );
    },
  );

  test('order list parser accepts the backend root items envelope', () async {
    final api = _OrderListApiClient();
    final repository = OrdersRepository(
      apiClient: api,
      accessTokenProvider: () async => 'token',
    );

    final orders = await repository.getCustomerOrders('profile-id');

    expect(orders.single.planName, 'Classic Plan');
    expect(orders.single.status, 'ACTIVE');
    expect(orders.single.totalAmount, 1880);
    expect(api.path, '/api/v1/customer-profiles/profile-id/orders');
    expect(api.queryParameters, {'pageNumber': '1', 'pageSize': '20'});
    expect(api.headers['Authorization'], 'Bearer token');
  });

  test('order list parser accepts a successful top-level empty page', () async {
    final repository = OrdersRepository(
      apiClient: _StaticOrdersApiClient(
        const ApiResponse(
          statusCode: 200,
          body: {'items': [], 'pageNumber': 1, 'pageSize': 20, 'totalCount': 0},
        ),
      ),
      accessTokenProvider: () async => 'token',
    );

    final orders = await repository.getCustomerOrders('profile-id');

    expect(orders, isEmpty);
  });

  test('malformed order page is an API failure, not an empty result', () async {
    final repository = OrdersRepository(
      apiClient: _StaticOrdersApiClient(
        const ApiResponse(
          statusCode: 200,
          body: {
            'data': {'orders': []},
          },
        ),
      ),
      accessTokenProvider: () async => 'token',
    );

    expect(
      repository.getCustomerOrders('profile-id'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.failure,
          'failure',
          ApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('successful empty items response becomes loaded empty state', () async {
    final container = ProviderContainer(
      overrides: [
        ordersRepositoryProvider.overrideWithValue(
          _FakeOrdersRepository(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(customerDashboardControllerProvider.notifier)
        .load('profile-id');

    final state = container.read(customerDashboardControllerProvider);
    expect(state, isA<DashboardNoOrders>());
  });

  test('orders request failure becomes retryable dashboard error', () async {
    final container = ProviderContainer(
      overrides: [
        ordersRepositoryProvider.overrideWithValue(_FailingOrdersRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(customerDashboardControllerProvider.notifier)
        .load('profile-id');

    expect(
      container.read(customerDashboardControllerProvider),
      isA<DashboardError>(),
    );
  });

  test(
    'profile PUT failure cannot block GET-based dashboard loading',
    () async {
      final profileRepository = _GetOnlyProfileRepository();
      final ordersRepository = _CountingOrdersRepository();
      final container = ProviderContainer(
        overrides: [
          otpAuthControllerProvider.overrideWith(OrderingAuth.new),
          customerProfileServiceProvider.overrideWithValue(
            CustomerProfileService(customerRepository: profileRepository),
          ),
          customerProfileRepositoryProvider.overrideWithValue(
            profileRepository,
          ),
          ordersRepositoryProvider.overrideWithValue(ordersRepository),
          checkoutControllerProvider.overrideWith(_NoopCheckoutController.new),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        profileRepository.updateProfile(
          const CustomerProfile(preferredName: 'Noor'),
        ),
        throwsA(isA<CustomerProfileException>()),
      );
      await container
          .read(customerDashboardControllerProvider.notifier)
          .initialize();

      expect(profileRepository.getCalls, 1);
      expect(profileRepository.updateCalls, 1);
      expect(ordersRepository.profileIds, ['profile-from-get']);
      expect(
        container.read(customerDashboardControllerProvider),
        isA<DashboardNoOrders>(),
      );
    },
  );
}

CustomerOrderSummary _summary(String id, String status, DateTime startDate) =>
    CustomerOrderSummary(
      id: id,
      orderNumber: 'ORD-$id',
      planName: '$id plan',
      planDurationName: '1 Month',
      status: status,
      paymentStatus: 'PAID',
      totalAmount: 100,
      currencyCode: 'QAR',
      startDate: startDate,
      endDate: startDate.add(const Duration(days: 20)),
      placedAt: startDate.subtract(const Duration(days: 1)),
    );

OrderConfirmation _detail(CustomerOrderSummary summary) =>
    OrderConfirmation.fromJson({
      'id': summary.id,
      'orderNumber': summary.orderNumber,
      'status': summary.status,
      'paymentStatus': summary.paymentStatus,
      'review': summary.review,
      'mealCount': summary.mealCount,
      'snackCount': summary.snackCount,
      'fulfillmentMethod': summary.fulfillmentMethod,
      'plan': {
        'name': summary.planName,
        'durationName': summary.planDurationName,
      },
      'meals': const [],
      'delivery': {
        'daysPerWeek': 5,
        'days': [1, 2, 3, 4, 5],
        'startDate': summary.startDate?.toIso8601String(),
        'endDate': summary.endDate?.toIso8601String(),
      },
      'pricing': {
        'totalAmount': summary.totalAmount,
        'currencyCode': summary.currencyCode,
      },
      'placedAt': summary.placedAt?.toIso8601String(),
    });

class _FakeOrdersRepository extends OrdersRepository {
  _FakeOrdersRepository(this.orders)
    : super(apiClient: ApiClient(), accessTokenProvider: _noToken);

  final List<CustomerOrderSummary> orders;
  int getOrderCalls = 0;

  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
  }) async => orders;

  @override
  Future<OrderConfirmation> getOrder(String orderId) async {
    getOrderCalls++;
    return _detail(orders.singleWhere((order) => order.id == orderId));
  }
}

class _DashboardControllerForTest extends CustomerDashboardController {
  _DashboardControllerForTest(this.initialState);

  final CustomerDashboardState initialState;

  void show(CustomerDashboardState value) => state = value;

  @override
  CustomerDashboardState build() => initialState;

  @override
  Future<void> initialize({String? profileId, bool force = false}) async {}

  @override
  Future<void> load(String profileId, {bool force = false}) async {}
}

class _RecordingDashboardController extends CustomerDashboardController {
  int initializeCalls = 0;
  int refreshCalls = 0;

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }

  @override
  CustomerDashboardState build() => const DashboardLoading();

  @override
  Future<void> initialize({String? profileId, bool force = false}) async {
    initializeCalls++;
    state = const DashboardWithoutActivePlan([]);
  }
}

class _OrderListApiClient extends ApiClient {
  String? path;
  Map<String, String> queryParameters = const {};
  Map<String, String> headers = const {};

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    this.path = path;
    this.queryParameters = queryParameters;
    this.headers = headers;
    return const ApiResponse(
      statusCode: 200,
      body: {
        'items': [
          {
            'id': 'order-id',
            'orderNumber': 'ORD-1',
            'planName': 'Classic Plan',
            'planDurationName': '1 Month',
            'startDate': '2026-08-11',
            'endDate': '2026-09-05',
            'status': 'ACTIVE',
            'paymentStatus': 'PAID',
            'totalAmount': 1880,
            'currencyCode': 'QAR',
            'placedAt': '2026-08-10T10:00:00Z',
          },
        ],
        'pageNumber': 1,
        'pageSize': 100,
        'totalCount': 1,
      },
    );
  }
}

class _StaticOrdersApiClient extends ApiClient {
  _StaticOrdersApiClient(this.response);

  final ApiResponse response;

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async => response;
}

class _FailingOrdersRepository extends OrdersRepository {
  _FailingOrdersRepository()
    : super(apiClient: ApiClient(), accessTokenProvider: _noToken);

  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
  }) => throw const ApiException(ApiFailure.server, statusCode: 500);
}

class _CountingOrdersRepository extends OrdersRepository {
  _CountingOrdersRepository()
    : super(apiClient: ApiClient(), accessTokenProvider: _noToken);

  final List<String> profileIds = [];

  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
  }) async {
    profileIds.add(profileId);
    return const [];
  }
}

class _GetOnlyProfileRepository implements CustomerProfileRepository {
  int getCalls = 0;
  int updateCalls = 0;

  @override
  Future<CustomerProfile?> getProfile() async {
    getCalls++;
    return const CustomerProfile(
      preferredName: 'Noor',
      genderCode: 'FEMALE',
      dateOfBirth: '1995-03-17',
      heightCm: 165,
      weightKg: 70,
      goalCode: 'LOSE_WEIGHT',
      dailyRoutineCode: 'OFFICE_WORK',
      activityLevelCode: 'MOSTLY_SITTING',
      onboardingStatus: 'COMPLETED',
      nextStepCode: 'PROFILE_COMPLETED',
      shouldShowOnboarding: false,
      profileId: 'profile-from-get',
    );
  }

  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async {
    updateCalls++;
    throw const CustomerProfileException(statusCode: 500);
  }
}

class _NoopCheckoutController extends CheckoutController {
  @override
  CheckoutState build() => const CheckoutState();

  @override
  Future<void> loadAddressesForProfile(String profileId) async {}
}

Future<String?> _noToken() async => null;

CustomerOrderSummary _reviewSummary(
  String id,
  String status, {
  bool blocked = false,
}) => CustomerOrderSummary.fromJson({
  'id': id,
  'orderNumber': 'ORD-$id',
  'planName': 'Balanced plan with a long name for responsive layout',
  'planDurationName': '12 Days',
  'status': status,
  'paymentStatus': 'UNPAID',
  'mealCount': 2,
  'snackCount': 1,
  'fulfillmentMethod': 'TAKEAWAY',
  'takeawayBranch': {
    'id': 'branch',
    'name': 'Diet Time branch with a long name for responsive layout',
  },
  'totalAmount': 750,
  'currencyCode': 'QAR',
  'startDate': '2026-11-01',
  'endDate': '2026-11-14',
  'placedAt': '2026-10-31',
  'review': {
    'canFulfill': !blocked && ['ACTIVE', 'CONFIRMED'].contains(status),
  },
});
