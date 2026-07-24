import 'package:diet_time/app/app.dart';
import 'package:diet_time/features/language/presentation/language_selection_screen.dart';
import 'package:diet_time/features/menu/presentation/browse_menu_screen.dart';
import 'package:diet_time/features/onboarding/presentation/onboarding_screen.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_screen.dart';
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
    expect(find.byType(LanguageSelectionScreen), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('Healthy Meals,'), findsNothing);
  });

  testWidgets('language preference is saved before onboarding opens', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await _finishSplash(tester);

    await _chooseLanguage(tester, 'English');

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('preferredLanguage'), 'en');
    expect(find.text('Healthy Meals,'), findsOneWidget);
  });

  testWidgets('complete first-run flow opens menu, plans, then login', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await _finishSplash(tester);
    await _chooseLanguage(tester, 'English');

    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(ValueKey('onboardingTapArea-$index')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(BrowseMenuScreen), findsOneWidget);

    await tester.tap(find.text('Browse Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MealPlanScreen), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('saved language skips language selection on later launches', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'preferredLanguage': 'en'});
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await _finishSplash(tester);

    expect(find.byType(LanguageSelectionScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Healthy Meals,'), findsOneWidget);
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

    await _chooseLanguage(tester, 'العربية');

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

Future<void> _chooseLanguage(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 400));
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
