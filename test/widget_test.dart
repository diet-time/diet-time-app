import 'package:diet_time/app/app.dart';
import 'package:diet_time/features/authentication/presentation/login_screen.dart';
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

  testWidgets('final onboarding tap opens language selection', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await tester.pump(const Duration(milliseconds: 5700));
    await tester.pump(const Duration(milliseconds: 400));

    for (var index = 0; index < 6; index++) {
      await tester.tap(find.byKey(ValueKey('onboardingTapArea-$index')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Choose your Language'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
  });

  testWidgets('language preference is saved before login opens', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await tester.pump(const Duration(milliseconds: 5700));
    await tester.pump(const Duration(milliseconds: 400));

    for (var index = 0; index < 6; index++) {
      await tester.tap(find.byKey(ValueKey('onboardingTapArea-$index')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('preferredLanguage'), 'en');
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('compact onboarding has no overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_onboardingApp());

    expect(find.text('Healthy Meals,'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic selection persists and makes login RTL', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await tester.pump(const Duration(milliseconds: 5700));
    await tester.pump(const Duration(milliseconds: 400));

    for (var index = 0; index < 6; index++) {
      await tester.tap(find.byKey(ValueKey('onboardingTapArea-$index')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('العربية'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('preferredLanguage'), 'ar');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(LoginScreen))),
      TextDirection.rtl,
    );
  });
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
