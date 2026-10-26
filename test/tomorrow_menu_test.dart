import 'dart:async';

import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/dashboard/data/tomorrow_menu_repository.dart';
import 'package:diet_time/features/dashboard/domain/tomorrow_menu.dart';
import 'package:diet_time/features/dashboard/domain/upcoming_meals.dart';
import 'package:diet_time/features/dashboard/presentation/tomorrow_menu_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const dishes = [
  DailyMealItem(
    id: 'm1',
    optionId: 'o1',
    name: 'Grilled chicken',
    category: 'meal',
    calories: 450,
  ),
  DailyMealItem(
    id: 'm2',
    optionId: 'o2',
    name: 'Salmon bowl',
    category: 'meal',
  ),
  DailyMealItem(
    id: 'm3',
    optionId: 'o3',
    name: 'Roasted vegetables',
    category: 'meal',
  ),
];
const snack = DailyMealItem(
  id: 's1',
  optionId: 'os1',
  name: 'Berry yogurt',
  category: 'snack',
);

TomorrowMenu menu({
  bool confirmed = false,
  bool noDelivery = false,
  bool extraSnack = false,
}) => TomorrowMenu(
  subscriptionId: 'order',
  dayId: noDelivery ? null : 'day',
  deliveryDate: DateTime(2026, 10, 27),
  planName: 'Complete Balance',
  mealCount: 2,
  snackCount: 1,
  status: noDelivery
      ? 'NO_DELIVERY'
      : confirmed
      ? 'CUSTOMER_CONFIRMED'
      : 'DEFAULT_PENDING',
  locked: confirmed,
  canConfirm: !confirmed && !noDelivery,
  cutoffAt: DateTime.utc(2026, 10, 26, 18),
  serverNow: DateTime.utc(2026, 10, 26, 12),
  selected: [dishes[0], dishes[1], snack],
  meals: confirmed ? [] : dishes,
  snacks: confirmed
      ? []
      : [
          snack,
          if (extraSnack)
            const DailyMealItem(
              id: 's2',
              optionId: 'os2',
              name: 'Fruit cup',
              category: 'snack',
            ),
        ],
);

void main() {
  test('replacement keeps count, category and dish identity', () {
    final draft = TomorrowMealDraft(menu());
    expect(draft.replace(dishes[2], 'm1'), true);
    expect(draft.mealIds, {'m2', 'm3'});
    expect(draft.snackIds, {'s1'});
    expect(draft.replace(dishes[1], 'm3'), false);
    expect(
      TomorrowMealDraft(menu(confirmed: true)).replace(dishes[2], 'm1'),
      false,
    );
  });

  Future<void> show(WidgetTester tester, FakeRepository repository) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tomorrowMenuRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TomorrowMenuSection(orderId: 'order'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('full draft opens replacement sheet without confirming', (
    tester,
  ) async {
    final repository = FakeRepository();
    await show(tester, repository);
    await tester.ensureVisible(find.text('Roasted vegetables'));
    await tester.tap(find.text('Roasted vegetables'));
    await tester.pumpAndSettle();
    expect(find.text('Replace a meal'), findsOneWidget);
    await tester.tap(find.text('Grilled chicken').last);
    await tester.pumpAndSettle();
    expect(find.text('Replace a meal'), findsNothing);
    expect(find.text('Meals: 2/2 selected'), findsOneWidget);
    expect(repository.confirms, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'one snack directly replaces its draft without a sheet or API call',
    (tester) async {
      final repository = FakeRepository()..response = menu(extraSnack: true);
      await show(tester, repository);
      await tester.ensureVisible(find.text('Fruit cup'));
      await tester.tap(find.text('Fruit cup'));
      await tester.pumpAndSettle();
      expect(find.text('Replace a snack'), findsNothing);
      expect(find.text('Snacks: 1/1 selected'), findsOneWidget);
      final selected = tester
          .widgetList<Semantics>(
            find.ancestor(
              of: find.text('Fruit cup'),
              matching: find.byType(Semantics),
            ),
          )
          .where((widget) => widget.properties.selected != null)
          .single;
      expect(selected.properties.selected, true);
      expect(repository.confirms, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final entry in {
    'SERVICE_DAYS_MISSING':
        'Your order is saved, but its delivery schedule needs to be initialized by our team.',
    'MENU_NOT_CONFIGURED':
        'Your order is saved. Tomorrow’s dishes have not been configured yet.',
    'NOT_STARTED':
        'Your plan starts soon. Selection opens the day before your first delivery.',
    'PENDING_ACTIVATION': 'Your order is saved and is waiting for activation.',
    'FINALIZATION_PENDING':
        'The 9:00 PM selection window has closed. Your automatic meals are being finalized.',
  }.entries) {
    testWidgets(
      '${entry.key} retains plan details with a distinct explanation',
      (tester) async {
        final response = TomorrowMenu(
          subscriptionId: 'order',
          dayId: null,
          deliveryDate: DateTime(2026, 10, 27),
          planName: 'Complete Balance',
          mealCount: 2,
          snackCount: 1,
          status: entry.key,
          locked: false,
          canConfirm: false,
          cutoffAt: DateTime.utc(2026, 10, 26, 18),
          serverNow: DateTime.utc(2026, 10, 26, 12),
          selected: [],
          meals: [],
          snacks: [],
          firstDeliveryDate: DateTime(2026, 10, 31),
        );
        await show(tester, FakeRepository()..response = response);
        expect(find.text('Complete Balance'), findsOneWidget);
        expect(find.text('2 Meals + 1 Snack'), findsOneWidget);
        expect(find.text(entry.value), findsOneWidget);
        expect(find.text('Confirm My Meals'), findsNothing);
        expect(
          find.text('No delivery is scheduled for tomorrow.'),
          findsNothing,
        );
        if (entry.key == 'NOT_STARTED') {
          expect(
            find.text('First delivery: Saturday, 31 October'),
            findsOneWidget,
          );
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'an available menu with no saved selections shows selectable dishes and zero progress',
    (tester) async {
      final available = menu();
      final response = TomorrowMenu(
        subscriptionId: available.subscriptionId,
        dayId: available.dayId,
        deliveryDate: available.deliveryDate,
        planName: available.planName,
        mealCount: 2,
        snackCount: 1,
        status: 'DEFAULT_PENDING',
        locked: false,
        canConfirm: true,
        cutoffAt: available.cutoffAt,
        serverNow: available.serverNow,
        selected: [],
        meals: dishes,
        snacks: [snack],
      );
      await show(tester, FakeRepository()..response = response);
      expect(find.text('Meals: 0/2 selected'), findsOneWidget);
      expect(find.text('Snacks: 0/1 selected'), findsOneWidget);
      expect(find.text('Grilled chicken'), findsOneWidget);
      await tester.tap(find.text('Grilled chicken'));
      await tester.pump();
      expect(find.text('Meals: 1/2 selected'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'defaults preselect locally; exact entitlements and distinct dishes are enforced',
    () {
      final draft = TomorrowMealDraft(menu());
      expect(draft.complete, isTrue);
      expect(draft.toggle(dishes[2]), isFalse);
      expect(draft.toggle(dishes[0]), isTrue);
      expect(draft.complete, isFalse);
      expect(draft.toggle(dishes[2]), isTrue);
      expect(draft.complete, isTrue);
      expect(draft.mealIds, {'m2', 'm3'});
      expect(
        draft.toggle(
          const DailyMealItem(
            id: 'm2',
            optionId: 'x',
            name: 'Invalid',
            category: 'snack',
          ),
        ),
        isFalse,
      );
      expect(
        draft.toggle(
          const DailyMealItem(
            id: 'x',
            optionId: 'x',
            name: 'Unknown',
            category: 'meal',
          ),
        ),
        isFalse,
      );
    },
  );

  test(
    'repository authenticates and posts complete set using existing order routes',
    () async {
      final api = RecordingApi();
      final repository = TomorrowMenuRepository(api, () async => 'token');
      await repository.get('order', 'en');
      expect(api.path, '/api/v1/orders/order/tomorrow-menu');
      expect(api.headers['Authorization'], 'Bearer token');
      api.confirmed = true;
      final saved = await repository.confirm(
        'order',
        'day',
        'en',
        {'m1', 'm2'},
        {'s1'},
      );
      expect(api.method, 'POST');
      expect(api.path, '/api/v1/orders/order/service-days/day/confirm-meals');
      expect(api.body, {
        'mealMenuItemIds': ['m1', 'm2'],
        'snackMenuItemIds': ['s1'],
      });
      expect(saved.locked, isTrue);
    },
  );

  test(
    'provisional or wrong-day success responses cannot show confirmation success',
    () async {
      final api = RecordingApi();
      final repository = TomorrowMenuRepository(api, () async => 'token');
      await expectLater(
        repository.confirm('order', 'day', 'en', {'m1', 'm2'}, {'s1'}),
        throwsA(isA<ApiException>()),
      );
      api.confirmed = true;
      api.dayId = 'other';
      await expectLater(
        repository.confirm('order', 'day', 'en', {'m1', 'm2'}, {'s1'}),
        throwsA(isA<ApiException>()),
      );
      final noAuth = RecordingApi();
      await expectLater(
        TomorrowMenuRepository(noAuth, () async => null).get('order', 'en'),
        throwsA(isA<ApiException>()),
      );
      expect(noAuth.path, isNull);
    },
  );

  testWidgets(
    'draft is editable, confirmation is cancellable, duplicate submits blocked, success waits for API',
    (tester) async {
      final repository = FakeRepository();
      await show(tester, repository);
      expect(find.text('Meals: 2/2 selected'), findsOneWidget);
      expect(repository.confirms, 0);
      await tester.tap(find.text('Grilled chicken'));
      await tester.pump();
      expect(find.text('Meals: 1/2 selected'), findsOneWidget);
      final disabled = tester.widget<FilledButton>(
        find.byKey(const ValueKey('confirmTomorrowMeals')),
      );
      expect(disabled.onPressed, isNull);
      await tester.tap(find.text('Roasted vegetables'));
      await tester.pump();
      await tester.ensureVisible(find.text('Confirm My Meals'));
      await tester.tap(find.text('Confirm My Meals'));
      await tester.pumpAndSettle();
      expect(
        find.text('Your selections cannot be changed after confirmation.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repository.confirms, 0);
      await tester.tap(find.text('Confirm My Meals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(repository.confirms, 1);
      expect(find.text('Your meals are confirmed!'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('confirmTomorrowMeals')),
            )
            .onPressed,
        isNull,
      );
      repository.pending.complete(menu(confirmed: true));
      await tester.pumpAndSettle();
      expect(find.text('Your meals are confirmed!'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Confirm My Meals'), findsNothing);
      expect(
        find
            .byType(InkWell)
            .evaluate()
            .where((e) => (e.widget as InkWell).onTap != null),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('no delivery has no selection form', (tester) async {
    await show(tester, FakeRepository()..response = menu(noDelivery: true));
    expect(find.text('No delivery is scheduled for tomorrow.'), findsOneWidget);
    expect(find.text('Confirm My Meals'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'network ambiguity refreshes authoritative state before success',
    (tester) async {
      final repository = FakeRepository();
      await show(tester, repository);
      await tester.ensureVisible(find.text('Confirm My Meals'));
      await tester.tap(find.text('Confirm My Meals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      repository.response = menu(confirmed: true);
      repository.pending.completeError(const ApiException(ApiFailure.network));
      await tester.pumpAndSettle();
      expect(repository.gets, 2);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.textContaining('could not verify'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class FakeRepository extends TomorrowMenuRepository {
  FakeRepository() : super(ApiClient(), () async => 'token');
  TomorrowMenu response = menu();
  final pending = Completer<TomorrowMenu>();
  int confirms = 0;
  int gets = 0;
  @override
  Future<TomorrowMenu> get(String orderId, String language) async {
    gets++;
    return response;
  }

  @override
  Future<TomorrowMenu> confirm(
    String orderId,
    String dayId,
    String language,
    Set<String> meals,
    Set<String> snacks,
  ) {
    confirms++;
    return pending.future;
  }
}

class RecordingApi extends ApiClient {
  String? path;
  String? method;
  String dayId = 'day';
  Map<String, String> headers = {};
  Map<String, dynamic>? body;
  bool confirmed = false;
  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    this.path = path;
    this.method = method;
    this.headers = headers;
    this.body = body;
    Map<String, dynamic> item(DailyMealItem m) => {
      'mealItemId': m.id,
      'slotOptionId': m.optionId,
      'mealName': m.name,
      'category': m.category,
    };
    return ApiResponse(
      statusCode: 200,
      body: {
        'data': {
          'subscriptionId': 'order',
          'subscriptionServiceDayId': dayId,
          'deliveryDate': '2026-10-27',
          'mealPlanName': 'Complete Balance',
          'mealCount': 2,
          'snackCount': 1,
          'selectionStatus': confirmed
              ? 'CUSTOMER_CONFIRMED'
              : 'DEFAULT_PENDING',
          'selectionLocked': confirmed,
          'canConfirm': !confirmed,
          'cutoffAt': '2026-10-26T18:00:00Z',
          'serverNow': '2026-10-26T12:00:00Z',
          'selectedMeals': [...dishes.take(2), snack].map(item).toList(),
          'availableMeals': dishes.map(item).toList(),
          'availableSnacks': [item(snack)],
        },
      },
    );
  }
}
