import 'package:diet_time/app/app.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:diet_time/features/authentication/presentation/phone_login_page.dart';
import 'package:diet_time/features/language/presentation/language_selection_screen.dart';
import 'package:diet_time/features/menu/presentation/browse_menu_screen.dart';
import 'package:diet_time/features/onboarding/presentation/onboarding_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('onboarding moves through steps and preserves goal selection', (
    tester,
  ) async {
    await tester.pumpWidget(_onboardingApp());

    expect(find.text('Welcome to Diet Time'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboardingProgress')), findsOneWidget);

    await _advance(tester);
    expect(find.text('What would you like to achieve?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('goal-muscle')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedContainer>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('goal-muscle')),
                  matching: find.byType(AnimatedContainer),
                )
                .first,
          )
          .decoration,
      isNotNull,
    );

    await tester.drag(
      find.byKey(const ValueKey('onboardingPageView')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text("Let's get to know you"), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboardingPrevious')));
    await tester.pumpAndSettle();
    expect(find.text('Build Muscle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile values use an iOS wheel picker bottom sheet', (
    tester,
  ) async {
    await tester.pumpWidget(_onboardingApp());
    await _advance(tester);
    await _advance(tester);

    await tester.tap(find.byKey(const ValueKey('profileAge')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboardingWheelPicker')), findsOneWidget);
    expect(find.byType(CupertinoPicker), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preference and allergy chips support multiple selections', (
    tester,
  ) async {
    await tester.pumpWidget(_onboardingApp());
    for (var index = 0; index < 5; index++) {
      await _advance(tester);
    }

    expect(find.text('What do you enjoy eating?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('choice-protein')));
    await tester.tap(find.byKey(const ValueKey('choice-seafood')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilterChip>(find.byKey(const ValueKey('choice-protein')))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(find.byKey(const ValueKey('choice-seafood')))
          .selected,
      isTrue,
    );

    await _advance(tester);
    await tester.tap(find.byKey(const ValueKey('choice-milk')));
    await tester.tap(find.byKey(const ValueKey('choice-none')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilterChip>(find.byKey(const ValueKey('choice-none')))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(find.byKey(const ValueKey('choice-milk')))
          .selected,
      isFalse,
    );
  });

  testWidgets('language selection opens before onboarding', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await _finishSplash(tester);

    expect(find.text('Choose your Language'), findsOneWidget);
    expect(find.byType(LanguageSelectionScreen), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('Welcome to Diet Time'), findsNothing);
  });

  testWidgets('language preference is saved before onboarding opens', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await _finishSplash(tester);
    await _chooseLanguage(tester, 'English');

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('preferredLanguage'), 'en');
    expect(preferences.getBool('languageSelectionCompletedV2'), isTrue);
    expect(find.text('Welcome to Diet Time'), findsOneWidget);
  });

  testWidgets('final plan-building screen reveals choices without waiting', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await _finishSplash(tester);
    await _chooseLanguage(tester, 'English');
    await _reachBuildingStep(tester);

    expect(find.text('Creating your personalized meal plan'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboardingPlanProgress')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('onboardingMenuChoice')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('onboardingContinue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('onboardingFinalChoicePanel')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('onboardingMenuChoice')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboardingPlanChoice')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('onboardingPlanChoice'))).height,
      AppButton.height,
    );

    await tester.tap(find.byKey(const ValueKey('onboardingMenuChoice')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(BrowseMenuScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('guestMenuBack')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guestMenuBack')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(OnboardingScreen), findsOneWidget);
    final menuButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('onboardingMenuChoice')),
    );
    expect(menuButton.onPressed, isNotNull);
  });

  testWidgets('returning from plan login re-enables final actions', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await _finishSplash(tester);
    await _chooseLanguage(tester, 'English');
    await _reachBuildingStep(tester);
    await tester.tap(find.byKey(const ValueKey('onboardingContinue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const ValueKey('onboardingPlanChoice')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PhoneLoginPage), findsOneWidget);
    expect(find.text("Let's Get Started"), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('otpFlowBack')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(OnboardingScreen), findsOneWidget);
    final planButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('onboardingPlanChoice')),
        matching: find.byType(FilledButton),
      ),
    );
    final menuButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('onboardingMenuChoice')),
    );
    expect(planButton.onPressed, isNotNull);
    expect(menuButton.onPressed, isNotNull);
  });

  testWidgets('saved language skips language selection on later launches', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'preferredLanguage': 'en',
      'languageSelectionCompletedV2': true,
    });
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await _finishSplash(tester);

    expect(find.byType(LanguageSelectionScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Welcome to Diet Time'), findsOneWidget);
  });

  testWidgets('older saved language still shows the language sheet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'preferredLanguage': 'en'});
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await _finishSplash(tester);

    expect(find.byType(LanguageSelectionScreen), findsOneWidget);
    expect(find.text('Choose your Language'), findsOneWidget);
  });

  testWidgets('all onboarding steps avoid overflow on a compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_onboardingApp());

    for (var index = 0; index < 7; index++) {
      expect(tester.takeException(), isNull);
      await _advance(tester);
    }
    expect(find.byKey(const ValueKey('onboardingStep-7')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('final choices wrap without overflow on a narrow phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_onboardingApp());
    await _reachBuildingStep(tester);
    await tester.tap(find.byKey(const ValueKey('onboardingContinue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('onboardingMenuChoice')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboardingPlanChoice')), findsOneWidget);
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
    expect(preferences.getBool('languageSelectionCompletedV2'), isTrue);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(OnboardingScreen))),
      TextDirection.rtl,
    );
    expect(find.text('مرحباً بك في دايت تايم'), findsOneWidget);
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

Future<void> _advance(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('onboardingContinue')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _reachBuildingStep(WidgetTester tester) async {
  for (var index = 0; index < 7; index++) {
    await _advance(tester);
  }
}

Widget _onboardingApp() {
  return const ProviderScope(
    child: MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: OnboardingScreen(),
    ),
  );
}
