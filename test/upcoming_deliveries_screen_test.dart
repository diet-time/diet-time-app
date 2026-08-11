import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/presentation/upcoming_deliveries_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows selectable customer delivery dates and order details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: UpcomingDeliveriesScreen(order: _order())),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('upcomingDeliveriesScreen')),
      findsOneWidget,
    );
    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('Delivery days'), findsOneWidget);
    expect(find.text('Morning'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.textContaining('Building 126'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

OrderConfirmation _order() => OrderConfirmation.fromJson({
  'id': 'order-id',
  'orderNumber': 'ORD-1',
  'status': 'ACTIVE',
  'paymentStatus': 'PAID',
  'plan': {'name': 'Classic Plan', 'durationName': '1 Month'},
  'meals': [
    {'id': 'lunch', 'name': 'Lunch', 'quantity': 1},
    {'id': 'dinner', 'name': 'Dinner', 'quantity': 1},
  ],
  'delivery': {
    'daysPerWeek': 5,
    'days': [1, 2, 3, 4, 5],
    'startDate': '2026-08-11',
    'endDate': '2026-09-05',
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
  'pricing': {'totalAmount': 100, 'currencyCode': 'QAR'},
});
