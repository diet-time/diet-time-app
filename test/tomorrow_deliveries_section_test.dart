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
}) => TomorrowMenu(
  subscriptionId: order,
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
  cutoffAt: DateTime.utc(2026, 10, 28, 18),
  serverNow: DateTime.utc(2026, 10, 28, 12),
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
              orders: repository.responses.keys.map(summary).toList(),
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
      expect(find.text('4 scheduled orders'), findsOneWidget);
      expect(inCard('a', 'Confirmed'), findsOneWidget);
      expect(inCard('b', 'Ready to confirm'), findsOneWidget);
      expect(inCard('b', 'Review & confirm'), findsOneWidget);
      expect(inCard('b', '4 of 4 selected'), findsOneWidget);
      expect(inCard('c', 'Selection pending'), findsOneWidget);
      expect(inCard('c', 'Choose your meals'), findsOneWidget);
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
      expect(inCard('a', 'Ready to confirm'), findsOneWidget);
      expect(inCard('a', 'Confirmed'), findsNothing);
      expect(find.byKey(const ValueKey('deliveryProgress-a')), findsNothing);
      await tester.tap(inCard('a', 'Review & confirm'));
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
      expect(inCard('a', 'Confirmed'), findsOneWidget);
      expect(inCard('a', 'View confirmed meals'), findsOneWidget);
      expect(inCard('a', 'Review & confirm'), findsNothing);
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
          ? 'Confirmed'
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
      expect(find.text('Confirmed'), findsOneWidget);
      expect(
        tester.getTopLeft(card('b')).dy,
        lessThan(tester.getTopLeft(card('a')).dy),
      );
      expect(tester.getSize(card('a')).height, lessThan(205));
      expect(tester.getSize(card('b')).height, lessThan(260));
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
      await tester.tap(inCard('b', 'Choose your meals'));
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
      expect(inCard('b', 'Confirmed'), findsOneWidget);
      expect(inCard('b', 'Choose your meals'), findsNothing);
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
    expect(inCard('b', 'Choose your meals'), findsNothing);
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
        expect(number, findsOneWidget);
        expect(tester.widget<Text>(number).maxLines, isNull);
        expect(tester.widget<Text>(number).overflow, isNull);
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
