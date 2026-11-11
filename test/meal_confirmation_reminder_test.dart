import 'package:diet_time/features/dashboard/domain/tomorrow_menu.dart';
import 'package:diet_time/features/dashboard/presentation/tomorrow_delivery_card.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tomorrow_deliveries_section_test.dart' as fixtures;

Widget reminderApp(
  TomorrowMenu menu, {
  bool reducedMotion = false,
  bool animate = true,
  bool expired = false,
  String language = 'en',
  VoidCallback? onShown,
}) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: TomorrowDeliveryCard(
        menu: menu,
        draft: TomorrowMealDraft(menu),
        orderReference: 'hidden-order',
        showDishes: false,
        expired: expired,
        onChoose: () {},
        onToggleDishes: () {},
        onRefresh: () {},
        animateReminder: animate,
        onReminderShown: onShown,
      ),
    ),
  ),
);

double breathingScale(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(const ValueKey('mealConfirmationBreathing')))
    .transform
    .storage[0];

void main() {
  testWidgets(
    'reminder breathes twice, stops, and rebuilds do not restart it',
    (tester) async {
      final menu = fixtures.delivery('a', complete: true, hasPlanImage: false);
      var shown = 0;
      await tester.pumpWidget(reminderApp(menu, onShown: () => shown++));
      expect(find.text('Meals Confirmed'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1400));
      expect(breathingScale(tester), closeTo(1.012, .0001));
      await tester.pump(const Duration(milliseconds: 1400));
      expect(breathingScale(tester), closeTo(1, .0001));
      await tester.pump(const Duration(milliseconds: 1400));
      expect(breathingScale(tester), closeTo(1.012, .0001));
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pump();
      expect(breathingScale(tester), closeTo(1, .0001));
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(reminderApp(menu, onShown: () => shown++));
      await tester.pump(const Duration(milliseconds: 1400));
      expect(shown, 1);
      expect(breathingScale(tester), closeTo(1, .0001));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final reduced in [false, true]) {
    testWidgets(
      'confirmed response replaces reminder and button (reduced motion: $reduced)',
      (tester) async {
        await tester.pumpWidget(
          reminderApp(
            fixtures.delivery('a', complete: true, hasPlanImage: false),
            reducedMotion: reduced,
          ),
        );
        await tester.pump(const Duration(milliseconds: 1400));
        if (reduced) {
          expect(breathingScale(tester), 1);
          expect(tester.binding.transientCallbackCount, 0);
        }
        await tester.pumpWidget(
          reminderApp(
            fixtures.delivery('a', confirmed: true, hasPlanImage: false),
            reducedMotion: reduced,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Meals Confirmed'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('mealConfirmationReminder')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('chooseTomorrowMeals')), findsNothing);
        expect(find.text('View confirmed meals'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('configured cutoff is formatted in Qatar time', (tester) async {
    await tester.pumpWidget(
      reminderApp(
        fixtures.delivery(
          'a',
          complete: true,
          hasPlanImage: false,
          cutoffAt: DateTime.utc(2026, 10, 28, 17, 30),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Confirm your meals by 8:30 PM'), findsOneWidget);
    expect(find.textContaining('9:00 PM'), findsNothing);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('reminder fits a small phone in $language', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        reminderApp(
          fixtures.delivery('a', complete: true, hasPlanImage: false),
          language: language,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('mealConfirmationReminder')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final status in [
    'DEFAULT_PENDING',
    'LOCKED',
    'AUTO_FINALIZED',
    'NO_DELIVERY',
    'PAUSED',
  ]) {
    testWidgets('$status does not imply confirmation or animate', (
      tester,
    ) async {
      final menu = fixtures.delivery(
        'a',
        hasPlanImage: false,
        confirmed: status == 'LOCKED' || status == 'AUTO_FINALIZED',
        noDelivery: status == 'NO_DELIVERY' || status == 'PAUSED',
        selectionStatus: status,
      );
      await tester.pumpWidget(reminderApp(menu));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('mealConfirmationReminder')),
        findsNothing,
      );
      expect(find.text('Meals Confirmed'), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
    });
  }

  testWidgets('expired selection has no confirmation action', (tester) async {
    await tester.pumpWidget(
      reminderApp(
        fixtures.delivery('a', complete: true, hasPlanImage: false),
        expired: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mealConfirmationReminder')),
      findsNothing,
    );
    expect(find.text('Review & Confirm Meals'), findsNothing);
    expect(find.text('Meals Confirmed'), findsNothing);
  });
}
