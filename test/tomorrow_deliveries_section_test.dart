import 'package:diet_time/core/widgets/meal_plan_image.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/data/tomorrow_menu_repository.dart';
import 'package:diet_time/features/dashboard/domain/tomorrow_menu.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/features/dashboard/presentation/tomorrow_deliveries_section.dart';
import 'package:diet_time/features/dashboard/presentation/tomorrow_delivery_card.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

DailyMealItem dish(String order, int index, {bool snack = false}) =>
    DailyMealItem(
      id: '$order-$index',
      optionId: 'option-$order-$index',
      name: '${snack ? 'Snack' : 'Dish'} $order $index',
      category: snack ? 'snack' : 'meal',
      imageUrl: 'https://example.com/food/$order-$index.jpg',
    );

TomorrowMenu delivery(
  String order, {
  bool confirmed = false,
  bool noDelivery = false,
  bool complete = false,
  bool hasPlanImage = true,
  String? selectionStatus,
  String? name,
  String? reference,
  int mealCount = 3,
  int snackCount = 1,
  bool? scheduledForDelivery,
  String? serviceDayStatus,
  String? packageDisplayStatus,
  bool pendingPause = false,
  DateTime? cutoffAt,
  DateTime? serverNow,
}) => TomorrowMenu(
  subscriptionId: order,
  isScheduledForDelivery: scheduledForDelivery,
  serviceDayStatus: serviceDayStatus,
  packageDisplayStatus: packageDisplayStatus,
  selectionBlockedByPendingPause: pendingPause,
  dayId: noDelivery ? null : 'day-$order',
  deliveryDate: DateTime(2026, 10, 29),
  planName: name ?? 'Balance $order',
  orderNumber: reference,
  planId: 'plan-$order',
  planVersion: 2,
  planImageUrl: hasPlanImage ? 'https://example.com/plans/$order.jpg' : null,
  mealCount: mealCount,
  snackCount: snackCount,
  status:
      selectionStatus ??
      (noDelivery
          ? 'NO_DELIVERY'
          : confirmed
          ? 'CUSTOMER_CONFIRMED'
          : 'DEFAULT_PENDING'),
  locked: confirmed,
  canConfirm: !confirmed && !noDelivery,
  cutoffAt: cutoffAt ?? DateTime.utc(2026, 10, 28, 18),
  serverNow: serverNow ?? DateTime.utc(2026, 10, 28, 12),
  selected: [
    dish(order, 0),
    if (confirmed || complete) ...[
      for (var i = 1; i < mealCount; i++) dish(order, i),
    ],
    for (var i = 0; i < snackCount; i++)
      dish(order, mealCount + i, snack: true),
  ],
  meals: confirmed ? [] : [for (var i = 0; i < mealCount; i++) dish(order, i)],
  snacks: confirmed
      ? []
      : [
          for (var i = 0; i < snackCount; i++)
            dish(order, mealCount + i, snack: true),
        ],
);

CustomerOrderSummary summary(String id) => CustomerOrderSummary(
  id: id,
  orderNumber: 'ORD-$id',
  planName: 'Balance $id',
  planDurationName: 'Monthly',
  status: 'ACTIVE',
  paymentStatus: 'PAID',
  totalAmount: 100,
  currencyCode: 'QAR',
  startDate: DateTime(2026, 10, 1),
  endDate: DateTime(2026, 10, 31),
  placedAt: null,
);

class DeliveryRepository extends TomorrowMenuRepository {
  DeliveryRepository(this.responses) : super(ApiClient(), () async => 'token');
  final Map<String, TomorrowMenu> responses;
  final List<String> gets = [];
  final List<(String, String, Set<String>, Set<String>)> confirmations = [];

  @override
  Future<TomorrowMenu> get(String orderId, String language) async {
    gets.add(orderId);
    return responses[orderId]!;
  }

  @override
  Future<TomorrowMenu> confirm(
    String orderId,
    String dayId,
    String language,
    Set<String> meals,
    Set<String> snacks,
  ) async {
    confirmations.add((orderId, dayId, Set.of(meals), Set.of(snacks)));
    final previous = responses[orderId]!;
    return responses[orderId] = delivery(
      orderId,
      confirmed: true,
      mealCount: previous.mealCount,
      snackCount: previous.snackCount,
      name: previous.planName,
      reference: previous.orderNumber,
    );
  }
}

Future<void> show(
  WidgetTester tester,
  DeliveryRepository repository, {
  bool arabic = false,
  double scale = 1,
  double width = 390,
  List<CustomerOrderSummary>? orders,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tomorrowMenuRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: Locale(arabic ? 'ar' : 'en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TomorrowDeliveriesSection(
              orders: orders ?? repository.responses.keys.map(summary).toList(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder card(String id) => find.byKey(ValueKey('tomorrowMenu-$id'));
Finder inCard(String id, String text) =>
    find.descendant(of: card(id), matching: find.text(text));

void main() {
  for (final arabic in [false, true]) {
    for (final allPaused in [false, true]) {
      testWidgets(
        'compact empty state reflects all paused plans ($arabic, $allPaused)',
        (tester) async {
          await show(
            tester,
            DeliveryRepository({
              'paused': delivery(
                'paused',
                noDelivery: true,
                packageDisplayStatus: 'PAUSED',
              ),
              'other': delivery(
                'other',
                noDelivery: true,
                packageDisplayStatus: allPaused ? 'PAUSED' : 'ACTIVE',
              ),
            }),
            arabic: arabic,
            width: 320,
            scale: 1.3,
          );
          final empty = find.byKey(const ValueKey('tomorrowDeliveriesEmpty'));
          expect(empty, findsOneWidget);
          expect(
            find.text(arabic ? 'لا يوجد توصيل غدًا' : 'No delivery tomorrow'),
            findsOneWidget,
          );
          final copy = AppLocalizations.of(tester.element(empty));
          expect(
            find.text(
              allPaused
                  ? arabic
                        ? 'وجباتك متوقفة مؤقتًا. استمتع بيومك!'
                        : 'Your meals are on pause. Enjoy your day!'
                  : copy.deliveriesStatus('NO_DELIVERY'),
            ),
            findsOneWidget,
          );
          // Large text can wrap naturally without clipping on a narrow screen.
          expect(tester.getSize(empty).height, lessThan(200));
          expect(find.byType(TomorrowDeliveryCard), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets(
    'identical plan names with 5, 2 and 1 meals share one keyed delivery-card layout',
    (tester) async {
      TomorrowMenu package(String id, int count) {
        final items = [
          for (var i = 0; i <= count; i++)
            {
              'mealItemId': '$id-$i',
              'slotOptionId': 'option-$id-$i',
              'mealName': 'Dish $id $i',
              'category': i == count ? 'snack' : 'meal',
              'nutrition': {
                'caloriesKcal': 100,
                'proteinGrams': 10,
                'carbohydratesGrams': 20,
                'fatGrams': 5,
              },
            },
        ];
        return TomorrowMenu.fromJson({
          'subscriptionId': id,
          'subscriptionServiceDayId': 'day-$id',
          'deliveryDate': '2026-10-29',
          'mealPlanName': 'Complete Balance',
          'mealPlanImageUrl': 'https://example.com/plans/$id.jpg',
          'mealCount': count,
          'snackCount': 1,
          'selectionStatus': 'DEFAULT_PENDING',
          'canConfirm': true,
          'cutoffAt': '2026-10-28T18:00:00Z',
          'serverNow': '2026-10-28T12:00:00Z',
          'selectedMeals': items,
          'availableMeals': items.take(count).toList(),
          'availableSnacks': [items.last],
        });
      }

      final repository = DeliveryRepository({
        'a': package('a', 5),
        'b': package('b', 2),
        'c': package('c', 1),
      });
      await show(tester, repository);
      final keys = <String, Key?>{};
      final images = <Size>[];
      for (final (id, count) in [('a', 5), ('b', 2), ('c', 1)]) {
        final deliveryCard = find.descendant(
          of: card(id),
          matching: find.byType(TomorrowDeliveryCard),
        );
        expect(deliveryCard, findsOneWidget);
        keys[id] = tester.widget<TomorrowDeliveryCard>(deliveryCard).key;
        expect((keys[id] as ValueKey).value, (id, id, 'day-$id'));
        expect(inCard(id, 'Complete Balance'), findsOneWidget);
        expect(inCard(id, '${(count + 1) * 100} kcal'), findsOneWidget);
        expect(inCard(id, 'Review & Confirm Meals'), findsOneWidget);
        images.add(
          tester.getSize(
            find.descendant(of: card(id), matching: find.byType(MealPlanImage)),
          ),
        );
      }
      expect(keys.values.toSet(), hasLength(3));
      expect(images.toSet(), hasLength(1));
      await show(
        tester,
        repository,
        orders: [summary('c'), summary('b'), summary('a')],
      );
      for (final id in ['a', 'b', 'c']) {
        final deliveryCard = find.descendant(
          of: card(id),
          matching: find.byType(TomorrowDeliveryCard),
        );
        expect(tester.widget<TomorrowDeliveryCard>(deliveryCard).key, keys[id]);
      }
      expect(repository.gets, hasLength(3));
      await tester.ensureVisible(inCard('b', 'Review & Confirm Meals'));
      await tester.tap(inCard('b', 'Review & Confirm Meals'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('confirmTomorrowMeals')),
      );
      await tester.tap(find.byKey(const ValueKey('confirmTomorrowMeals')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(repository.confirmations.single.$1, 'b');
      expect(repository.confirmations.single.$2, 'day-b');
      expect(inCard('b', 'Meals Confirmed'), findsOneWidget);
      expect(inCard('a', 'Review & Confirm Meals'), findsOneWidget);
      expect(inCard('c', 'Review & Confirm Meals'), findsOneWidget);
      expect(inCard('a', '600 kcal'), findsOneWidget);
      expect(inCard('c', '200 kcal'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final status in [
    'PAUSED',
    'SUSPENDED',
    'CANCELLED',
    'SKIPPED',
    'DISPLACED',
  ]) {
    test(
      'inactive $status service cannot override the shared card filter with a scheduled flag',
      () {
        expect(
          delivery(
            'a',
            scheduledForDelivery: true,
            serviceDayStatus: status,
          ).scheduledForTomorrow,
          isFalse,
        );
      },
    );
  }

  testWidgets(
    'aggregates active and pause-requested plans once while excluding approved paused deliveries',
    (tester) async {
      final repository = DeliveryRepository({
        'active': delivery('active', scheduledForDelivery: true),
        'requested': delivery(
          'requested',
          pendingPause: true,
          scheduledForDelivery: true,
          packageDisplayStatus: 'PAUSE_REQUESTED',
        ),
        'paused': delivery(
          'paused',
          scheduledForDelivery: false,
          serviceDayStatus: 'PAUSED',
          packageDisplayStatus: 'PAUSED',
        ),
      });
      await show(
        tester,
        repository,
        orders: [
          summary('active'),
          summary('requested'),
          summary('active'),
          summary('paused'),
        ],
      );
      final copy = AppLocalizations.of(
        tester.element(find.byType(TomorrowDeliveriesSection)),
      );
      expect(find.text(copy.deliveriesScheduled(2)), findsOneWidget);
      expect(find.byType(TomorrowDeliveryCard), findsNWidgets(2));
      expect(card('active'), findsOneWidget);
      expect(card('requested'), findsOneWidget);
      expect(card('paused'), findsNothing);
      expect(repository.gets.where((id) => id == 'active'), hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final arabic in [false, true]) {
    testWidgets(
      'pending pause holds only its own meal selection and rejection restores it ($arabic)',
      (tester) async {
        final repository = DeliveryRepository({
          'held': delivery(
            'held',
            pendingPause: true,
            scheduledForDelivery: true,
            packageDisplayStatus: 'PAUSE_REQUESTED',
          ),
          'unaffected': delivery('unaffected', scheduledForDelivery: true),
        });
        await show(tester, repository, width: 320, scale: 1.3, arabic: arabic);
        final copy = AppLocalizations.of(
          tester.element(find.byType(TomorrowDeliveriesSection)),
        );
        expect(inCard('held', copy.packagePauseRequested), findsOneWidget);
        expect(
          inCard('held', copy.packageMealSelectionPending),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: card('held'),
            matching: find.byKey(const ValueKey('chooseTomorrowMeals')),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: card('unaffected'),
            matching: find.byKey(const ValueKey('chooseTomorrowMeals')),
          ),
          findsOneWidget,
        );
        expect(repository.confirmations, isEmpty);
        expect(tester.takeException(), isNull);

        // Staff rejection releases the hold on the next authoritative schedule refresh.
        repository.responses['held'] = delivery(
          'held',
          scheduledForDelivery: true,
          packageDisplayStatus: 'ACTIVE',
        );
        await tester.pump(const Duration(seconds: 31));
        await tester.pumpAndSettle();
        expect(inCard('held', copy.packagePauseRequested), findsNothing);
        expect(inCard('held', copy.packageMealSelectionPending), findsNothing);
        final choose = find.descendant(
          of: card('held'),
          matching: find.byKey(const ValueKey('chooseTomorrowMeals')),
        );
        expect(choose, findsOneWidget);
        await tester.ensureVisible(choose);
        await tester.tap(choose);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('confirmTomorrowMeals')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('pending pause preserves already confirmed dishes for viewing', (
    tester,
  ) async {
    final repository = DeliveryRepository({
      'committed': delivery(
        'committed',
        confirmed: true,
        pendingPause: true,
        scheduledForDelivery: true,
      ),
    });
    await show(tester, repository);
    expect(find.byKey(const ValueKey('chooseTomorrowMeals')), findsNothing);
    expect(find.byKey(const ValueKey('toggleConfirmedMeals')), findsOneWidget);
    expect(repository.confirmations, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'suspended locked meals are hidden independently of a preserved committed package',
    (tester) async {
      final repository = DeliveryRepository({
        'paused': delivery(
          'paused',
          confirmed: true,
          scheduledForDelivery: false,
          serviceDayStatus: 'PAUSED',
          packageDisplayStatus: 'PAUSED',
        ),
        'committed': delivery(
          'committed',
          confirmed: true,
          scheduledForDelivery: true,
          serviceDayStatus: 'CONFIRMED',
          packageDisplayStatus: 'PAUSED',
        ),
      });
      await show(tester, repository);
      expect(find.byType(TomorrowDeliveryCard), findsOneWidget);
      expect(find.text('Balance paused'), findsNothing);
      expect(find.text('Balance committed'), findsOneWidget);
      final copy = AppLocalizations.of(
        tester.element(find.byType(TomorrowDeliveriesSection)),
      );
      expect(find.text(copy.deliveriesScheduled(1)), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tomorrowDeliveriesEmpty')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'server schedule polling removes an approved pause and restores recalculated resume deliveries',
    (tester) async {
      final repository = DeliveryRepository({
        'plan': delivery('plan', scheduledForDelivery: true),
      });
      await show(tester, repository);
      repository.responses['plan'] = delivery(
        'plan',
        confirmed: true,
        scheduledForDelivery: false,
        serviceDayStatus: 'PAUSED',
        packageDisplayStatus: 'PAUSED',
      );
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.byType(TomorrowDeliveryCard), findsNothing);
      expect(
        find.byKey(const ValueKey('tomorrowDeliveriesEmpty')),
        findsOneWidget,
      );
      repository.responses['plan'] = delivery(
        'plan',
        scheduledForDelivery: true,
        serviceDayStatus: 'PLANNED',
        packageDisplayStatus: 'ACTIVE',
      );
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.byType(TomorrowDeliveryCard), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tomorrowDeliveriesEmpty')),
        findsNothing,
      );
      expect(repository.gets.length, greaterThanOrEqualTo(3));
      await tester.pumpWidget(const SizedBox());
    },
  );
  test(
    'legacy locked selections are never proof of delivery when the day is suspended',
    () {
      final menu = delivery(
        'old',
        confirmed: true,
        serviceDayStatus: 'SUSPENDED',
      );
      expect(menu.locked, isTrue);
      expect(menu.scheduledForTomorrow, isFalse);
    },
  );
  testWidgets(
    'four scheduled orders retain distinct images, states and contextual actions',
    (tester) async {
      await show(
        tester,
        DeliveryRepository({
          'a': delivery('a', confirmed: true),
          'b': delivery('b', complete: true),
          'c': delivery('c'),
          'd': delivery(
            'd',
            confirmed: true,
            selectionStatus: 'AUTO_FINALIZED',
          ),
        }),
      );
      expect(find.byType(TomorrowDeliveryCard), findsNWidgets(4));
      expect(inCard('a', 'Daily nutrition total'), findsOneWidget);
      expect(find.text('4 scheduled orders'), findsOneWidget);
      expect(inCard('a', 'Meals Confirmed'), findsOneWidget);
      expect(inCard('b', 'Confirm your meals by 9:00 PM'), findsOneWidget);
      expect(inCard('b', 'Review & Confirm Meals'), findsOneWidget);
      expect(inCard('b', '4 of 4 selected'), findsOneWidget);
      expect(inCard('c', 'Selection pending'), findsOneWidget);
      expect(inCard('c', 'Choose Meals'), findsOneWidget);
      expect(inCard('d', 'Automatically selected'), findsOneWidget);
      expect(find.byKey(const ValueKey('deliveryProgress-b')), findsNothing);
      expect(find.byKey(const ValueKey('deliveryProgress-c')), findsOneWidget);
      for (final id in ['b', 'c']) {
        expect(
          tester.getTopLeft(card(id)).dy,
          lessThan(tester.getTopLeft(card('a')).dy),
        );
        expect(
          tester.getTopLeft(card(id)).dy,
          lessThan(tester.getTopLeft(card('d')).dy),
        );
      }
      for (final id in ['a', 'b', 'c', 'd']) {
        final image = tester.widget<Image>(
          find.descendant(of: card(id), matching: find.byType(Image)).first,
        );
        expect(
          ((image.image as ResizeImage).imageProvider as NetworkImage).url,
          'https://example.com/plans/$id.jpg',
        );
        expect(image.fit, BoxFit.cover);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    '2 of 2 selected remains unconfirmed and opens review for its own service day',
    (tester) async {
      final repository = DeliveryRepository({
        'a': delivery('a', complete: true, mealCount: 1),
      });
      await show(tester, repository);
      expect(inCard('a', '2 of 2 selected'), findsOneWidget);
      expect(inCard('a', 'Confirm your meals by 9:00 PM'), findsOneWidget);
      expect(inCard('a', 'Meals Confirmed'), findsNothing);
      expect(find.byKey(const ValueKey('deliveryProgress-a')), findsNothing);
      await tester.tap(inCard('a', 'Review & Confirm Meals'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Confirm My Meals'));
      await tester.tap(find.text('Confirm My Meals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(repository.confirmations.single.$1, 'a');
      expect(repository.confirmations.single.$2, 'day-a');
      expect(repository.confirmations.single.$3, {'a-0'});
      expect(repository.confirmations.single.$4, {'a-1'});
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(inCard('a', 'Meals Confirmed'), findsOneWidget);
      expect(inCard('a', 'View confirmed meals'), findsOneWidget);
      expect(inCard('a', 'Review & Confirm Meals'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final state in ['CUSTOMER_CONFIRMED', 'AUTO_FINALIZED', 'LOCKED']) {
    testWidgets('$state exposes all dishes without allowing changes', (
      tester,
    ) async {
      final menu = delivery('a', confirmed: true, selectionStatus: state);
      final repository = DeliveryRepository({'a': menu});
      await show(tester, repository);
      final expected = state == 'CUSTOMER_CONFIRMED'
          ? 'Meals Confirmed'
          : state == 'AUTO_FINALIZED'
          ? 'Automatically selected'
          : 'Locked';
      expect(inCard('a', expected), findsOneWidget);
      expect(
        find.descendant(of: card('a'), matching: find.byType(FilledButton)),
        findsNothing,
      );
      expect(TomorrowMealDraft(menu).toggle(dish('a', 0)), isFalse);
      await tester.tap(find.byKey(const ValueKey('toggleConfirmedMeals')));
      await tester.pumpAndSettle();
      expect(find.text('Dish a 0'), findsOneWidget);
      expect(find.text('Snack a 3'), findsOneWidget);
      expect(repository.confirmations, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('missing plan image uses branding even when dishes have images', (
    tester,
  ) async {
    await show(
      tester,
      DeliveryRepository({'a': delivery('a', hasPlanImage: false)}),
    );
    expect(find.byKey(const ValueKey('planImagePlaceholder')), findsOneWidget);
    final images = tester.widgetList<Image>(
      find.descendant(of: card('a'), matching: find.byType(Image)),
    );
    expect(
      images.any(
        (image) => image.image is NetworkImage || image.image is ResizeImage,
      ),
      isFalse,
    );
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'API maps purchased plan metadata and server confirmation timestamps',
    () {
      final menu = TomorrowMenu.fromJson({
        'subscriptionId': 'order',
        'orderId': 'order',
        'orderNumber': 'DT-123',
        'subscriptionServiceDayId': 'day',
        'deliveryDate': '2026-10-29',
        'mealPlanName': 'Complete Balance',
        'mealPlanTemplateId': 'purchased-plan-v2',
        'mealPlanVersion': 2,
        'mealPlanImageUrl': '/images/balance.jpg',
        'mealCount': 1,
        'snackCount': 1,
        'selectedMealCount': 1,
        'selectedSnackCount': 1,
        'selectionStatus': 'DEFAULT_PENDING',
        'selectionLocked': false,
        'canConfirm': false,
        'customerConfirmedAt': '2026-10-28T12:00:00Z',
        'autoFinalizedAt': null,
        'serverNow': '2026-10-28T13:00:00Z',
        'cutoffAt': '2026-10-28T18:00:00Z',
        'selectedMeals': [],
        'availableMeals': [],
        'availableSnacks': [],
      });
      expect(menu.planId, 'purchased-plan-v2');
      expect(menu.planImageUrl, '/images/balance.jpg');
      expect(menu.planVersion, 2);
      expect(menu.orderNumber, 'DT-123');
      expect(menu.savedMealCount + menu.savedSnackCount, 2);
      expect(menu.deliveryState(), TomorrowDeliveryState.confirmed);
      expect(menu.readOnly, isTrue);
    },
  );

  testWidgets(
    'one dated header, pending first, accurate snack progress and compact read-only confirmation',
    (tester) async {
      final repository = DeliveryRepository({
        'a': delivery('a', confirmed: true),
        'b': delivery('b'),
        'c': delivery('c'),
      });
      await show(tester, repository);
      expect(find.text('Tomorrow’s Deliveries'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tomorrowDeliveryDate')),
        findsOneWidget,
      );
      expect(find.text('3 scheduled orders'), findsOneWidget);
      expect(find.text('2 of 4 selected'), findsNWidgets(2));
      expect(find.text('Selection pending'), findsNWidgets(2));
      expect(find.text('Meals Confirmed'), findsOneWidget);
      expect(
        tester.getTopLeft(card('b')).dy,
        lessThan(tester.getTopLeft(card('a')).dy),
      );
      expect(tester.getSize(card('a')).height, lessThan(285));
      expect(tester.getSize(card('b')).height, lessThan(360));
      expect(find.text('Dish a 0'), findsNothing);
      expect(
        find.descendant(of: card('a'), matching: find.byType(FilledButton)),
        findsNothing,
      );
      final thumbnail = tester.widget<Image>(
        find.descendant(of: card('a'), matching: find.byType(Image)).first,
      );
      expect(
        ((thumbnail.image as ResizeImage).imageProvider as NetworkImage).url,
        'https://example.com/plans/a.jpg',
      );
      await tester.ensureVisible(inCard('a', 'View confirmed meals'));
      await tester.tap(inCard('a', 'View confirmed meals'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        expect(find.text('Dish a $i'), findsOneWidget);
      }
      expect(find.text('Snack a 3'), findsOneWidget);
      expect(repository.confirmations, isEmpty);
      expect(repository.gets, containsAll(['a', 'b', 'c']));
      expect(repository.gets.length, 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'selection and confirmation use the correct order and service day after sorting',
    (tester) async {
      final repository = DeliveryRepository({
        'a': delivery('a', confirmed: true),
        'b': delivery('b'),
        'c': delivery('c'),
      });
      await show(tester, repository);
      await tester.tap(inCard('b', 'Choose Meals'));
      await tester.pumpAndSettle();
      expect(find.text('Balance b'), findsOneWidget);
      expect(find.text('Dish c 0'), findsNothing);
      for (final name in ['Dish b 1', 'Dish b 2']) {
        await tester.ensureVisible(find.text(name));
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Confirm My Meals'));
      await tester.tap(find.text('Confirm My Meals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      final confirmation = repository.confirmations.single;
      expect(confirmation.$1, 'b');
      expect(confirmation.$2, 'day-b');
      expect(confirmation.$3, {'b-0', 'b-1', 'b-2'});
      expect(confirmation.$4, {'b-3'});
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(inCard('b', 'Meals Confirmed'), findsOneWidget);
      expect(inCard('b', 'Choose Meals'), findsNothing);
      expect(inCard('c', '2 of 4 selected'), findsOneWidget);
      expect(
        tester.getTopLeft(card('c')).dy,
        lessThan(tester.getTopLeft(card('b')).dy),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('unscheduled orders are excluded from the scheduled count', (
    tester,
  ) async {
    await show(
      tester,
      DeliveryRepository({
        'a': delivery('a'),
        'b': delivery('b', noDelivery: true),
      }),
    );
    expect(find.text('1 scheduled order'), findsOneWidget);
    expect(inCard('b', 'Choose Meals'), findsNothing);
    expect(card('b'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  for (final arabic in [false, true]) {
    testWidgets(
      '320px ${arabic ? 'Arabic RTL' : 'English'} supports large text and expansion',
      (tester) async {
        await show(
          tester,
          DeliveryRepository({
            'a': delivery(
              'a',
              confirmed: true,
              name: arabic
                  ? 'خطة كومبليت بالانس المتكاملة'
                  : 'Complete Balance',
              reference: 'DT-20261028-00001234',
            ),
            'b': delivery(
              'b',
              name: arabic
                  ? 'خطة كومبليت بالانس المتكاملة'
                  : 'Complete Balance',
              reference: 'DT-20261028-00001235',
            ),
          }),
          arabic: arabic,
          width: 320,
          scale: 1.5,
        );
        expect(
          find.text(arabic ? 'توصيلات الغد' : 'Tomorrow’s Deliveries'),
          findsOneWidget,
        );
        expect(
          Directionality.of(tester.element(card('a'))),
          arabic ? TextDirection.rtl : TextDirection.ltr,
        );
        final number = inCard(
          'a',
          arabic
              ? 'الطلب: DT-20261028-00001234'
              : 'Order: DT-20261028-00001234',
        );
        expect(number, findsNothing);
        expect(find.byTooltip('Order: DT-20261028-00001234'), findsNothing);
        final toggle = inCard(
          'a',
          arabic ? 'عرض الوجبات المؤكدة' : 'View confirmed meals',
        );
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.text('Snack a 3'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
