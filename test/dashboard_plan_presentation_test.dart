import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_theme.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/domain/package_management.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_screen.dart';
import 'package:diet_time/features/dashboard/presentation/dashboard_plan_status_colors.dart';
import 'package:diet_time/features/dashboard/presentation/package_management_provider.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

CustomerOrderSummary plan(String id, String status, {bool live = false}) =>
    CustomerOrderSummary.fromJson({
      'id': id,
      'orderNumber': 'ORD-$id',
      'planName': 'Complete Balance',
      'status': status == 'PENDING_APPROVAL' ? status : 'ACTIVE',
      'paymentStatus': 'PAID',
      'mealCount': 1,
      'snackCount': 1,
      'startDate': status == 'UPCOMING' ? '2026-11-20' : '2026-11-09',
      'endDate': '2026-11-30',
      'review': {'canFulfill': false, 'rowVersion': live ? 1 : 0},
      'packageSchedule': {
        'displayStatus': status,
        'dashboardStatus': status,
        'dashboardEligible': status != 'PENDING_APPROVAL',
        'remainingServiceDays': 12,
        'revisedEndDate': '2026-11-30',
        'serverNow': '2026-11-10T09:00:00Z',
        'nextScheduledDelivery': '2026-11-11',
        if (const {
          'PAUSE_REQUESTED',
          'PAUSE_SCHEDULED',
          'PAUSED',
        }.contains(status)) ...{
          'pauseStartDate': '2026-11-12',
          'resumeDate': '2026-11-16',
        },
      },
    });

class Dashboard extends CustomerDashboardController {
  Dashboard(this.orders);
  final List<CustomerOrderSummary> orders;
  @override
  CustomerDashboardState build() => DashboardSummariesReady(
    orders: orders,
    activeOrders: orders.where((o) => o.isCurrent).toList(),
  );
  @override
  Future<void> initialize({String? profileId, bool force = false}) async {}
  @override
  Future<void> refresh() async {}
}

void main() {
  const statuses = [
    'ACTIVE',
    'PAUSE_REQUESTED',
    'PAUSE_SCHEDULED',
    'PAUSED',
    'UPCOMING',
    'PENDING_APPROVAL',
  ];
  CustomerOrderSummary terminal(String status) => CustomerOrderSummary.fromJson(
    {'id': status, 'orderNumber': 'ORD-$status', 'status': status},
  );
  final noPlansCases = <String, List<CustomerOrderSummary>>{
    'no subscriptions': [],
    'cancelled only': [terminal('CANCELLED')],
    'rejected only': [terminal('REJECTED')],
    'completed only': [terminal('COMPLETED')],
    'all terminal statuses': [
      terminal('CANCELLED'),
      terminal('REJECTED'),
      terminal('COMPLETED'),
    ],
    'API excludes the remaining subscription': [
      CustomerOrderSummary.fromJson({
        'id': 'exhausted',
        'orderNumber': 'ORD-EXHAUSTED',
        'status': 'ACTIVE',
        'packageSchedule': {
          'displayStatus': 'COMPLETED',
          'dashboardStatus': 'COMPLETED',
          'dashboardEligible': false,
          'remainingServiceDays': 0,
          'revisedEndDate': '2026-11-09',
          'serverNow': '2026-11-10T09:00:00Z',
        },
      }),
    ],
  };
  for (final scenario in noPlansCases.entries) {
    for (final language in ['en', 'ar']) {
      testWidgets(
        'no-plan card for ${scenario.key} preserves controls and opens existing selection ($language)',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final router = GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const CustomerDashboardScreen(),
              ),
              GoRoute(
                path: AppRoutes.startPlan,
                builder: (_, _) =>
                    const Scaffold(body: Text('Existing plan selection')),
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                customerDashboardControllerProvider.overrideWith(
                  () => Dashboard(scenario.value),
                ),
              ],
              child: MaterialApp.router(
                routerConfig: router,
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.3)),
                  child: child!,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final copy = lookupAppLocalizations(Locale(language));
          final empty = find.byKey(const ValueKey('noActivePlan'));
          expect(empty, findsOneWidget);
          expect(tester.getRect(empty).center.dx, closeTo(160, .1));
          expect(find.text(copy.dashboardNoPlansTitle), findsOneWidget);
          expect(find.text(copy.dashboardNoPlansDescription), findsOneWidget);
          expect(find.text(copy.dashboardExploreMealPlans), findsOneWidget);
          if (language == 'en') {
            expect(find.text('Ready to eat healthier?'), findsOneWidget);
            expect(
              find.text(
                'Explore our freshly prepared meal plans and find the perfect fit for your lifestyle.',
              ),
              findsOneWidget,
            );
            expect(find.text('Explore Meal Plans'), findsOneWidget);
          }
          expect(find.text(copy.dashboardMyPlans), findsNothing);
          for (final key in [
            'activePlansCarousel',
            'dashboardAddPlan',
            'tomorrowDeliveries',
            'dashboardOrdersAction',
            'orderAnotherPlan',
          ]) {
            expect(find.byKey(ValueKey(key)), findsNothing);
          }
          expect(find.text('QUICK ACTIONS'), findsNothing);
          expect(find.text('MY ORDERS'), findsNothing);
          for (final key in [
            'dashboardMenuButton',
            'dashboardSupportButton',
            'dashboardLanguageSelector',
            'dashboardHomeTab',
            'dashboardOrdersTab',
            'dashboardCalendarTab',
            'dashboardProfileTab',
          ]) {
            expect(find.byKey(ValueKey(key)), findsOneWidget);
          }
          final button = find.byKey(const ValueKey('choosePlan'));
          expect(
            tester
                .widget<FilledButton>(button)
                .style!
                .backgroundColor!
                .resolve({}),
            const Color(0xFF17352D),
          );
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(find.text('Existing plan selection'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  const palette = [
    ('ACTIVE', 0xFF205B46, 0xFFFFFFFF),
    ('UPCOMING', 0xFFDDF1ED, 0xFF176B62),
    ('PENDING_APPROVAL', 0xFFFFF0D5, 0xFF8A601E),
    ('PAUSE_REQUESTED', 0xFFFFF0D5, 0xFF8A601E),
    ('PAUSE_SCHEDULED', 0xFFDCEAF4, 0xFF285A7A),
    ('PAUSED', 0xFFE5E7EB, 0xFF475569),
    ('CANCELLED', 0xFFF5E6E8, 0xFFA34452),
  ];
  for (final (status, background, foreground) in palette) {
    test('specified dashboard palette for $status', () {
      final colors = dashboardPlanStatusColors(status);
      expect(colors.background, Color(background));
      expect(colors.foreground, Color(foreground));
    });
    if (status == 'CANCELLED') continue;
    testWidgets('$status card and badge share the specified palette', (
      tester,
    ) async {
      final order = plan('plan', status);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(
              () => Dashboard([order]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(const Locale('en')),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CustomerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('activePlan-plan'));
      expect(find.byKey(const ValueKey('noActivePlan')), findsNothing);
      expect(find.byKey(const ValueKey('dashboardAddPlan')), findsOneWidget);
      final addPlan = find.byKey(const ValueKey('dashboardAddPlan'));
      final button = tester.widget<TextButton>(addPlan);
      expect(
        button.style!.backgroundColor!.resolve({}),
        const Color(0xFF00674E),
      );
      expect(button.style!.foregroundColor!.resolve({}), Colors.white);
      expect(button.style!.shape!.resolve({}), isA<StadiumBorder>());
      const child = SizedBox();
      expect(
        button.style!.backgroundBuilder!(tester.element(addPlan), {}, child),
        same(child),
      );
      expect(tester.widget<Material>(card).color, Color(background));
      final badge = find.byKey(const ValueKey('planStatus-plan'));
      expect(
        (tester.widget<Container>(badge).decoration! as BoxDecoration).color,
        Color(background),
      );
      final texts = tester.widgetList<Text>(
        find.descendant(of: badge, matching: find.byType(Text)),
      );
      expect(texts.single.style!.color, Color(foreground));
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: card,
                matching: find.text('Complete Balance'),
              ),
            )
            .style!
            .color,
        Color(foreground),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  test('all eligible statuses are unique and sorted within My Plans only', () {
    final orders = [
      for (final status in statuses.reversed) plan(status, status),
    ];
    final state = DashboardSummariesReady(
      orders: [...orders, ...orders],
      activeOrders: orders,
    );
    expect(dashboardPlanOrders(state).map((o) => o.id), statuses);
    expect(dashboardPlanOrders(state).map((o) => o.id).toSet(), hasLength(6));
  });

  for (final language in ['en', 'ar']) {
    testWidgets(
      'same-name plans retain count, card dimensions, ordering and detail destinations ($language)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final orders = [
          plan('paused', 'PAUSED'),
          plan('requested', 'PAUSE_REQUESTED'),
          plan('active', 'ACTIVE'),
        ];
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const CustomerDashboardScreen(),
            ),
            GoRoute(
              path: AppRoutes.orderDetails,
              builder: (_, state) =>
                  Scaffold(body: Text('Details ${state.extra}')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerDashboardControllerProvider.overrideWith(
                () => Dashboard([...orders, orders.first]),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final copy = lookupAppLocalizations(Locale(language));
        final count = find.byKey(const ValueKey('dashboardPlanCount'));
        expect(
          find.descendant(of: count, matching: find.text('3')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<Semantics>(
                find
                    .ancestor(of: count, matching: find.byType(Semantics))
                    .first,
              )
              .properties
              .label,
          copy.dashboardPlanCount(3),
        );
        final addPlan = find.byKey(const ValueKey('dashboardAddPlan'));
        if (language == 'en') {
          expect(
            tester.getRect(count).right,
            lessThan(tester.getRect(addPlan).left),
          );
        } else {
          expect(
            tester.getRect(count).left,
            greaterThan(tester.getRect(addPlan).right),
          );
        }
        expect(
          find.byKey(const ValueKey('dashboardChooseMeals')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('pendingPlanMessage')), findsNothing);
        Size? size;
        final carousel = find.byKey(const ValueKey('activePlansCarousel'));
        for (final id in ['active', 'requested', 'paused']) {
          final card = find.byKey(ValueKey('activePlan-$id'));
          expect(card.hitTestable(), findsOneWidget);
          size ??= tester.getSize(card);
          expect(tester.getSize(card), size);
          await tester.tap(find.byKey(ValueKey('viewOrder-$id')));
          await tester.pumpAndSettle();
          expect(find.text('Details $id'), findsOneWidget);
          router.pop();
          await tester.pumpAndSettle();
          if (id != 'paused') {
            await tester.drag(
              carousel,
              Offset(language == 'ar' ? 290 : -290, 0),
            );
            await tester.pumpAndSettle();
          }
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'live Qatar pause lifecycle overrides an older dashboard snapshot',
    (tester) async {
      final order = plan('live', 'PAUSE_REQUESTED', live: true);
      PackageManagement data(String phase) => PackageManagement.fromJson({
        'rowVersion': 2,
        'status': 'ACTIVE',
        'remainingServiceDays': 12,
        'serverNow': phase == 'PAUSED'
            ? '2026-11-12T09:00:00Z'
            : phase == 'ACTIVE'
            ? '2026-11-16T09:00:00Z'
            : '2026-11-10T09:00:00Z',
        'expectedEndDate': '2026-11-30',
        'eligiblePauseDates': [],
        if (phase == 'PAUSE_REQUESTED')
          'latestRequest': {
            'id': 'request',
            'type': 'PAUSE',
            'status': 'PENDING_APPROVAL',
            'pauseStartDate': '2026-11-12',
            'resumeDate': '2026-11-16',
          }
        else
          'currentPause': {
            'id': 'pause',
            'pauseStartDate': '2026-11-12',
            'resumeDate': '2026-11-16',
            'status': 'CONFIRMED',
          },
      });
      var management = data('PAUSE_REQUESTED');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(
              () => Dashboard([order]),
            ),
            packageManagementProvider(
              order.id,
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
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CustomerDashboardScreen)),
      );
      for (final (phase, label) in [
        ('PAUSE_REQUESTED', 'Pause requested'),
        ('PAUSE_SCHEDULED', 'Pause scheduled'),
        ('PAUSED', 'Paused'),
        ('ACTIVE', 'Active'),
      ]) {
        management = data(phase);
        container.invalidate(packageManagementProvider(order.id));
        await tester.pumpAndSettle();
        final card = find.byKey(ValueKey('activePlan-${order.id}'));
        expect(
          find.descendant(of: card, matching: find.text(label)),
          findsOneWidget,
        );
        expect(
          tester.widget<Material>(card).color,
          dashboardPlanStatusColors(phase).background,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
