import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/personalization/data/display_name_repository.dart';
import 'package:diet_time/features/personalization/presentation/authenticated_landing_screen.dart';
import 'package:diet_time/features/personalization/presentation/display_name_panel.dart';
import 'package:diet_time/app/app.dart';
import 'package:go_router/go_router.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_screen.dart';
import 'package:diet_time/features/authentication/data/mock_authentication_service.dart';
import 'package:diet_time/features/authentication/presentation/login_screen.dart';
import 'package:diet_time/features/authentication/presentation/phone_login_page.dart';
import 'package:diet_time/features/home/presentation/home_screen.dart';
import 'package:diet_time/features/language/data/language_repository.dart';
import 'package:diet_time/features/language/presentation/language_selection_panel.dart';
import 'package:diet_time/features/language/presentation/language_selection_screen.dart';
import 'package:diet_time/features/menu/presentation/browse_menu_screen.dart';
import 'package:diet_time/features/onboarding/presentation/onboarding_carousel_screen.dart';
import 'package:diet_time/features/onboarding/presentation/onboarding_screen.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('first launch keeps the original onboarding carousel', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const OnboardingCarouselScreen()));

    expect(find.text('Healthy Meals,'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboardingCarousel')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assets/images/onboarding_1.png')),
      findsOneWidget,
    );
    expect(find.byType(PersonalizationScreen), findsNothing);

    await tester.tap(find.byKey(const ValueKey('onboardingTapArea-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Plans That Fit'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('onboardingCarousel')),
      const Offset(-500, 0),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Fresh. Clean.'), findsOneWidget);
  });

  testWidgets('active onboarding image progress fills over time', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const OnboardingCarouselScreen()));
    await tester.pump(const Duration(milliseconds: 1400));

    final progress = tester.widget<FractionallySizedBox>(
      find.descendant(
        of: find.byKey(const ValueKey('onboardingImageProgress-0')),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(progress.widthFactor, greaterThan(.35));
    expect(progress.widthFactor, lessThan(.65));
  });

  testWidgets('all five onboarding image assets remain available', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const OnboardingCarouselScreen()));

    for (var index = 0; index < 5; index++) {
      expect(
        find.byKey(ValueKey('assets/images/onboarding_${index + 1}.png')),
        findsOneWidget,
      );
      if (index == 4) break;
      await tester.tap(
        find.byKey(ValueKey('onboardingTapArea-$index')).hitTestable(),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  });

  testWidgets('final onboarding page shows menu and start plan actions', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const OnboardingCarouselScreen()));
    await _reachCarouselEnd(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('onboardingFinalChoicePanel')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('onboardingMenuChoice')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboardingPlanChoice')), findsOneWidget);
  });

  testWidgets('new guest sees the five-image onboarding after language', (
    tester,
  ) async {
    await tester.pumpWidget(_dietTimeApp());
    await _finishSplash(tester);
    expect(find.byType(LanguageSelectionPanel), findsOneWidget);
    await _chooseLanguage(tester, 'English');

    expect(find.byType(OnboardingCarouselScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('onboardingCarousel')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assets/images/onboarding_1.png')),
      findsOneWidget,
    );
    expect(find.byType(PersonalizationScreen), findsNothing);
    expect(find.byType(PhoneLoginPage), findsNothing);
  });

  testWidgets('saved language does not skip an unfinished image onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'preferredLanguage': 'en',
      'languageSelectionCompletedV2': true,
    });
    await tester.pumpWidget(_dietTimeApp());
    await _finishSplash(tester);

    expect(find.byType(LanguageSelectionPanel), findsNothing);
    expect(find.byType(OnboardingCarouselScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('onboardingCarousel')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assets/images/onboarding_1.png')),
      findsOneWidget,
    );
  });

  testWidgets('carousel start plan prompts login before plan selection', (
    tester,
  ) async {
    await tester.pumpWidget(_dietTimeApp());
    await _finishSplash(tester);
    await _chooseLanguage(tester, 'English');
    await _reachCarouselEnd(tester);
    await tester.tap(
      find.byKey(const ValueKey('onboardingPlanChoice')).hitTestable(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pumpAndSettle();
    expect(find.byType(MealPlanScreen), findsNothing);
    expect(find.byType(PhoneLoginPage), findsOneWidget);
  });

  testWidgets('goal selection is required and preserved when navigating back', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const PersonalizationScreen()));
    expect(
      find.byKey(const ValueKey('onboardingLanguageSelector')),
      findsNothing,
    );
    await _continue(tester);

    expect(find.text('What would you like to achieve?'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    await _continue(tester);
    expect(find.text('Choose an option to continue.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('goal-lose')).hitTestable());
    await tester.pump(const Duration(milliseconds: 250));
    await _continue(tester);
    expect(find.text("Let's get to know you"), findsOneWidget);
    expect(find.text('17%'), findsOneWidget);
    await _continue(tester);
    expect(find.text('Choose an option to continue.'), findsOneWidget);
    expect(find.text("Let's get to know you"), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboardingPrevious')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final selected = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byKey(const ValueKey('goal-lose')),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(selected.decoration, isNotNull);
  });

  testWidgets('customer profile questionnaire reopens saved answers', (
    tester,
  ) async {
    final service = _FakeProfilePersistenceService(
      profile: const CustomerProfile(
        preferredName: 'Noor',
        profileId: 'profile-id',
        genderCode: 'FEMALE',
        dateOfBirth: '1990-05-12',
        heightCm: 165,
        weightKg: 60,
        goalCode: 'MAINTAIN_WEIGHT',
        dailyRoutineCode: 'OFFICE_WORK',
        activityLevelCode: 'MOSTLY_SITTING',
        preferences: {'HIGH_PROTEIN', 'INTERNATIONAL', 'MEDITERRANEAN'},
        allergens: {'NONE'},
        preferencesConfirmed: true,
        allergensConfirmed: true,
        nextStepCode: 'PROFILE_COMPLETED',
        completionPercentage: 100,
        shouldShowOnboarding: false,
      ),
    );
    await tester.pumpWidget(
      _localizedApp(
        const PersonalizationScreen(customerProfileMode: true),
        profileService: service,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PersonalizationScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('onboardingHeaderBack')), findsOneWidget);
    await _continue(tester);
    final selectedGoal = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('goal-maintain')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect((selectedGoal.decoration! as BoxDecoration).gradient, isNotNull);
    for (var step = 0; step < 4; step++) {
      await _continue(tester);
    }
    expect(find.text('What do you enjoy eating?'), findsOneWidget);
    expect(find.text('International'), findsNothing);
    expect(find.text('Mediterranean'), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PersonalizationScreen)),
    );
    expect(
      container.read(personalizationControllerProvider).preferences,
      contains('INTERNATIONAL'),
    );
    expect(
      container.read(personalizationControllerProvider).preferences,
      contains('MEDITERRANEAN'),
    );
  });

  testWidgets(
    'authenticated questionnaire checkpoints answers and continues to checkout',
    (tester) async {
      final profileService = _FakeProfilePersistenceService();
      await tester.pumpWidget(_questionnaireCheckoutApp(profileService));
      await tester.pump();

      // BASIC_DETAILS and BODY_MEASUREMENTS share the existing profile card.
      await _continue(tester);
      await tester.tap(find.byKey(const ValueKey('goal-lose')).hitTestable());
      await _continue(tester);
      await _fillRequiredProfile(tester);
      await _continue(tester);
      await tester.tap(
        find.byKey(const ValueKey('lifestyle-office')).hitTestable(),
      );
      await _continue(tester);
      await tester.tap(
        find.byKey(const ValueKey('activity-sitting')).hitTestable(),
      );
      await _continue(tester);
      expect(profileService.saveProgressCalls, 4);
      expect(profileService.completeCalls, 0);
      await tester.tap(find.byKey(const ValueKey('choice-HIGH_PROTEIN')));
      await _continue(tester);
      expect(profileService.saveProgressCalls, 5);
      expect(profileService.completeCalls, 0);
      await tester.tap(find.byKey(const ValueKey('choice-none')));
      await _continue(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(profileService.saveProgressCalls, 5);
      expect(profileService.completeCalls, 1);
      expect(profileService.lastSubmitted?.goalCode, 'LOSE_WEIGHT');
      expect(profileService.lastSubmitted?.dailyRoutineCode, 'OFFICE_WORK');
      expect(profileService.lastSubmitted?.activityLevelCode, 'MOSTLY_SITTING');
      expect(profileService.lastSubmitted?.preferencesConfirmed, isTrue);
      expect(profileService.lastSubmitted?.allergensConfirmed, isTrue);
      expect(find.byKey(const ValueKey('bmiRange')), findsOneWidget);
      expect(find.byKey(const ValueKey('bmiScaleMarker')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('bmiScaleIndicatorDot')),
        findsOneWidget,
      );
      final indicatorRect = tester.getRect(
        find.byKey(const ValueKey('bmiScaleIndicatorDot')),
      );
      final bmiCardRect = tester.getRect(
        find.byKey(const ValueKey('bmiRange')),
      );
      expect(indicatorRect.size, const Size(22, 22));
      expect(bmiCardRect.overlaps(indicatorRect), isTrue);
      expect(find.text('24.2'), findsWidgets);
      await _continue(tester);
      expect(find.text("You're all set!"), findsOneWidget);
      expect(find.byKey(const ValueKey('personalizationGoHome')), findsNothing);
      await _continue(tester);
      expect(find.text('Checkout ready'), findsOneWidget);
      expect(find.byType(PhoneLoginPage), findsNothing);
    },
  );

  testWidgets(
    'Start Your Plan resumes saved answers and continues to plan selection',
    (tester) async {
      final service = _FakeProfilePersistenceService(
        profile: const CustomerProfile(
          preferredName: 'Noor',
          profileId: 'profile-id',
          goalCode: 'LOSE_WEIGHT',
          genderCode: 'FEMALE',
          dateOfBirth: '1995-03-17',
          heightCm: 165.5,
          weightKg: 70.4,
          dailyRoutineCode: 'OFFICE_WORK',
          activityLevelCode: 'MOSTLY_SITTING',
          preferences: {'HIGH_PROTEIN'},
          preferencesConfirmed: true,
          allergens: {'MILK'},
          nextStepCode: 'ALLERGENS',
        ),
      );
      await tester.pumpWidget(
        _questionnaireCheckoutApp(service, startPlan: true),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('onboardingStep-6')), findsOneWidget);
      await _continue(tester);
      await tester.pumpAndSettle();
      expect(service.completeCalls, 1);
      expect(service.lastSubmitted!.dateOfBirth, '1995-03-17');
      expect(service.lastSubmitted!.heightCm, 165.5);
      expect(service.lastSubmitted!.weightKg, 70.4);
      expect(service.lastSubmitted!.allergens, {'MILK'});
      expect(service.lastSubmitted!.preferences, {'HIGH_PROTEIN'});
      expect(service.lastSubmitted!.allergensConfirmed, isTrue);
      expect(find.text('Plan selection ready'), findsOneWidget);
      expect(find.byType(PersonalizationScreen), findsNothing);
      expect(find.byType(PhoneLoginPage), findsNothing);
    },
  );

  testWidgets(
    'missing profile collects name then goal and basic details in order',
    (tester) async {
      final service = _FakeProfilePersistenceService();
      await tester.pumpWidget(
        _questionnaireCheckoutApp(service, accountSetup: true),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DisplayNamePanel), findsOneWidget);
      expect(find.byType(PersonalizationScreen), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('displayNameInput')),
        'Noor',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('displayNameContinue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('onboardingStep-1')), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(service.saveProgressCalls, 0);
      await tester.tap(find.byKey(const ValueKey('goal-lose')).hitTestable());
      service.failSave = true;
      await _continue(tester);
      expect(find.byKey(const ValueKey('onboardingStep-1')), findsOneWidget);
      expect(find.text('Dashboard ready'), findsNothing);
      expect(service.profile!.goalCode, isNull);
      service.failSave = false;
      await _continue(tester);
      expect(find.byKey(const ValueKey('onboardingStep-2')), findsOneWidget);
      expect(find.text('17%'), findsOneWidget);
      await _fillRequiredProfile(tester);
      await _continue(tester);
      await tester.tap(
        find.byKey(const ValueKey('lifestyle-office')).hitTestable(),
      );
      await _continue(tester);
      await tester.tap(
        find.byKey(const ValueKey('activity-sitting')).hitTestable(),
      );
      await _continue(tester);
      await tester.tap(find.byKey(const ValueKey('choice-HIGH_PROTEIN')));
      await _continue(tester);
      await tester.tap(find.byKey(const ValueKey('choice-none')));
      await _continue(tester);
      await tester.pumpAndSettle();
      expect(service.completeCalls, 1);
      expect(service.profile!.isCompleted, isTrue);
      expect(find.text('Dashboard ready'), findsOneWidget);
      expect(find.byType(PersonalizationScreen), findsNothing);
      expect(find.byType(PhoneLoginPage), findsNothing);
    },
  );

  testWidgets('returning incomplete guest still sees image onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'preferredLanguage': 'en',
      'languageSelectionCompletedV2': true,
      'hasCompletedOnboarding': true,
    });
    await tester.pumpWidget(_dietTimeApp());
    await _finishSplash(tester);

    expect(find.byType(LanguageSelectionPanel), findsNothing);
    expect(find.byType(OnboardingCarouselScreen), findsOneWidget);
    expect(find.byType(PersonalizationScreen), findsNothing);
    expect(find.byType(BrowseMenuScreen), findsNothing);
  });

  testWidgets('completed returning guest still sees image onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'preferredLanguage': 'en',
      'languageSelectionCompletedV2': true,
      'hasCompletedOnboarding': true,
    });
    await tester.pumpWidget(_dietTimeApp());
    await _finishSplash(tester);

    expect(find.byType(LanguageSelectionPanel), findsNothing);
    expect(find.byType(OnboardingCarouselScreen), findsOneWidget);
    expect(find.byType(BrowseMenuScreen), findsNothing);
    expect(find.byType(PersonalizationScreen), findsNothing);
  });

  testWidgets('restored new user opens profile creation before dashboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'preferredLanguage': 'en',
      'languageSelectionCompletedV2': true,
      'hasCompletedOnboarding': true,
      'hasCompletedProfile': false,
    });
    await tester.pumpWidget(
      _dietTimeApp(authenticationService: const _AuthenticatedService()),
    );
    await _finishSplash(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LanguageSelectionPanel), findsNothing);
    expect(find.byType(OnboardingCarouselScreen), findsNothing);
    expect(find.byType(DisplayNamePanel), findsOneWidget);
    expect(find.byType(PersonalizationScreen), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(MealPlanScreen), findsNothing);
    expect(find.byType(PhoneLoginPage), findsNothing);
  });

  testWidgets('restored customer without active orders opens dashboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'preferredLanguage': 'en',
      'languageSelectionCompletedV2': true,
      'hasCompletedOnboarding': true,
      'hasCompletedPersonalization': true,
      'hasCompletedProfile': true,
    });
    await tester.pumpWidget(
      _dietTimeApp(
        authenticationService: const _AuthenticatedService(),
        profileService: _FakeProfilePersistenceService(
          profile: const CustomerProfile(
            preferredName: 'Noor',
            profileId: 'profile-id',
            genderCode: 'FEMALE',
            dateOfBirth: '1995-03-17',
            heightCm: 165,
            weightKg: 70,
            goalCode: 'LOSE_WEIGHT',
            dailyRoutineCode: 'OFFICE_WORK',
            activityLevelCode: 'MOSTLY_SITTING',
            onboardingStatus: 'COMPLETED',
            nextStepCode: 'PROFILE_COMPLETED',
            completionPercentage: 100,
            shouldShowOnboarding: false,
          ),
        ),
      ),
    );
    await _finishSplash(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(MealPlanScreen), findsNothing);
    expect(find.byType(LanguageSelectionPanel), findsNothing);
    expect(find.byType(OnboardingCarouselScreen), findsNothing);
    expect(find.byType(PersonalizationScreen), findsNothing);
  });

  testWidgets('login excludes language and social sign-in controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(const LoginScreen(showLoginInitially: true)),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Language'), findsNothing);
    expect(find.byIcon(Icons.apple), findsNothing);
    expect(find.byIcon(Icons.g_mobiledata_rounded), findsNothing);
    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('Arabic carousel and personalization remain RTL', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        const OnboardingCarouselScreen(),
        locale: const Locale('ar'),
      ),
    );
    expect(
      Directionality.of(tester.element(find.byType(OnboardingCarouselScreen))),
      TextDirection.rtl,
    );
    expect(find.text('وجبات صحية،'), findsOneWidget);
  });

  testWidgets('personalization does not overflow on a compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_localizedApp(const PersonalizationScreen()));
    expect(find.text("Let's shape your plan"), findsOneWidget);
    await _continue(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first launch shows a compact language action panel', (
    tester,
  ) async {
    await tester.pumpWidget(_dietTimeApp());
    await _finishSplash(tester);

    expect(find.byType(LanguageSelectionPanel), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(LanguageSelectionScreen), findsNothing);
    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('اختر لغتك'), findsOneWidget);
    expect(find.byType(OnboardingCarouselScreen), findsNothing);
  });

  testWidgets('authentication does not bypass first-launch language panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      _dietTimeApp(authenticationService: const _AuthenticatedService()),
    );
    await _finishSplash(tester);

    expect(find.byType(LanguageSelectionPanel), findsOneWidget);
    expect(find.byType(LanguageSelectionScreen), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(PersonalizationScreen), findsNothing);
  });

  testWidgets('language panel requires a selection and persists English', (
    tester,
  ) async {
    await tester.pumpWidget(_dietTimeApp());
    await _finishSplash(tester);

    final continueFinder = find.descendant(
      of: find.byKey(const ValueKey('languageSelectionContinue')),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(continueFinder).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('languageOption-en')));
    await tester.pump();
    expect(tester.widget<FilledButton>(continueFinder).onPressed, isNotNull);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('languageOption-en')),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('languageSelectionContinue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(LanguageRepository.preferenceKey), 'en');
    expect(
      preferences.getBool(LanguageRepository.selectionCompletedKey),
      isTrue,
    );
    expect(preferences.getBool('hasCompletedOnboarding'), isNot(true));
    expect(find.byType(LanguageSelectionPanel), findsNothing);
    expect(find.byType(OnboardingCarouselScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(OnboardingCarouselScreen))),
      TextDirection.ltr,
    );
  });

  testWidgets('Arabic selection switches panel and onboarding to RTL', (
    tester,
  ) async {
    await tester.pumpWidget(_dietTimeApp());
    await _finishSplash(tester);

    await tester.tap(find.byKey(const ValueKey('languageOption-ar')));
    await tester.pump();
    expect(
      Directionality.of(
        tester.element(find.byKey(const ValueKey('languageSelectionPanel'))),
      ),
      TextDirection.rtl,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('languageOption-ar')),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('languageSelectionContinue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(LanguageRepository.preferenceKey), 'ar');
    expect(find.byType(OnboardingCarouselScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(OnboardingCarouselScreen))),
      TextDirection.rtl,
    );
  });
}

Future<void> _finishSplash(WidgetTester tester) async {
  // Installation setup completes asynchronously before the splash timer starts.
  for (var i = 0; i < 7; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _chooseLanguage(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('languageSelectionContinue')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _reachCarouselEnd(WidgetTester tester) async {
  for (var index = 0; index < 5; index++) {
    await tester.tap(
      find.byKey(ValueKey('onboardingTapArea-$index')).hitTestable(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey('onboardingContinue')).hitTestable(),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _fillRequiredProfile(WidgetTester tester) async {
  for (final key in const [
    'profileGender',
    'profileAge',
    'profileHeight',
    'profileWeight',
  ]) {
    await tester.tap(find.byKey(ValueKey(key)).hitTestable());
    await tester.pump();
    final saveButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Save'),
    );
    saveButton.onPressed!();
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Widget _localizedApp(
  Widget home, {
  Locale locale = const Locale('en'),
  ProfilePersistenceService? profileService,
}) {
  return ProviderScope(
    overrides: [
      authenticationServiceProvider.overrideWithValue(
        const _AuthenticatedService(),
      ),
      customerProfileServiceProvider.overrideWithValue(
        profileService ?? _FakeProfilePersistenceService(),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

Widget _dietTimeApp({
  AuthenticationService authenticationService = const _UnauthenticatedService(),
  ProfilePersistenceService? profileService,
}) {
  return ProviderScope(
    overrides: [
      authenticationServiceProvider.overrideWithValue(authenticationService),
      ordersRepositoryProvider.overrideWithValue(_NoOrders()),
      customerProfileServiceProvider.overrideWithValue(
        profileService ?? _FakeProfilePersistenceService(),
      ),
    ],
    child: const DietTimeApp(),
  );
}

class _FakeProfilePersistenceService implements ProfilePersistenceService {
  _FakeProfilePersistenceService({this.profile});

  CustomerProfile? profile;
  CustomerProfile? lastSubmitted;
  int saveProgressCalls = 0;
  int completeCalls = 0;
  bool failSave = false;

  @override
  Future<CustomerProfile?> load() async => profile;

  @override
  Future<CustomerProfile> saveProgress(CustomerProfile profile) async {
    saveProgressCalls++;
    lastSubmitted = profile;
    if (failSave) throw const CustomerProfileException(statusCode: 500);
    return _save(profile);
  }

  @override
  Future<CustomerProfile> complete(CustomerProfile profile) async {
    completeCalls++;
    lastSubmitted = profile;
    return _save(profile.copyWith(onboardingStatus: 'COMPLETED'));
  }

  CustomerProfile _save(CustomerProfile profile) {
    final nextStep = switch ((
      profile.genderCode,
      profile.goalCode,
      profile.dailyRoutineCode,
      profile.activityLevelCode,
      profile.allergensConfirmed,
      profile.preferencesConfirmed,
    )) {
      (_, null, _, _, _, _) => 'GOAL',
      (null, _, _, _, _, _) => 'BASIC_DETAILS',
      (_, _, null, _, _, _) => 'DAILY_ROUTINE',
      (_, _, _, null, _, _) => 'ACTIVITY_LEVEL',
      (_, _, _, _, _, false) => 'PREFERENCES',
      (_, _, _, _, false, _) => 'ALLERGENS',
      _ => 'PROFILE_COMPLETED',
    };
    final completed =
        nextStep == 'PROFILE_COMPLETED' &&
        profile.onboardingStatus == 'COMPLETED';
    this.profile = profile.copyWith(
      profileId: profile.profileId ?? 'profile-id',
      nutritionTargets: const NutritionTargets(
        calories: 2450,
        proteinGrams: 160,
      ),
      nextStepCode: nextStep == 'PROFILE_COMPLETED' && !completed
          ? 'ALLERGENS'
          : nextStep,
      completionPercentage: completed ? 100 : 50,
      shouldShowOnboarding: !completed,
    );
    return this.profile!;
  }
}

class _UnauthenticatedService implements AuthenticationService {
  const _UnauthenticatedService();

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<void> markAuthenticated() async {}

  @override
  Future<void> signIn({
    required String identity,
    required String password,
  }) async {}
}

class _AuthenticatedService implements AuthenticationService {
  const _AuthenticatedService();

  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<void> markAuthenticated() async {}

  @override
  Future<void> signIn({
    required String identity,
    required String password,
  }) async {}
}

class _NoOrders extends OrdersRepository {
  _NoOrders()
    : super(apiClient: ApiClient(), accessTokenProvider: () async => 'token');
  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
  }) async => [];
}

Widget _questionnaireCheckoutApp(
  ProfilePersistenceService service, {
  bool startPlan = false,
  bool accountSetup = false,
}) => ProviderScope(
  overrides: [
    authenticationServiceProvider.overrideWithValue(
      const _AuthenticatedService(),
    ),
    customerProfileServiceProvider.overrideWithValue(service),
    displayNameRepositoryProvider.overrideWithValue(
      _QuestionnaireNames(service as _FakeProfilePersistenceService),
    ),
  ],
  child: MaterialApp.router(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: GoRouter(
      initialLocation: accountSetup || startPlan
          ? '/authenticated-landing'
          : '/checkout-questionnaire',
      routes: [
        GoRoute(
          path: '/authenticated-landing',
          builder: (_, _) =>
              AuthenticatedLandingScreen(startNewPlan: startPlan),
        ),
        GoRoute(
          path: '/customer-setup',
          builder: (_, _) =>
              const PersonalizationScreen(accountSetupMode: true),
        ),
        GoRoute(
          path: '/checkout-questionnaire',
          builder: (_, _) => PersonalizationScreen(
            checkoutMode: true,
            startNewPlan: startPlan,
            accountSetupMode: accountSetup || startPlan,
          ),
        ),
        GoRoute(
          path: '/checkout-entry',
          builder: (_, _) => const Scaffold(body: Text('Checkout ready')),
        ),
        GoRoute(
          path: '/plans',
          builder: (_, _) => const Scaffold(body: Text('Plan selection ready')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Dashboard ready')),
        ),
      ],
    ),
  ),
);

class _QuestionnaireNames extends DisplayNameRepository {
  _QuestionnaireNames(this.service)
    : super(apiClient: ApiClient(), secureStorage: SecureStorageService());
  final _FakeProfilePersistenceService service;
  @override
  Future<CustomerProfile> saveAuthenticatedProfileName(String name) async {
    return service.profile =
        (service.profile ?? const CustomerProfile(profileId: 'profile-id'))
            .copyWith(preferredName: name);
  }
}
