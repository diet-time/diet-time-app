import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_screen.dart';
import 'package:diet_time/features/dashboard/domain/package_management.dart';
import 'package:diet_time/features/dashboard/presentation/package_management_provider.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CustomerOrderSummary plan(
  String state, {
  bool eligible = true,
  bool canFulfill = false,
}) => CustomerOrderSummary.fromJson({
  'id': 'plan',
  'orderNumber': 'ORD-PLAN',
  'planName': 'Complete Balance',
  'status': 'CONFIRMED',
  'paymentStatus': 'PENDING',
  'mealCount': 2,
  'snackCount': 1,
  'startDate': '2026-11-09',
  'endDate': '2026-11-23',
  'review': {'canFulfill': canFulfill, 'requiresPrepayment': true},
  'packageSchedule': {
    'displayStatus': 'CONFIRMED',
    'dashboardStatus': state,
    'dashboardEligible': eligible,
    'dashboardExclusionReason': eligible ? null : 'NO_REMAINING_SERVICE_DAYS',
    'remainingServiceDays': eligible ? 12 : 0,
    'revisedEndDate': '2026-11-23',
    'serverNow': '2026-11-09T00:00:00Z',
    'tomorrowScheduled': false,
    if (state == 'PAUSED' || state == 'PAUSE_SCHEDULED') ...{
      'pauseStartDate': '2026-11-09',
      'resumeDate': '2026-11-16',
    },
  },
});

void main() {
  testWidgets(
    'legacy future plan stays Upcoming when management maps CONFIRMED to ACTIVE',
    (tester) async {
      final order = CustomerOrderSummary.fromJson({
        'id': 'future',
        'orderNumber': 'ORD-FUTURE',
        'planName': 'Balance',
        'status': 'CONFIRMED',
        'paymentStatus': 'PENDING',
        'startDate': '2026-11-10',
        'endDate': '2026-11-23',
        'mealCount': 2,
        'review': {'rowVersion': 1, 'canFulfill': false},
        'packageSchedule': {
          'displayStatus': 'CONFIRMED',
          'remainingServiceDays': 0,
          'revisedEndDate': '2026-11-23',
          'serverNow': '2026-11-09T00:00:00Z',
        },
      });
      final management = PackageManagement.fromJson({
        'rowVersion': 1,
        'serverNow': '2026-11-09T00:00:00Z',
        'status': 'CONFIRMED',
        'remainingServiceDays': 0,
        'expectedEndDate': '2026-11-23',
        'eligiblePauseDates': [],
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(
              () => _Dashboard(
                DashboardSummariesReady(orders: [order], activeOrders: [order]),
              ),
            ),
            packageManagementProvider(
              'future',
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
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.byKey(const ValueKey('noActivePlan')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final state in [
    'ACTIVE',
    'UPCOMING',
    'PAUSED',
    'PAUSE_SCHEDULED',
    'PAUSE_REQUESTED',
  ]) {
    test(
      'approved $state plan remains visible while payment blocks fulfillment',
      () {
        final order = plan(state);
        expect(order.isCurrent, isTrue);
        expect(order.dashboardStatus, state);
        expect(order.canChooseMeals, isFalse);
        expect(order.paymentStatus, 'PENDING');
      },
    );
  }
  test('API exclusion is authoritative even for a literal ACTIVE order', () {
    final order = plan('COMPLETED', eligible: false);
    expect(order.isCurrent, isFalse);
    expect(
      order.packageSchedule!.dashboardExclusionReason,
      'NO_REMAINING_SERVICE_DAYS',
    );
  });
  for (final status in [
    'PENDING_APPROVAL',
    'PENDING',
    'CANCELLED',
    'COMPLETED',
    'REJECTED',
  ]) {
    test(
      'terminal or unapproved $status cannot become a visible subscription',
      () {
        final order = CustomerOrderSummary.fromJson({
          'status': status,
          'review': {'canFulfill': true},
        });
        expect(order.isCurrent, isFalse);
      },
    );
  }
  test('older API confirmed unpaid plans are not hidden by canFulfill', () {
    final order = CustomerOrderSummary.fromJson({
      'status': 'CONFIRMED',
      'review': {'canFulfill': false},
    });
    expect(order.isCurrent, isTrue);
    expect(order.canChooseMeals, isFalse);
  });

  for (final scenario in [
    ('ACTIVE', const Color(0xFF205B46), 'Active'),
    ('UPCOMING', const Color(0xFFDDF1ED), 'Upcoming'),
    ('PAUSED', const Color(0xFFE5E7EB), 'Paused'),
    ('PAUSE_SCHEDULED', const Color(0xFFDCEAF4), 'Pause scheduled'),
  ]) {
    testWidgets(
      'dashboard renders approved unpaid ${scenario.$1} without an empty state',
      (tester) async {
        final order = plan(scenario.$1);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerDashboardControllerProvider.overrideWith(
                () => _Dashboard(
                  DashboardSummariesReady(
                    orders: [order],
                    activeOrders: [order],
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const CustomerDashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = find.byKey(const ValueKey('activePlan-plan'));
        expect(card, findsOneWidget);
        expect(tester.widget<Material>(card).color, scenario.$2);
        expect(
          find.descendant(of: card, matching: find.text(scenario.$3)),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('noActivePlan')), findsNothing);
        expect(find.byKey(const ValueKey('tomorrowDeliveries')), findsNothing);
        expect(
          find.byKey(const ValueKey('dashboardChooseMeals')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  for (final state in <CustomerDashboardState>[
    const DashboardLoading(),
    const DashboardError('Unable to load plans'),
  ]) {
    testWidgets('$state never renders the empty-plan state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(
              () => _Dashboard(state),
            ),
          ],
          child: const MaterialApp(home: CustomerDashboardScreen()),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('noActivePlan')), findsNothing);
      if (state is DashboardError) {
        expect(find.text('Unable to load plans'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}

class _Dashboard extends CustomerDashboardController {
  _Dashboard(this.initial);
  final CustomerDashboardState initial;
  @override
  CustomerDashboardState build() => initial;
  @override
  Future<void> initialize({String? profileId, bool force = false}) async {}
}
