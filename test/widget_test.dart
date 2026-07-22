import 'package:diet_time/app/app.dart';
import 'package:diet_time/features/onboarding/presentation/onboarding_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tap and swipe update the same onboarding page index', (
    tester,
  ) async {
    await tester.pumpWidget(_onboardingApp());

    expect(find.text('Healthy Meals,'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(find.text('Next'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('onboardingTapArea-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Plans That Fit'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Fresh. Clean.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding automatically advances to the next page', (
    tester,
  ) async {
    await tester.pumpWidget(_onboardingApp());

    expect(find.text('Healthy Meals,'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Plans That Fit'), findsOneWidget);
  });

  testWidgets('language selection opens before onboarding', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await _finishSplash(tester);

    expect(find.text('Choose your Language'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('Healthy Meals,'), findsNothing);
  });

  testWidgets('language preference is saved before onboarding opens', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await _finishSplash(tester);

    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('preferredLanguage'), 'en');
    expect(find.text('Healthy Meals,'), findsOneWidget);
  });

  testWidgets('final onboarding tap opens login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await _finishSplash(tester);
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    for (var index = 0; index < 6; index++) {
      await tester.tap(find.byKey(ValueKey('onboardingTapArea-$index')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('compact onboarding has no overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_onboardingApp());

    expect(find.text('Healthy Meals,'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic selection persists and makes onboarding RTL', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await _finishSplash(tester);

    await tester.tap(find.text('العربية'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('preferredLanguage'), 'ar');
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(OnboardingScreen))),
      TextDirection.rtl,
    );
  });
}

Future<void> _finishSplash(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 5700));
  await tester.pump(const Duration(milliseconds: 400));
}

Widget _onboardingApp() {
  return const MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: OnboardingScreen(),
  );
}
