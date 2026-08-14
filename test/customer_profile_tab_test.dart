import 'package:diet_time/features/checkout/domain/checkout_models.dart';
import 'package:diet_time/features/dashboard/presentation/customer_profile_tab.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('customer profile reference layout fits a compact phone', (
    tester,
  ) async {
    var questionnaireOpened = false;
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: CustomerProfileTab(
              profile: const CustomerProfile(
                preferredName: 'Customer',
                dateOfBirth: '1990-05-12',
                genderCode: 'MALE',
              ),
              phoneNumber: '+971 50 123 4567',
              address: _address,
              onBack: () {},
              onEditAddress: () {},
              onEditProfile: () {},
              onQuestionnaire: () => questionnaireOpened = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Customer Profile'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('customerQuestionnaireOption')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('customerQuestionnaireOption')));
    expect(questionnaireOpened, isTrue);
    expect(find.text('PERSONAL INFORMATION'), findsOneWidget);
    expect(find.text('12 May 1990'), findsOneWidget);
    expect(find.text('Default ✓'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('editCustomerProfile')),
      150,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _address = CustomerDeliveryAddress(
  id: 'address-id',
  addressName: 'Home',
  addressType: DeliveryAddressType.home,
  buildingNo: '1204',
  streetNo: '42',
  zoneNo: '7',
  area: 'Dubai Marina',
  latitude: 25.08,
  longitude: 55.14,
  formattedAddress: 'Dubai, UAE',
  unitNumber: '1204',
  isDefault: true,
);
