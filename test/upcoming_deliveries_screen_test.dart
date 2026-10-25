import 'dart:async';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/data/upcoming_meals_repository.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/features/dashboard/presentation/upcoming_deliveries_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    _Repository repository, {
    double scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          upcomingMealsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: UpcomingDeliveriesScreen(order: _order()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'existing calendar loads all four saved dishes for selected day',
    (tester) async {
      final repository = _Repository();
      await show(tester, repository);
      expect(find.text('October 2030'), findsOneWidget);
      expect(find.text('Automatically Selected'), findsWidgets);
      expect(
        find.byKey(const ValueKey('assigned-selection-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('assigned-selection-3')),
        findsOneWidget,
      );
      expect(find.text('Chicken day-1'), findsOneWidget);
      expect(find.text('Fruit day-1'), findsOneWidget);
      expect(find.text('Meal 1'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Morning'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Building 126'), findsOneWidget);
      expect(repository.menuRequests, ['day-1']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('one meal can be replaced and saved without reselecting others', (
    tester,
  ) async {
    final repository = _Repository();
    await show(tester, repository);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('assigned-selection-0')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Change Meal').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Meal').first);
    await tester.pumpAndSettle();
    expect(find.text('Save Changes'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('alternative-option-new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('saveMealChanges')));
    await tester.pumpAndSettle();
    expect(repository.replacements, 1);
    expect(repository.selected.first.meal.name, 'Salmon day-1');
    expect(repository.selected.skip(1).map((s) => s.meal.name), [
      'Beef day-1',
      'Vegetables day-1',
      'Fruit day-1',
    ]);
    expect(find.text('Salmon day-1'), findsOneWidget);
    expect(find.text('Customized'), findsWidgets);
    expect(repository.lastRevision, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('switching dates hides old dishes until requested day loads', (
    tester,
  ) async {
    final repository = _Repository()..delayedDay = Completer<DailyMealMenu>();
    await show(tester, repository);
    final next = find.byKey(
      ValueKey('deliveryDate-${DateTime(2030, 10, 28).toIso8601String()}'),
    );
    await tester.tap(next);
    await tester.pump();
    expect(find.text('Chicken day-1'), findsNothing);
    expect(find.byKey(const ValueKey('dailyMenu-day-1')), findsNothing);
    repository.delayedDay!.complete(_menu('day-2'));
    await tester.pumpAndSettle();
    expect(find.text('Chicken day-2'), findsOneWidget);
    expect(repository.menuRequests, ['day-1', 'day-2']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('locked days show meals and cutoff explanation without editing', (
    tester,
  ) async {
    await show(tester, _Repository()..locked = true);
    expect(find.text('Chicken day-1'), findsOneWidget);
    expect(find.text('Change Meal'), findsNothing);
    expect(
      find.text('Your meals are locked for kitchen preparation.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('daily menu failures can be retried on the same selected date', (
    tester,
  ) async {
    final repository = _Repository()..failMenu = true;
    await show(tester, repository);
    final retry = find.text('Retry');
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    repository.failMenu = false;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('Chicken day-1'), findsOneWidget);
    expect(repository.menuRequests, ['day-1', 'day-1']);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('conflict preserves saved choices and asks for refresh', (
    tester,
  ) async {
    final repository = _Repository()..conflict = true;
    await show(tester, repository);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('assigned-selection-0')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Change Meal').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Meal').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('alternative-option-new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('saveMealChanges')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mealSaveError')), findsOneWidget);
    expect(repository.selected.first.meal.name, 'Chicken day-1');
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('saveMealChanges')),
    );
    expect(button.onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('days without assignments show empty state', (tester) async {
    final repository = _Repository()..empty = true;
    await show(tester, repository);
    expect(find.text('No upcoming deliveries are scheduled.'), findsOneWidget);
    expect(repository.menuRequests, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Fridays inside the subscription remain nonselectable', (
    tester,
  ) async {
    await show(tester, _Repository());
    await tester.tap(find.byKey(const ValueKey('nextDeliveryMonth')));
    await tester.pumpAndSettle();
    final friday = tester.widget<InkWell>(
      find.byKey(
        ValueKey('deliveryDate-${DateTime(2030, 11, 1).toIso8601String()}'),
      ),
    );
    expect(friday.onTap, isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('meal cards and change sheet support large accessibility text', (
    tester,
  ) async {
    await show(tester, _Repository(), scale: 2);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('assigned-selection-0')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Change Meal').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Meal').first);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('saveMealChanges')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

class _Repository extends UpcomingMealsRepository {
  _Repository() : super(ApiClient(), () async => 'token');
  bool locked = false, failMenu = false, conflict = false, empty = false;
  int replacements = 0;
  int? lastRevision;
  final menuRequests = <String>[];
  List<AssignedDailyMeal> selected = _menu('day-1').selected;
  Completer<DailyMealMenu>? delayedDay;
  @override
  Future<List<UpcomingMealDay>> getDays(String orderId) async => empty
      ? []
      : [
          UpcomingMealDay(
            id: 'day-1',
            date: DateTime(2030, 10, 27),
            status: locked
                ? 'locked'
                : replacements > 0
                ? 'customized'
                : 'auto_selected',
          ),
          UpcomingMealDay(
            id: 'day-2',
            date: DateTime(2030, 10, 28),
            status: 'auto_selected',
          ),
        ];
  @override
  Future<DailyMealMenu> getMenu(DailyMenuRequest request) async {
    menuRequests.add(request.dayId);
    if (failMenu) throw const ApiException(ApiFailure.network);
    if (request.dayId == 'day-2' && delayedDay != null) {
      return delayedDay!.future;
    }
    return _menu(
      request.dayId,
      locked: locked,
      selected: request.dayId == 'day-1' ? selected : null,
      revision: replacements + 1,
    );
  }

  @override
  Future<DailyMealMenu> replace(
    DailyMenuRequest request,
    AssignedDailyMeal selection,
    DailyMealItem replacement,
    int revision,
  ) async {
    if (conflict) {
      throw const ApiException(ApiFailure.conflict, statusCode: 409);
    }
    replacements++;
    lastRevision = revision;
    selected = [
      for (final s in selected)
        s.id == selection.id
            ? AssignedDailyMeal(id: s.id, source: 'customer', meal: replacement)
            : s,
    ];
    return _menu(request.dayId, selected: selected, revision: revision + 1);
  }
}

DailyMealMenu _menu(
  String dayId, {
  bool locked = false,
  List<AssignedDailyMeal>? selected,
  int revision = 1,
}) => DailyMealMenu(
  dayId: dayId,
  date: DateTime(2030, 10, dayId == 'day-1' ? 27 : 28),
  mealCount: 3,
  snackCount: 1,
  status: locked
      ? 'locked'
      : revision > 1
      ? 'customized'
      : 'auto_selected',
  canEdit: !locked,
  revision: revision,
  cutoffAt: DateTime.utc(2030, 10, 26, 16),
  lockReason: locked ? 'Your meals are locked for kitchen preparation.' : null,
  selected:
      selected ??
      [
        for (var i = 0; i < 4; i++)
          AssignedDailyMeal(
            id: 'selection-$i',
            source: 'automatic',
            meal: DailyMealItem(
              id: 'meal-$i',
              optionId: 'option-$i',
              name: '${['Chicken', 'Beef', 'Vegetables', 'Fruit'][i]} $dayId',
              category: i == 3 ? 'snack' : 'meal',
              calories: 350,
              description: 'Freshly prepared with balanced ingredients.',
            ),
          ),
      ],
  alternatives: [
    DailyMealItem(
      id: 'new',
      optionId: 'option-new',
      name: 'Salmon $dayId',
      category: 'meal',
      calories: 400,
    ),
  ],
);
OrderConfirmation _order() => OrderConfirmation.fromJson({
  'id': 'order-id',
  'orderNumber': 'ORD-1',
  'status': 'ACTIVE',
  'paymentStatus': 'PAID',
  'plan': {'name': 'Complete Balance', 'durationName': '2 Weeks'},
  'meals': [],
  'delivery': {
    'daysPerWeek': 6,
    'days': [1, 2, 3, 4, 6, 7],
    'startDate': '2030-10-27',
    'endDate': '2030-11-09',
    'timeSlot': {
      'id': 'morning',
      'name': 'Morning',
      'startTime': '09:00',
      'endTime': '11:00',
    },
    'address': {
      'id': 'address-id',
      'name': 'Al Wakrah',
      'buildingNo': '126',
      'streetNo': '960',
      'zoneNo': '91',
    },
  },
  'pricing': {'totalAmount': 1299, 'currencyCode': 'QAR'},
});
