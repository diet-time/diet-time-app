import 'package:diet_time/features/dashboard/presentation/customer_profile_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('profile navigation rows fit a compact phone and open screens', (
    tester,
  ) async {
    var customerProfileOpened = false;
    var questionnaireOpened = false;
    var addressOpened = false;
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: CustomerProfileTab(
              onBack: () {},
              onEditAddress: () => addressOpened = true,
              onEditProfile: () => customerProfileOpened = true,
              onQuestionnaire: () => questionnaireOpened = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Profile'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('customerProfileOption')));
    expect(customerProfileOpened, isTrue);
    await tester.tap(find.byKey(const ValueKey('customerQuestionnaireOption')));
    expect(questionnaireOpened, isTrue);
    await tester.tap(find.byKey(const ValueKey('customerAddressOption')));
    expect(addressOpened, isTrue);

    expect(find.text('PERSONAL INFORMATION'), findsNothing);
    expect(find.text('DELIVERY ADDRESS'), findsNothing);
    expect(find.text('Add or edit your delivery address'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
