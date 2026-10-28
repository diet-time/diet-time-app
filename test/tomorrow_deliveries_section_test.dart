import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/data/tomorrow_menu_repository.dart';
import 'package:diet_time/features/dashboard/domain/tomorrow_menu.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/features/dashboard/presentation/tomorrow_deliveries_section.dart';
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
}) => TomorrowMenu(
  subscriptionId: order,
  dayId: noDelivery ? null : 'day-$order',
  deliveryDate: DateTime(2026, 10, 29),
  planName: 'Balance $order',
  mealCount: 3,
  snackCount: 1,
  status: noDelivery
      ? 'NO_DELIVERY'
      : confirmed
      ? 'CUSTOMER_CONFIRMED'
      : 'DEFAULT_PENDING',
  locked: confirmed,
  canConfirm: !confirmed && !noDelivery,
  cutoffAt: DateTime.utc(2026, 10, 28, 18),
  serverNow: DateTime.utc(2026, 10, 28, 12),
  selected: [
    dish(order, 0),
    if (confirmed) ...[dish(order, 1), dish(order, 2)],
    dish(order, 3, snack: true),
  ],
  meals: confirmed ? [] : [for (var i = 0; i < 3; i++) dish(order, i)],
  snacks: confirmed ? [] : [dish(order, 3, snack: true)],
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
    return responses[orderId] = delivery(orderId, confirmed: true);
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
      expect(find.text('Action needed'), findsNWidgets(2));
      expect(find.text('All 4 dishes confirmed'), findsOneWidget);
      expect(
        tester.getTopLeft(card('b')).dy,
        lessThan(tester.getTopLeft(card('a')).dy),
      );
      expect(tester.getSize(card('a')).height, lessThan(205));
      expect(tester.getSize(card('b')).height, lessThan(240));
      expect(find.text('Dish a 0'), findsNothing);
      expect(
        find.descendant(of: card('a'), matching: find.byType(FilledButton)),
        findsNothing,
      );
      final thumbnail = tester.widget<Image>(
        find.descendant(of: card('a'), matching: find.byType(Image)).first,
      );
      expect(
        (thumbnail.image as NetworkImage).url,
        'https://example.com/food/a-0.jpg',
      );
      await tester.ensureVisible(inCard('a', 'View your dishes'));
      await tester.tap(inCard('a', 'View your dishes'));
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
    expect(find.text('No delivery is scheduled for tomorrow.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final arabic in [false, true]) {
    testWidgets(
      '320px ${arabic ? 'Arabic RTL' : 'English'} supports large text and expansion',
      (tester) async {
        await show(
          tester,
          DeliveryRepository({
            'a': delivery('a', confirmed: true),
            'b': delivery('b'),
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
        final toggle = inCard('a', arabic ? 'عرض أطباقك' : 'View your dishes');
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
