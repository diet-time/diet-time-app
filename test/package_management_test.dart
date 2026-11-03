import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/domain/package_management.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/dashboard/presentation/order_details_screen.dart';
import 'package:diet_time/features/dashboard/presentation/package_management_panel.dart';
import 'package:diet_time/features/dashboard/presentation/package_management_provider.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> management({bool paused = false, bool available = true}) =>
    {
      'orderId': 'order',
      'rowVersion': paused ? 2 : 1,
      'serverNow': '2026-11-02T12:00:00Z',
      'status': paused ? 'SCHEDULED' : 'ACTIVE',
      'remainingServiceDays': 8,
      'nextScheduledDelivery': paused ? '2026-11-10' : '2026-11-04',
      'expectedEndDate': paused ? '2026-11-20' : '2026-11-12',
      'eligiblePauseDates': !paused && available
          ? ['2026-11-04', '2026-11-05', '2026-11-07']
          : [],
      'currentPause': paused
          ? {
              'id': 'pause',
              'pauseStartDate': '2026-11-04',
              'resumeDate': '2026-11-10',
              'status': 'SCHEDULED',
            }
          : null,
      'canResumeEarly': paused,
    };
Map<String, dynamic> previewJson() => {
  'rowVersion': 1,
  'scheduleVersion': 'schedule-fingerprint',
  'earliestPauseDate': '2026-11-04',
  'pauseStartDate': '2026-11-04',
  'resumeDate': '2026-11-05',
  'affectedServiceDays': 1,
  'rescheduledServiceDays': 8,
  'preservedCommittedDays': 1,
  'projectedEndDate': '2026-11-20',
  'remainingServiceDays': 8,
  'actualRestartDate': '2026-11-05',
};
OrderConfirmation order({
  String status = 'CONFIRMED',
  String payment = 'PAID',
  bool takeaway = false,
}) => OrderConfirmation.fromJson({
  'fulfillmentMethod': takeaway ? 'TAKEAWAY' : 'HOME_DELIVERY',
  'takeawayBranch': takeaway
      ? {
          'id': 'branch',
          'name': 'Diet Time – Izghawa Branch',
          'address': 'Izghawa, Qatar',
        }
      : null,
  'id': 'order',
  'orderNumber': 'ORD-TEST',
  'status': status,
  'paymentStatus': payment,
  'plan': {
    'mealPlanTemplateId': 'plan',
    'mealPlanPriceId': 'price',
    'name': 'Balanced',
    'durationName': '12 days',
  },
  'meals': [
    {'mealTypeId': 'meal', 'name': 'Lunch', 'quantity': 1},
  ],
  'delivery': {
    'address': {
      'name': 'Home',
      'area': 'Doha',
      'formattedAddress': 'Building 10, Street 20, Doha',
    },
    'daysPerWeek': 6,
    'days': [1, 2, 3, 4, 6, 7],
    'startDate': '2026-11-03',
    'endDate': '2026-11-16',
  },
  'pricing': {
    'subtotal': 100,
    'discountAmount': 0,
    'deliveryCharge': 0,
    'totalAmount': 100,
    'currencyCode': 'QAR',
  },
  'placedAt': '2026-11-02T10:00:00Z',
  'review': {'rowVersion': 1},
});

class PackageOrders extends OrdersRepository {
  PackageOrders()
    : super(apiClient: ApiClient(), accessTokenProvider: () async => 'token');
  bool paused = false, available = true, failOnce = false, takeaway = false;
  ApiException? previewError;
  int managementReads = 0;
  List<String>? changedEligibleDates;
  final previewStarts = <DateTime>[];
  final confirmedStarts = <DateTime>[];
  int previews = 0, resumes = 0;
  final commands = <String>[];
  @override
  Future<OrderConfirmation> getOrder(String id) async =>
      order(takeaway: takeaway);
  @override
  Future<PackageManagement> getPackageManagement(String id) async {
    managementReads++;
    final json = management(paused: paused, available: available);
    if (managementReads >= 3 && changedEligibleDates != null) {
      json['eligiblePauseDates'] = changedEligibleDates;
    }
    return PackageManagement.fromJson(json);
  }

  @override
  Future<PackagePausePreview> previewPause(
    String id,
    DateTime start,
    DateTime resume,
  ) async {
    previews++;
    previewStarts.add(start);
    if (previewError case final error?) throw error;
    return PackagePausePreview.fromJson({
      ...previewJson(),
      'pauseStartDate': packageDate(start),
      'resumeDate': packageDate(resume),
      'actualRestartDate': packageDate(resume),
    });
  }

  @override
  Future<PackageManagement> pausePackage(
    String id,
    String commandId,
    PackagePausePreview preview,
    DateTime start,
    DateTime resume,
    String? reason,
  ) async {
    commands.add(commandId);
    confirmedStarts.add(start);
    if (failOnce) {
      failOnce = false;
      throw const ApiException(ApiFailure.network);
    }
    paused = true;
    return getPackageManagement(id);
  }

  @override
  Future<PackageManagement> resumePackage(
    String id,
    String commandId,
    String pauseId,
    int rowVersion, {
    DateTime? resumeDate,
  }) async {
    resumes++;
    paused = false;
    return getPackageManagement(id);
  }
}

class PackageDashboard extends CustomerDashboardController {
  @override
  CustomerDashboardState build() => const DashboardNoOrders();
  @override
  Future<void> refresh() async {}
}

class CapturePackageApi extends ApiClient {
  final calls =
      <
        ({
          String method,
          String path,
          Map<String, String> headers,
          Map<String, dynamic>? body,
        })
      >[];
  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    calls.add((method: method, path: path, headers: headers, body: body));
    return ApiResponse(
      statusCode: 200,
      body: path.endsWith('/preview') ? previewJson() : management(),
    );
  }
}

void main() {
  test(
    'restart selection extends beyond package end and clamps six-month boundaries',
    () {
      final data = PackageManagement.fromJson(management());
      expect(
        data.earliestRestartDate(utcNow: data.receivedAt),
        DateTime(2026, 11, 3),
      );
      expect(
        data.latestRestartDate(utcNow: data.receivedAt),
        DateTime(2027, 5, 2),
      );
      expect(packageRestartLimit(DateTime(2026, 8, 31)), DateTime(2027, 2, 28));
      final cutoff = PackageManagement.fromJson({
        ...management(),
        'serverNow': '2026-11-02T18:00:00Z',
      });
      expect(
        cutoff.earliestRestartDate(utcNow: cutoff.receivedAt),
        DateTime(2026, 11, 4),
      );
    },
  );
  test(
    'pause restart follows the first eligible delivery, not the clock boundary or package end',
    () {
      final data = PackageManagement.fromJson({
        ...management(),
        'expectedEndDate': '2026-12-01',
      });
      expect(
        data.earliestPauseDate(utcNow: data.receivedAt),
        DateTime(2026, 11, 4),
      );
      expect(
        data.earliestPauseRestartDate(utcNow: data.receivedAt),
        DateTime(2026, 11, 5),
      );
      expect(
        data.earliestPauseRestartDate(utcNow: data.receivedAt),
        isNot(data.endDate),
      );
    },
  );
  test(
    'cancellation requires both approved state and paid payment; pending payment keeps the existing action',
    () {
      for (final status in ['CONFIRMED', 'ACTIVE', 'PAUSED']) {
        expect(order(status: status).customerCancellationBlocked, isTrue);
        expect(order(status: status).canRequestCancellation, isFalse);
      }
      expect(order(payment: 'PENDING').canRequestCancellation, isTrue);
      expect(order(payment: 'UNPAID').canRequestCancellation, isTrue);
      expect(
        order(
          status: 'PENDING_APPROVAL',
          payment: 'PENDING',
        ).canRequestCancellation,
        isTrue,
      );
      expect(
        order(status: 'ON_HOLD', payment: 'PENDING').canRequestCancellation,
        isTrue,
      );
      expect(order(status: 'COMPLETED').canRequestCancellation, isFalse);
    },
  );
  test(
    'Qatar dates exclude today, past, locked/missing dates, Friday and the exact next-day cutoff',
    () {
      final data = PackageManagement.fromJson({
        ...management(),
        'serverNow': '2026-11-02T17:59:59Z',
        'eligiblePauseDates': [
          '2026-11-02',
          '2026-11-03',
          '2026-11-04',
          '2026-11-06',
        ],
      });
      expect(
        data.allowsPauseDate(DateTime(2026, 11, 2), utcNow: data.receivedAt),
        isFalse,
      );
      expect(
        data.allowsPauseDate(DateTime(2026, 11, 1), utcNow: data.receivedAt),
        isFalse,
      );
      expect(
        data.allowsPauseDate(DateTime(2026, 11, 3), utcNow: data.receivedAt),
        isTrue,
      );
      expect(
        data.allowsPauseDate(
          DateTime(2026, 11, 3),
          utcNow: data.receivedAt.add(const Duration(seconds: 1)),
        ),
        isFalse,
      );
      expect(
        data.allowsPauseDate(DateTime(2026, 11, 4), utcNow: data.receivedAt),
        isTrue,
      );
      expect(
        data.allowsPauseDate(DateTime(2026, 11, 5), utcNow: data.receivedAt),
        isFalse,
      );
      expect(
        data.allowsPauseDate(DateTime(2026, 11, 6), utcNow: data.receivedAt),
        isFalse,
      );
    },
  );
  test(
    'package commands reuse authenticated order endpoints with versions, dates and stable command IDs',
    () async {
      final api = CapturePackageApi();
      final repository = OrdersRepository(
        apiClient: api,
        accessTokenProvider: () async => 'token',
      );
      await repository.getPackageManagement('order');
      final preview = await repository.previewPause(
        'order',
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 10),
      );
      const id = 'a3112f94-8ba0-42ff-9485-3a743453ac88';
      await repository.pausePackage(
        'order',
        id,
        preview,
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 10),
        'Travel',
      );
      await repository.resumePackage(
        'order',
        id,
        'pause',
        2,
        resumeDate: DateTime(2026, 11, 3),
      );
      expect(api.calls.last.body, containsPair('resumeDate', '2026-11-03'));
      expect(api.calls.map((c) => c.path), [
        '/api/v1/orders/order/package-management',
        '/api/v1/orders/order/pause/preview',
        '/api/v1/orders/order/pause',
        '/api/v1/orders/order/resume',
      ]);
      expect(
        api.calls.every((c) => c.headers['Authorization'] == 'Bearer token'),
        isTrue,
      );
      expect(
        api.calls[2].body,
        containsPair('scheduleVersion', 'schedule-fingerprint'),
      );
      expect(api.calls[2].body, containsPair('commandId', id));
      expect(api.calls[2].body, containsPair('expectedRowVersion', 1));
      expect(api.calls[2].body, containsPair('pauseStartDate', '2026-11-04'));
    },
  );

  testWidgets(
    'preview refreshes the eligible start when preparation commits a day while the picker is open',
    (tester) async {
      final repository = PackageOrders()
        ..changedEligibleDates = ['2026-11-05', '2026-11-07'];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: PackageManagementPanel(orderId: 'order'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final copy = lookupAppLocalizations(const Locale('en'));
      await tester.tap(find.byKey(const ValueKey('pausePackage-order')));
      await tester.pumpAndSettle();
      final picker = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      picker.onDateChanged(DateTime(2026, 11, 10));
      await tester.pump();
      await tester.tap(
        find.text(
          MaterialLocalizations.of(
            tester.element(find.byType(CalendarDatePicker)),
          ).okButtonLabel,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(copy.packagePreviewPause));
      await tester.pumpAndSettle();
      expect(repository.previewStarts, [DateTime(2026, 11, 5)]);
      expect(repository.commands, isEmpty);
      expect(find.text(copy.packageConfirmPause), findsOneWidget);
    },
  );

  for (final language in ['en', 'ar']) {
    testWidgets(
      'paid confirmed order keeps details and explanation, without cancellation ($language)',
      (tester) async {
        final repository = PackageOrders();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const OrderDetailsScreen(orderId: 'order'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final copy = lookupAppLocalizations(Locale(language));
        expect(find.text(copy.packageCancellationBlocked), findsOneWidget);
        expect(find.byIcon(Icons.cancel_outlined), findsNothing);
        expect(
          find.byKey(const ValueKey('orderDetailsHeader')),
          findsOneWidget,
        );
        expect(find.text('Balanced'), findsWidgets);
        expect(
          find.byKey(const ValueKey('packageManagement-order')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    for (final takeaway in [true, false]) {
      testWidgets(
        'fulfillment is inside the details card with one deferred support button and no receipt action ($language, $takeaway)',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = PackageOrders()..takeaway = takeaway;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ordersRepositoryProvider.overrideWithValue(repository),
              ],
              child: MaterialApp(
                locale: Locale(language),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(viewPadding: const EdgeInsets.only(bottom: 34)),
                  child: child!,
                ),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const OrderDetailsScreen(orderId: 'order'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final copy = lookupAppLocalizations(Locale(language));
          final row = find.byKey(const ValueKey('orderFulfillmentDetails'));
          await tester.scrollUntilVisible(row, 250);
          expect(
            find.descendant(
              of: row,
              matching: find.text(
                takeaway
                    ? copy.orderCollectionDetails
                    : copy.orderDeliveryDetails,
              ),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: row,
              matching: find.byIcon(Icons.location_on_outlined),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: row,
              matching: find.textContaining(
                takeaway ? 'Diet Time – Izghawa Branch' : 'Doha',
              ),
            ),
            findsOneWidget,
          );
          expect(
            find.text('Takeaway · Diet Time – Izghawa Branch'),
            findsNothing,
          );
          final appBar = tester.widget<AppBar>(find.byType(AppBar));
          expect(appBar.actions, isNull);
          expect(find.byIcon(Icons.receipt_long_outlined), findsNothing);
          final support = find.byKey(const ValueKey('orderContactSupport'));
          await tester.scrollUntilVisible(support, 200);
          await tester.tap(support);
          await tester.pump();
          expect(find.text(copy.orderSupportPending), findsOneWidget);
          expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('orderConfirmationCard')),
            100,
          );
          expect(
            tester.getRect(support).bottom,
            lessThan(
              tester
                  .getRect(find.byKey(const ValueKey('orderConfirmationCard')))
                  .top,
            ),
          );
          expect(
            tester
                .getRect(find.byKey(const ValueKey('orderConfirmationCard')))
                .bottom,
            lessThanOrEqualTo(844 - 34),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets(
      'preview explains backend validation failures instead of hiding them ($language)',
      (tester) async {
        final repository = PackageOrders()
          ..previewError = const ApiException(
            ApiFailure.validation,
            statusCode: 400,
            code: 'invalid_resume_date',
            message: 'Restart date is invalid',
          );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: PackageManagementPanel(orderId: 'order'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final copy = lookupAppLocalizations(Locale(language));
        await tester.tap(find.byKey(const ValueKey('pausePackage-order')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(
            MaterialLocalizations.of(
              tester.element(find.byType(CalendarDatePicker)),
            ).okButtonLabel,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(copy.packagePreviewPause));
        await tester.pumpAndSettle();
        expect(find.text(copy.packageInvalidRestart), findsOneWidget);
        expect(find.text(copy.packageScheduleChanged), findsNothing);
        expect(repository.commands, isEmpty);
        expect(find.text(copy.packageConfirmPause), findsNothing);
      },
    );

    testWidgets(
      'picker excludes committed dates; preview never writes; network retry reuses the pause command ($language)',
      (tester) async {
        final repository = PackageOrders()..failOnce = true;
        final container = ProviderContainer(
          overrides: [
            ordersRepositoryProvider.overrideWithValue(repository),
            customerDashboardControllerProvider.overrideWith(
              PackageDashboard.new,
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: PackageManagementPanel(orderId: 'order'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final copy = lookupAppLocalizations(Locale(language));
        await tester.tap(find.byKey(const ValueKey('pausePackage-order')));
        await tester.pumpAndSettle();
        final picker = tester.widget<CalendarDatePicker>(
          find.byType(CalendarDatePicker),
        );
        expect(picker.firstDate, DateTime(2026, 11, 5));
        expect(picker.initialDate, DateTime(2026, 11, 5));
        expect(picker.lastDate, DateTime(2027, 5, 2));
        expect(picker.lastDate.isAfter(DateTime(2026, 11, 12)), isTrue);
        expect(picker.selectableDayPredicate, isNull);
        final nativeCopy = MaterialLocalizations.of(
          tester.element(find.byType(CalendarDatePicker)),
        );
        await tester.tap(find.text(nativeCopy.okButtonLabel));
        await tester.pumpAndSettle();
        expect(repository.commands, isEmpty);
        await tester.tap(find.text(copy.packagePreviewPause));
        await tester.pumpAndSettle();
        expect(repository.previews, 1);
        expect(repository.previewStarts, [DateTime(2026, 11, 4)]);
        expect(repository.commands, isEmpty);
        expect(find.text('${copy.packageAffectedDays}: 1'), findsOneWidget);
        expect(find.text('${copy.packageRescheduledDays}: 8'), findsOneWidget);
        expect(find.text(copy.packagePreserveDays), findsOneWidget);
        await tester.tap(find.text(copy.packageConfirmPause));
        await tester.pumpAndSettle();
        expect(find.text(copy.packageScheduleChanged), findsOneWidget);
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text(copy.packageConfirmPause));
        await tester.pumpAndSettle();
        expect(repository.commands.length, 2);
        expect(
          repository.confirmedStarts.every((d) => d == DateTime(2026, 11, 4)),
          isTrue,
        );
        expect(repository.commands.first, repository.commands.last);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text(copy.packagePauseScheduled), findsOneWidget);
        expect(container.read(packageScheduleChangesProvider), {'order': 1});
        await tester.tap(find.text(copy.packageResumeEarly));
        await tester.pumpAndSettle();
        final restartPicker = tester.widget<CalendarDatePicker>(
          find.byType(CalendarDatePicker),
        );
        expect(restartPicker.firstDate, DateTime(2026, 11, 3));
        expect(restartPicker.lastDate, DateTime(2027, 5, 2));
        await tester.tap(
          find.text(
            MaterialLocalizations.of(
              tester.element(find.byType(CalendarDatePicker)),
            ).okButtonLabel,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, copy.packageResumeEarly),
        );
        await tester.pumpAndSettle();
        expect(repository.resumes, 1);
        expect(
          find.byKey(const ValueKey('pausePackage-order')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('no eligible days disables pause and explains why', (
    tester,
  ) async {
    final repository = PackageOrders()..available = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: PackageManagementPanel(orderId: 'order')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('pausePackage-order')),
    );
    expect(button.onPressed, isNull);
    expect(
      find.text(lookupAppLocalizations(const Locale('en')).packageUnavailable),
      findsOneWidget,
    );
  });
}
