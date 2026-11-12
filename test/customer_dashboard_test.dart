import 'support/ordering_customer.dart';
import 'package:diet_time/features/dashboard/domain/package_management.dart';
import 'package:diet_time/features/dashboard/presentation/package_management_panel.dart';
import 'package:diet_time/features/dashboard/presentation/package_management_provider.dart';
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
  for (final scenario in [
    ('CANCELLED', 'PENDING', 'No payment due — Cancelled'),
    ('CANCELLED', 'UNPAID', 'No payment due — Cancelled'),
    ('CANCELLED', 'PAID', 'Paid'),
    ('CANCELLED', 'PARTIALLY_PAID', 'Partially paid — Settlement under review'),
    ('CANCELLED', 'REFUND_PENDING', 'Refund Under Review'),
    ('CANCELLED', 'PARTIALLY_REFUNDED', 'Partially Refunded'),
    ('CANCELLED', 'REFUNDED', 'Refunded'),
    ('REJECTED', 'PENDING', 'No payment due — Rejected'),
    ('PENDING_APPROVAL', 'PENDING', 'Payment Pending'),
    ('CONFIRMED', 'UNPAID', 'Unpaid'),
    ('CONFIRMED', 'PAID', 'Paid'),
  ]) {
    testWidgets(
      'order and payment states stay separate: ${scenario.$1} ${scenario.$2}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final summary = CustomerOrderSummary.fromJson({
          'id': 'status-test',
          'orderNumber': 'ORD-status-test',
          'status': scenario.$1,
          'paymentStatus': scenario.$2,
          'mealCount': 2,
          'snackCount': 1,
          'review': {'awaitingPayment': true},
        });
        expect(summary.paymentLabel, scenario.$3);
        final detail = _detail(summary);
        expect(detail.paymentLabel, summary.paymentLabel);
        expect(detail.paymentStatus, scenario.$2);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              orderDetailsProvider(
                summary.id,
              ).overrideWith((ref) async => detail),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: OrderDetailsScreen(orderId: summary.id),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(scenario.$3),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(scenario.$3), findsOneWidget);
        expect(
          find.byKey(const ValueKey('orderConfirmationCard')),
          findsNothing,
        );
        expect(find.text('Thank you for your order!'), findsNothing);
        expect(
          find.text('Your plan and delivery schedule are confirmed above.'),
          findsNothing,
        );
        if (scenario.$1 == 'CANCELLED') {
          expect(
            find.text(
              'This order has been cancelled. No further deliveries are scheduled.',
            ),
            findsOneWidget,
          );
          expect(detail.reviewMessage, isNull);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'Quick Actions are removed and header support preserves its existing action',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final active = _reviewSummary('choose', 'ACTIVE');
      final repository = _FakeOrdersRepository([active]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(
              () => _DashboardControllerForTest(
                DashboardWithActivePlan(
                  order: active,
                  detail: _detail(active),
                  orders: [active],
                ),
              ),
            ),
            ordersRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: CustomerDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('QUICK ACTIONS'), findsNothing);
      expect(find.byKey(const ValueKey('dashboardOrdersAction')), findsNothing);
      expect(find.byKey(const ValueKey('dashboardChooseMeals')), findsNothing);
      expect(find.byKey(const ValueKey('orderAnotherPlan')), findsNothing);
      expect(find.byKey(const ValueKey('dashboardAddPlan')), findsOneWidget);
      final support = find.byKey(const ValueKey('dashboardSupportButton'));
      expect(tester.widget<IconButton>(support).tooltip, 'Support');
      expect(tester.getSize(support).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(support).height, greaterThanOrEqualTo(48));
      expect(
        tester.getRect(support).left,
        greaterThan(
          tester
              .getRect(find.byKey(const ValueKey('dashboardMenuButton')))
              .right,
        ),
      );
      await tester.tap(support);
      await tester.pumpAndSettle();
      expect(find.text('Support will be available soon.'), findsOneWidget);
      expect(find.text('MY ORDERS'), findsNothing);
      expect(find.text('PREVIOUS ORDERS'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('dashboardOrdersTab')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NavigationBar>(
              find.byKey(const ValueKey('dashboardNavigation')),
            )
            .selectedIndex,
        1,
      );
      expect(repository.getOrderCalls, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final pauseStatus in [
    'PAUSED',
    'SCHEDULED',
    'PAUSE_PENDING',
    'RESUME_PENDING',
  ]) {
    testWidgets(
      'dashboard shows $pauseStatus in the plan card without pause controls',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final summary = CustomerOrderSummary.fromJson({
          'id': 'paused-plan',
          'orderNumber': 'ORD-PAUSED',
          'planName': 'Balance',
          'planDurationName': '12 days',
          'status': 'CONFIRMED',
          'paymentStatus': 'PAID',
          'totalAmount': 100,
          'currencyCode': 'QAR',
          'startDate': '2026-11-03',
          'endDate': '2026-11-20',
          'placedAt': '2026-11-02',
          'review': {'rowVersion': 1, 'canFulfill': true},
        });
        final management = PackageManagement.fromJson({
          'rowVersion': 2,
          'serverNow': pauseStatus == 'PAUSED'
              ? '2026-11-04T12:00:00Z'
              : '2026-11-02T12:00:00Z',
          'status': pauseStatus.endsWith('_PENDING')
              ? 'CONFIRMED'
              : pauseStatus,
          'remainingServiceDays': 8,
          'expectedEndDate': pauseStatus == 'PAUSE_PENDING'
              ? '2026-11-20'
              : '2026-12-20',
          'firstDeliveryAfterPause': '2026-12-05',
          'eligiblePauseDates': [],
          'canResumeEarly': true,
          'latestRequest': pauseStatus.endsWith('_PENDING')
              ? {
                  'id': 'request',
                  'type': pauseStatus == 'PAUSE_PENDING' ? 'PAUSE' : 'RESUME',
                  'status': 'PENDING_APPROVAL',
                  'pauseStartDate': '2026-11-03',
                  'resumeDate': '2026-12-03',
                }
              : null,
          'currentPause': pauseStatus == 'PAUSE_PENDING'
              ? null
              : {
                  'id': 'pause',
                  'pauseStartDate': '2026-11-03',
                  'resumeDate': '2026-12-03',
                  'status': pauseStatus,
                },
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerDashboardControllerProvider.overrideWith(
                () => _DashboardControllerForTest(
                  DashboardWithActivePlan(
                    order: summary,
                    detail: _detail(summary),
                    orders: [summary],
                  ),
                ),
              ),
              ordersRepositoryProvider.overrideWithValue(
                _FakeOrdersRepository([summary]),
              ),
              packageManagementProvider(
                summary.id,
              ).overrideWith((ref) async => management),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const CustomerDashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
        final card = find.byKey(const ValueKey('activePlan-paused-plan'));
        expect(
          tester.widget<Material>(card).color,
          pauseStatus == 'PAUSED'
              ? const Color(0xFFE8EEF4)
              : pauseStatus == 'PAUSE_PENDING'
              ? const Color(0xFFFFF0E8)
              : const Color(0xFFE8EEF4),
        );
        expect(
          find.descendant(
            of: card,
            matching: find.text(
              pauseStatus == 'PAUSE_PENDING'
                  ? 'Requested pause start: Nov 3, 2026\nAwaiting Diet Time confirmation'
                  : pauseStatus == 'PAUSED'
                  ? 'Resume on: Dec 3, 2026'
                  : 'Pause start date: Nov 3, 2026\nResume on: Dec 3, 2026',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: card,
            matching: find.text(switch (pauseStatus) {
              'PAUSE_PENDING' => 'Pause requested',
              'RESUME_PENDING' => 'Resume pending confirmation',
              'PAUSED' => 'Paused',
              _ => 'Pause scheduled',
            }),
          ),
          findsOneWidget,
        );
        expect(find.byType(PackageManagementPanel), findsNothing);
        if (pauseStatus == 'PAUSED') {
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('dashboardAddPlan')),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(
            find.byKey(const ValueKey('dashboardChooseMeals')),
            findsNothing,
          );
          expect(find.byKey(const ValueKey('orderAnotherPlan')), findsNothing);
        }
        expect(
          find.byKey(const ValueKey('pausePackage-paused-plan')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  for (final language in ['en', 'ar']) {
    for (final width in [320.0, 800.0]) {
      testWidgets(
        'Home omits history while Orders remains available: $language $width',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 1100));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final order = _reviewSummary('alignment', 'PENDING_APPROVAL');
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                customerDashboardControllerProvider.overrideWith(
                  () => _DashboardControllerForTest(
                    DashboardWithoutActivePlan([order]),
                  ),
                ),
                ordersRepositoryProvider.overrideWithValue(
                  _FakeOrdersRepository([order]),
                ),
              ],
              child: MaterialApp(
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const CustomerDashboardScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('order-alignment')), findsNothing);
          expect(find.text('MY ORDERS'), findsNothing);
          expect(find.text('PREVIOUS ORDERS'), findsNothing);
          if (width >= 800) {
            await tester.tap(find.byKey(const ValueKey('dashboardOrdersTab')));
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('detailedOrder-alignment')),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  for (final count in [1, 2]) {
    testWidgets('pending orders use canonical Orders navigation: $count', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final orders = [
        for (var i = 0; i < count; i++)
          _reviewSummary('pending-$i', 'PENDING_APPROVAL'),
      ];
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
          child: const MaterialApp(home: CustomerDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dashboardMyPlan')), findsNothing);
      expect(find.byKey(const ValueKey('dashboardChooseMeals')), findsNothing);
      expect(find.byKey(const ValueKey('orderAnotherPlan')), findsNothing);
      expect(find.byKey(const ValueKey('dashboardAddPlan')), findsOneWidget);
      expect(find.byKey(const ValueKey('noActivePlan')), findsNothing);
      expect(find.byKey(const ValueKey('pendingPlanMessage')), findsNothing);
      expect(find.byKey(const ValueKey('dashboardPlanCount')), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('dashboardOrdersTab')),
      );
      await tester.tap(find.byKey(const ValueKey('dashboardOrdersTab')));
      await tester.pumpAndSettle();
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
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
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
  testWidgets(
    'pending orders refresh in the foreground without changing tabs',
    (tester) async {
      final controller = _RecordingDashboardController(
        orders: [_reviewSummary('pending', 'PENDING_APPROVAL')],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(() => controller),
          ],
          child: const MaterialApp(home: CustomerDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.refreshCalls, 0);
      await tester.pump(const Duration(minutes: 1));
      await tester.pump();
      expect(controller.refreshCalls, 1);
      expect(find.byKey(const ValueKey('noActivePlan')), findsNothing);
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
      expect(plans.map((p) => p.id), ['active', 'confirmed', 'purchase']);
      expect(pending.isCurrent, isFalse);
      expect(hold.isCurrent, isFalse);
      expect(confirmed.isCurrent, isTrue);
      expect(confirmed.canChooseMeals, isFalse);
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
        ),
        isNotEmpty,
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
      'pending plan opens its order details on a compact $locale dashboard',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final pending = _reviewSummary('pending', 'PENDING_APPROVAL');
        final router = GoRouter(
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
        addTearDown(router.dispose);
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
              routerConfig: router,
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
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
        expect(
          find.byKey(const ValueKey('activePlan-pending')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('noActivePlan')), findsNothing);
        expect(find.byKey(const ValueKey('tomorrowDeliveries')), findsNothing);
        final row = find.byKey(const ValueKey('viewOrder-pending'));
        await tester.scrollUntilVisible(
          row,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<OrderDetailsScreen>(find.byType(OrderDetailsScreen))
              .orderId,
          'pending',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'only eligible subscriptions appear in the active plan carousel',
    (tester) async {
      final active = _reviewSummary('active', 'ACTIVE');
      final pending = _reviewSummary('pending', 'PENDING_APPROVAL');
      final cancelled = _reviewSummary('cancelled', 'CANCELLED');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(
              () => _DashboardControllerForTest(
                DashboardWithActivePlan(
                  order: active,
                  detail: _detail(active),
                  orders: [pending, cancelled, active, pending],
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: CustomerDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('dashboardPlanCount')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('activePlan-active')), findsOneWidget);
      expect(find.byKey(const ValueKey('activePlan-pending')), findsOneWidget);
      expect(find.byKey(const ValueKey('activePlan-cancelled')), findsNothing);
      expect(find.byKey(const ValueKey('activePlansCarousel')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'approval adds an active card and rejection removes it without changing history',
    (tester) async {
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
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('noActivePlan')), findsNothing);
      expect(find.byKey(const ValueKey('activePlan-purchase')), findsOneWidget);
      for (final status in ['CONFIRMED', 'ACTIVE']) {
        final updated = _reviewSummary('purchase', status);
        controller.show(
          DashboardWithActivePlan(
            order: updated,
            detail: _detail(updated),
            orders: [updated],
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('activePlan-purchase')),
          findsOneWidget,
        );
        expect(updated.paymentStatus, pending.paymentStatus);
      }
      controller.show(
        DashboardWithoutActivePlan([_reviewSummary('purchase', 'REJECTED')]),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('activePlan-purchase')), findsNothing);
      expect(find.byKey(const ValueKey('noActivePlan')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'held orders stay in history while approved unpaid plans remain visible',
    (tester) async {
      final orders = [
        _reviewSummary('hold', 'ON_HOLD'),
        _reviewSummary('confirmed', 'CONFIRMED', blocked: true),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(
              () => _DashboardControllerForTest(
                DashboardWithoutActivePlan(orders),
              ),
            ),
          ],
          child: const MaterialApp(home: CustomerDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('noActivePlan')), findsNothing);
      expect(find.byKey(const ValueKey('activePlan-hold')), findsNothing);
      expect(
        find.byKey(const ValueKey('activePlan-confirmed')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('dashboardChooseMeals')), findsNothing);
      expect(find.byKey(const ValueKey('tomorrowDeliveries')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
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
    expect(find.text('QUICK ACTIONS'), findsNothing);
    expect(find.textContaining('ORDER ANOTHER PLAN'), findsNothing);
    expect(find.byKey(const ValueKey('orderAnotherPlan')), findsNothing);
    expect(find.byKey(const ValueKey('dashboardAddPlan')), findsOneWidget);
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
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('dashboardPlanCount')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
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

    expect(find.text('Your Meal Calendar'), findsOneWidget);
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
    bool dashboard = false,
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
  _RecordingDashboardController({this.orders = const []});
  final List<CustomerOrderSummary> orders;
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
    state = DashboardWithoutActivePlan(orders);
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
    bool dashboard = false,
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
    bool dashboard = false,
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
