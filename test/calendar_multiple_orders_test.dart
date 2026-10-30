import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/dashboard/data/upcoming_meals_repository.dart';
import 'package:diet_time/features/dashboard/domain/calendar_delivery.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/features/dashboard/presentation/upcoming_deliveries_screen.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

OrderConfirmation order(String id, {String status = 'ACTIVE'}) =>
    OrderConfirmation.fromJson({
      'id': id,
      'orderNumber': 'ORD-$id',
      'status': status,
      'paymentStatus': 'PAID',
      'plan': {'name': 'Balance $id', 'durationName': '2 Weeks'},
      'meals': [],
      'delivery': {
        'startDate': '2026-10-28',
        'endDate': '2026-11-10',
        'days': [1, 2, 3, 4, 6, 7],
        'daysPerWeek': 6,
        'timeSlot': {
          'id': 'morning',
          'name': 'Morning',
          'startTime': '07:00',
          'endTime': '11:00',
        },
        'address': {'id': 'address', 'name': 'Home', 'area': 'Doha'},
      },
      'pricing': {'totalAmount': 1000, 'currencyCode': 'QAR'},
    });

class OverlappingRepository extends UpcomingMealsRepository {
  OverlappingRepository() : super(ApiClient(), () async => 'token');
  final dayRequests = <String>[];
  final menuRequests = <DailyMenuRequest>[];
  bool failSecond = false;
  bool historical = false;
  DateTime get date =>
      historical ? DateTime(2026, 10, 28) : DateTime(2030, 10, 28);
  @override
  Future<List<UpcomingMealDay>> getDays(String orderId) async {
    dayRequests.add(orderId);
    if (failSecond && orderId == 'b') {
      throw const ApiException(ApiFailure.network);
    }
    return [
      UpcomingMealDay(
        id: 'day-$orderId',
        date: date,
        status: historical
            ? 'delivered'
            : orderId == 'a'
            ? 'customized'
            : 'auto_selected',
        orderId: orderId,
        mealCount: orderId == 'a' ? 4 : 5,
        snackCount: 1,
        selectionStatus: orderId == 'a'
            ? 'CUSTOMER_CONFIRMED'
            : 'DEFAULT_PENDING',
        selectionLocked: orderId == 'a',
        deliveryStatus: historical ? 'DELIVERED' : 'PLANNED',
      ),
    ];
  }

  @override
  Future<DailyMealMenu> getMenu(DailyMenuRequest request) async {
    menuRequests.add(request);
    final count = request.orderId == 'a' ? 4 : 5;
    return DailyMealMenu(
      dayId: request.dayId,
      orderId: request.orderId,
      date: date,
      mealCount: count,
      snackCount: 1,
      status: historical
          ? 'delivered'
          : request.orderId == 'a'
          ? 'customized'
          : 'auto_selected',
      canEdit: false,
      revision: 1,
      alternatives: [],
      selectionLocked: request.orderId == 'a',
      selected: [
        for (var i = 1; i <= count + 1; i++)
          AssignedDailyMeal(
            id: '${request.orderId}-$i',
            source: 'automatic',
            selectionNumber: i > count ? 1 : i,
            meal: DailyMealItem(
              id: 'dish-${request.orderId}-$i',
              optionId: 'option-$i',
              name: '${i > count ? 'Snack' : 'Meal'} ${request.orderId}-$i',
              category: i > count ? 'snack' : 'meal',
            ),
          ),
      ],
    );
  }
}

void main() {
  for (final historical in [false, true]) {
    testWidgets(
      'dashboard calendar retains both ${historical ? 'completed' : 'active'} orders',
      (tester) async {
        final summaries = [
          for (final id in ['a', 'b'])
            CustomerOrderSummary.fromJson({
              'id': id,
              'orderNumber': 'ORD-$id',
              'planName': 'Balance $id',
              'status': historical ? 'COMPLETED' : 'ACTIVE',
              'startDate': '2026-10-28',
              'endDate': '2026-11-10',
            }),
        ];
        final state = historical
            ? DashboardWithoutActivePlan(summaries)
            : DashboardWithMultipleActivePlans(
                activeOrders: summaries,
                details: {
                  for (final summary in summaries)
                    summary.id: order(summary.id),
                },
                orders: summaries,
              );
        final repository = OverlappingRepository()..historical = true;
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerDashboardControllerProvider.overrideWith(
                () => CalendarDashboard(state),
              ),
              upcomingMealsRepositoryProvider.overrideWithValue(repository),
              ordersRepositoryProvider.overrideWithValue(
                CalendarOrdersRepository(),
              ),
            ],
            child: const MaterialApp(home: CustomerDashboardScreen()),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('dashboardCalendarTab')));
        await tester.pumpAndSettle();
        expect(find.text('2 scheduled deliveries'), findsOneWidget);
        expect(repository.dayRequests, containsAll(['a', 'b']));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  Future<void> show(
    WidgetTester tester,
    OverlappingRepository repository,
    List<OrderConfirmation> orders,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          upcomingMealsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(home: UpcomingDeliveriesScreen(orders: orders)),
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'date grouping retains different orders and excludes cancelled deliveries',
    () {
      final date = DateTime(2026, 10, 28);
      final grouped = deliveriesByDate([
        for (final id in ['a', 'b'])
          CalendarDelivery(
            order: order(id),
            day: UpcomingMealDay(
              id: 'day-$id',
              date: date,
              status: 'auto_selected',
            ),
          ),
        CalendarDelivery(
          order: order('cancelled', status: 'CANCELLED'),
          day: UpcomingMealDay(
            id: 'cancelled',
            date: date,
            status: 'auto_selected',
          ),
        ),
        CalendarDelivery(
          order: order('skipped'),
          day: UpcomingMealDay(
            id: 'skipped',
            date: date,
            status: 'auto_selected',
            deliveryStatus: 'SKIPPED',
          ),
        ),
      ]);
      expect(grouped[date]!.map((d) => d.order.id), ['a', 'b']);
    },
  );

  testWidgets(
    'overlapping four and five meal packages retain every meal, snack and status',
    (tester) async {
      final repository = OverlappingRepository();
      await show(tester, repository, [
        order('a'),
        order('b'),
        order('c', status: 'CANCELLED'),
      ]);
      expect(find.text('2 scheduled deliveries'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('calendarOrder-a-day-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey('deliveryCount-${repository.date.toIso8601String()}'),
        ),
        findsOneWidget,
      );
      expect(find.byType(Badge), findsNothing);
      expect(find.byIcon(Icons.layers_outlined), findsWidgets);
      expect(find.textContaining('4 Meals + 1 Snack'), findsWidgets);
      expect(repository.dayRequests, containsAll(['a', 'b']));
      expect(repository.dayRequests, isNot(contains('c')));
      await tester.scrollUntilVisible(
        find.text('Meal a-4'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Meal a-4'), findsOneWidget);
      expect(find.text('Snack a-5'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Meal b-5'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Meal b-5'), findsOneWidget);
      expect(find.text('Snack b-6'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('calendarOrder-b-day-b')),
        findsOneWidget,
      );
      expect(find.textContaining('5 Meals + 1 Snack'), findsWidgets);
      expect(
        repository.menuRequests.map((r) => '${r.orderId}/${r.dayId}'),
        containsAll(['a/day-a', 'b/day-b']),
      );
      expect(find.text('Change Meal'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'completed subscriptions keep delivered history and separate order cards',
    (tester) async {
      final repository = OverlappingRepository()..historical = true;
      await show(tester, repository, [
        order('a', status: 'COMPLETED'),
        order('b', status: 'COMPLETED'),
      ]);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('2 scheduled deliveries'), findsOneWidget);
      expect(find.textContaining('Delivered'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Meal b-5'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('5 Meals + 1 Snack'), findsWidgets);
      expect(find.text('Change Meal'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('a failed order cannot silently disappear from the calendar', (
    tester,
  ) async {
    final repository = OverlappingRepository()..failSecond = true;
    await show(tester, repository, [order('a'), order('b')]);
    expect(
      find.text('We couldn’t load all your delivery meals.'),
      findsOneWidget,
    );
    expect(find.text('1 scheduled delivery'), findsNothing);
    repository.failSecond = false;
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('2 scheduled deliveries'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

class CalendarDashboard extends CustomerDashboardController {
  CalendarDashboard(this.initial);
  final CustomerDashboardState initial;
  @override
  CustomerDashboardState build() => initial;
  @override
  Future<void> initialize({String? profileId, bool force = false}) async {}
}

class CalendarOrdersRepository extends OrdersRepository {
  CalendarOrdersRepository()
    : super(apiClient: ApiClient(), accessTokenProvider: () async => 'token');
  @override
  Future<OrderConfirmation> getOrder(String id) async =>
      order(id, status: 'COMPLETED');
}
