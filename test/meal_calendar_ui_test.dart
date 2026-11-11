import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/dashboard/data/tomorrow_menu_repository.dart';
import 'package:diet_time/features/dashboard/data/upcoming_meals_repository.dart';
import 'package:diet_time/features/dashboard/domain/tomorrow_menu.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/features/dashboard/presentation/calendar_meal_status.dart';
import 'package:diet_time/features/dashboard/presentation/upcoming_deliveries_screen.dart';
import 'package:diet_time/features/menu/domain/meal_nutrition.dart';
import 'package:diet_time/features/menu/presentation/meal_detail_viewer.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'calendar_multiple_orders_test.dart' as fixtures;

class CalendarRepository extends UpcomingMealsRepository {
  CalendarRepository(
    this.count, {
    this.tomorrow = false,
    this.completeNutrition = true,
  }) : super(ApiClient(), () async => 'token');
  final int count;
  final bool tomorrow, completeNutrition;
  bool confirmed = false;
  final requests = <String>[];
  DateTime get date {
    final qatar = DateTime.now().toUtc().add(const Duration(hours: 3));
    return tomorrow
        ? DateTime(qatar.year, qatar.month, qatar.day + 1)
        : DateTime(2030, 10, 28);
  }

  DateTime get cutoff => DateTime.now().toUtc().add(const Duration(hours: 2));

  @override
  Future<List<UpcomingMealDay>> getDays(String orderId) async => [
    UpcomingMealDay(
      id: 'day',
      orderId: orderId,
      date: date,
      status: 'auto_selected',
      canEdit: tomorrow && !confirmed,
      cutoffAt: tomorrow ? cutoff : null,
      selectionStatus: confirmed ? 'CUSTOMER_CONFIRMED' : 'DEFAULT_PENDING',
    ),
    UpcomingMealDay(
      id: 'next',
      orderId: orderId,
      date: date.add(const Duration(days: 1)),
      status: 'auto_selected',
    ),
    UpcomingMealDay(
      id: 'paused',
      orderId: orderId,
      date: date.add(const Duration(days: 2)),
      status: 'locked',
      deliveryStatus: 'PAUSED',
    ),
  ];

  @override
  Future<DailyMealMenu> getMenu(DailyMenuRequest request) async {
    requests.add(request.dayId);
    return DailyMealMenu(
      dayId: request.dayId,
      orderId: request.orderId,
      date: request.dayId == 'next' ? date.add(const Duration(days: 1)) : date,
      mealCount: count,
      snackCount: 1,
      status: 'auto_selected',
      canEdit: tomorrow && !confirmed,
      selectionLocked: confirmed,
      selectionStatus: confirmed ? 'CUSTOMER_CONFIRMED' : 'DEFAULT_PENDING',
      revision: 1,
      cutoffAt: tomorrow ? cutoff : null,
      alternatives: const [],
      selected: [
        for (var i = 0; i <= count; i++)
          AssignedDailyMeal(
            id: '${request.dayId}-$i',
            source: 'automatic',
            meal: DailyMealItem(
              id: 'meal-$i',
              optionId: 'option-$i',
              name: i == count ? 'Fruit snack' : 'Healthy meal ${i + 1}',
              category: i == count ? 'snack' : 'meal',
              nutrition: completeNutrition
                  ? const MealNutrition(
                      calories: 100,
                      protein: 5,
                      carbs: 10,
                      fat: 4,
                    )
                  : const MealNutrition(calories: 100),
            ),
          ),
      ],
    );
  }
}

Future<void> showCalendar(
  WidgetTester tester,
  CalendarRepository repository, {
  String language = 'en',
  TomorrowMenuRepository? reviewRepository,
}) async {
  await tester.binding.setSurfaceSize(const Size(320, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        upcomingMealsRepositoryProvider.overrideWithValue(repository),
        if (reviewRepository != null)
          tomorrowMenuRepositoryProvider.overrideWithValue(reviewRepository),
      ],
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UpcomingDeliveriesScreen(order: fixtures.order('a')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('calendarOrder-a-day')),
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('tourDailyNutrition')),
    -200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

class ReviewRepository extends TomorrowMenuRepository {
  ReviewRepository(this.calendar) : super(ApiClient(), () async => 'token');
  final CalendarRepository calendar;
  int confirmations = 0;
  @override
  Future<TomorrowMenu> get(String orderId, String language) async {
    final daily = await calendar.getMenu((
      orderId: orderId,
      dayId: 'day',
      language: language,
    ));
    final items = daily.selected.map((s) => s.meal).toList();
    return TomorrowMenu(
      subscriptionId: orderId,
      dayId: 'day',
      deliveryDate: calendar.date,
      planName: 'Balance a',
      mealCount: calendar.count,
      snackCount: 1,
      status: calendar.confirmed ? 'CUSTOMER_CONFIRMED' : 'DEFAULT_PENDING',
      locked: calendar.confirmed,
      canConfirm: !calendar.confirmed,
      cutoffAt: calendar.cutoff,
      serverNow: DateTime.now().toUtc(),
      selected: items,
      meals: items.where((m) => m.category == 'meal').toList(),
      snacks: items.where((m) => m.category == 'snack').toList(),
    );
  }

  @override
  Future<TomorrowMenu> confirm(
    String orderId,
    String dayId,
    String language,
    Set<String> meals,
    Set<String> snacks,
  ) async {
    confirmations++;
    calendar.confirmed = true;
    return get(orderId, language);
  }
}

void main() {
  for (final count in [1, 3, 5]) {
    testWidgets(
      '$count meals plus a snack are visible without expansion or extra buttons',
      (tester) async {
        final repository = CalendarRepository(count);
        await showCalendar(tester, repository);
        expect(find.text('Your Meal Calendar'), findsOneWidget);
        expect(find.byType(ExpansionTile), findsNothing);
        expect(find.textContaining('View All'), findsNothing);
        expect(find.text('View Details'), findsNothing);
        for (var i = 0; i <= count; i++) {
          expect(find.byKey(ValueKey('assigned-day-$i')), findsOneWidget);
        }
        expect(find.text('Daily nutrition total'), findsOneWidget);
        expect(find.text('${(count + 1) * 100} kcal'), findsOneWidget);
        final summary = find.byKey(const ValueKey('tourDailyNutrition'));
        final first = find.byKey(const ValueKey('assigned-day-0'));
        expect(
          tester.getTopLeft(summary).dy,
          lessThan(tester.getTopLeft(first).dy),
        );
        expect(tester.getSize(first).height, lessThan(110));
        await tester.ensureVisible(first);
        await tester.tap(first);
        await tester.pumpAndSettle();
        expect(find.byType(MealDetailViewer), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(MealDetailViewer),
            matching: find.text('Healthy meal 1'),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('mealDetailClose')));
        await tester.pumpAndSettle();
        expect(repository.requests, ['day']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'revisiting a date reuses its menu; paused dates show no meal controls',
    (tester) async {
      final repository = CalendarRepository(5);
      await showCalendar(tester, repository);
      Future<void> select(DateTime date) async {
        final cell = find.byKey(
          ValueKey('deliveryDate-${date.toIso8601String()}'),
        );
        await tester.scrollUntilVisible(
          cell,
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(cell);
        await tester.pumpAndSettle();
      }

      await select(repository.date.add(const Duration(days: 1)));
      await select(repository.date);
      expect(repository.requests, ['day', 'next']);
      await select(repository.date.add(const Duration(days: 2)));
      expect(find.text('No meals are scheduled for this day.'), findsOneWidget);
      expect(find.byKey(const ValueKey('assigned-day-0')), findsNothing);
      expect(repository.requests, ['day', 'next']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('incomplete nutrition never displays a misleading daily total', (
    tester,
  ) async {
    await showCalendar(tester, CalendarRepository(3, completeNutrition: false));
    expect(
      find.text('Totals unavailable for missing nutritional values.'),
      findsOneWidget,
    );
    expect(find.text('400 kcal'), findsNothing);
    expect(find.byKey(const ValueKey('assigned-day-3')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Arabic calendar preserves all six rows on a small phone', (
    tester,
  ) async {
    await showCalendar(tester, CalendarRepository(5), language: 'ar');
    expect(find.text('تقويم وجباتك'), findsOneWidget);
    expect(find.byKey(const ValueKey('assigned-day-5')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('calendar reviews and confirms through the existing API flow', (
    tester,
  ) async {
    final calendar = CalendarRepository(1, tomorrow: true);
    final review = ReviewRepository(calendar);
    await showCalendar(tester, calendar, reviewRepository: review);
    final action = find.text('Review & Confirm');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    final confirm = find.byKey(const ValueKey('confirmTomorrowMeals'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(review.confirmations, 1);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Your meals are confirmed.'), findsOneWidget);
    expect(find.text('Review & Confirm'), findsNothing);
    expect(find.byKey(const ValueKey('assigned-day-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'future backend locked display without a selection lock remains scheduled',
    () {
      final now = DateTime.now().toUtc().add(const Duration(hours: 3));
      expect(
        calendarMealStatus(
          date: DateTime(now.year, now.month, now.day + 3),
          status: 'locked',
          selectionStatus: 'DEFAULT_PENDING',
        ),
        CalendarMealStatus.scheduled,
      );
      expect(
        calendarMealStatus(
          date: DateTime(now.year, now.month, now.day + 1),
          status: 'locked',
          deadlinePassed: true,
        ),
        CalendarMealStatus.closed,
      );
      expect(
        calendarMealStatus(
          date: now,
          status: 'locked',
          locked: true,
          selectionStatus: 'AUTO_FINALIZED',
        ),
        CalendarMealStatus.selectedForYou,
      );
      expect(
        calendarMealStatus(
          date: now,
          status: 'auto_selected',
          selectionStatus: 'CUSTOMER_CONFIRMED',
        ),
        CalendarMealStatus.confirmed,
      );
    },
  );
}
