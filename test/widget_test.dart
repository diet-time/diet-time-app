import 'package:diet_time/app/app.dart';
import 'package:diet_time/features/authentication/data/mock_authentication_service.dart';
import 'package:diet_time/features/authentication/presentation/phone_login_page.dart';
import 'package:diet_time/features/home/presentation/home_screen.dart';
import 'package:diet_time/features/language/presentation/language_selection_screen.dart';
import 'package:diet_time/features/menu/presentation/browse_menu_screen.dart';
import 'package:diet_time/features/onboarding/presentation/onboarding_screen.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/data/guest_recommendation_repository.dart';
import 'package:diet_time/features/personalization/data/guest_startup_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/domain/plan_recommendation.dart';
import 'package:diet_time/features/personalization/presentation/meal_plan_recommendation_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('first launch keeps the original onboarding carousel', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const OnboardingScreen()));

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

  testWidgets('final onboarding page shows menu and start plan actions', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const OnboardingScreen()));
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

  testWidgets('new guest starts profile onboarding without authentication', (
    tester,
  ) async {
    await tester.pumpWidget(_dietTimeApp());
    await _finishSplash(tester);
    await _chooseLanguage(tester, 'English');

    expect(find.byType(PersonalizationScreen), findsOneWidget);
    expect(find.text("Let's get to know you"), findsOneWidget);
    expect(find.byType(PhoneLoginPage), findsNothing);
  });

  testWidgets('goal selection is required and preserved when navigating back', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const PersonalizationScreen()));
    await _continue(tester);

    expect(find.text('What would you like to achieve?'), findsOneWidget);
    await _continue(tester);
    expect(find.text('Choose an option to continue.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('goal-lose')).hitTestable());
    await tester.pump(const Duration(milliseconds: 250));
    await _continue(tester);
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

  testWidgets('server completion routes directly to guest recommendations', (
    tester,
  ) async {
    await tester.pumpWidget(_dietTimeApp());
    await _finishSplash(tester);
    await _chooseLanguage(tester, 'English');

    // BASIC_DETAILS and BODY_MEASUREMENTS share the existing profile card.
    await _continue(tester);
    await tester.tap(find.byKey(const ValueKey('goal-lose')).hitTestable());
    await _continue(tester);
    await tester.tap(
      find.byKey(const ValueKey('lifestyle-office')).hitTestable(),
    );
    await _continue(tester);
    await tester.tap(
      find.byKey(const ValueKey('activity-sitting')).hitTestable(),
    );
    await _continue(tester);
    await tester.tap(find.byKey(const ValueKey('choice-none')));
    await _continue(tester);
    await tester.tap(find.byKey(const ValueKey('choice-HIGH_PROTEIN')));
    await _continue(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MealPlanRecommendationScreen), findsOneWidget);
    expect(find.byType(PhoneLoginPage), findsNothing);
  });

  testWidgets('returning incomplete guest resumes the server-provided step', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'preferredLanguage': 'en',
      'languageSelectionCompletedV2': true,
      'hasCompletedOnboarding': true,
    });
    await tester.pumpWidget(_dietTimeApp());
    await _finishSplash(tester);

    expect(find.byType(PersonalizationScreen), findsOneWidget);
    expect(find.text("Let's get to know you"), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(BrowseMenuScreen), findsNothing);
  });

  testWidgets('completed guest skips onboarding and clears its route stack', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'preferredLanguage': 'en',
      'languageSelectionCompletedV2': true,
    });
    await tester.pumpWidget(
      _dietTimeApp(
        guestStartupProfile: const CustomerProfile(
          nextStepCode: 'PROFILE_COMPLETED',
          completionPercentage: 100,
          shouldShowOnboarding: false,
        ),
      ),
    );
    await _finishSplash(tester);

    expect(find.byType(MealPlanRecommendationScreen), findsOneWidget);
    expect(find.byType(PersonalizationScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('authenticated user with an incomplete profile resumes setup', (
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

    expect(find.byType(PersonalizationScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(PhoneLoginPage), findsNothing);
  });

  testWidgets('stored profile completion does not skip the demo setup', (
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
      _dietTimeApp(authenticationService: const _AuthenticatedService()),
    );
    await _finishSplash(tester);

    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(PersonalizationScreen), findsOneWidget);
  });

  testWidgets('Arabic carousel and personalization remain RTL', (tester) async {
    await tester.pumpWidget(
      _localizedApp(const OnboardingScreen(), locale: const Locale('ar')),
    );
    expect(
      Directionality.of(tester.element(find.byType(OnboardingScreen))),
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

  testWidgets('language selection still precedes first onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(_dietTimeApp());
    await _finishSplash(tester);
    expect(find.byType(LanguageSelectionScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
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

Future<void> _reachCarouselEnd(WidgetTester tester) async {
  for (var index = 0; index < 4; index++) {
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

Widget _localizedApp(Widget home, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      customerProfileServiceProvider.overrideWithValue(
        _FakeProfilePersistenceService(),
      ),
      guestStartupServiceProvider.overrideWithValue(
        const _FakeGuestStartupService(),
      ),
      guestPlanRecommendationsProvider.overrideWith(
        (ref, language) async => _fakeRecommendations,
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
  CustomerProfile? guestStartupProfile,
}) {
  return ProviderScope(
    overrides: [
      authenticationServiceProvider.overrideWithValue(authenticationService),
      customerProfileServiceProvider.overrideWithValue(
        _FakeProfilePersistenceService(),
      ),
      guestStartupServiceProvider.overrideWithValue(
        _FakeGuestStartupService(profile: guestStartupProfile),
      ),
      guestPlanRecommendationsProvider.overrideWith(
        (ref, language) async => _fakeRecommendations,
      ),
    ],
    child: const DietTimeApp(),
  );
}

class _FakeProfilePersistenceService implements ProfilePersistenceService {
  CustomerProfile? profile;

  @override
  Future<CustomerProfile?> load({required bool authenticated}) async => profile;

  @override
  Future<CustomerProfile> saveProgress(
    CustomerProfile profile, {
    required bool authenticated,
  }) async {
    return _save(profile);
  }

  @override
  Future<CustomerProfile> complete(
    CustomerProfile profile, {
    required bool authenticated,
  }) async {
    return _save(
      profile.copyWith(
        onboardingStatus: authenticated ? 'COMPLETED' : 'PROFILE_COMPLETED',
      ),
    );
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
      (null, _, _, _, _, _) => 'BASIC_DETAILS',
      (_, null, _, _, _, _) => 'GOAL',
      (_, _, null, _, _, _) => 'DAILY_ROUTINE',
      (_, _, _, null, _, _) => 'ACTIVITY_LEVEL',
      (_, _, _, _, false, _) => 'ALLERGENS',
      (_, _, _, _, true, false) => 'PREFERENCES',
      _ => 'PROFILE_COMPLETED',
    };
    final completed = nextStep == 'PROFILE_COMPLETED';
    this.profile = profile.copyWith(
      bmi: 24.2,
      nutritionTargets: const NutritionTargets(
        calories: 2450,
        proteinGrams: 160,
      ),
      nextStepCode: nextStep,
      completionPercentage: completed ? 100 : 50,
      shouldShowOnboarding: !completed,
    );
    return this.profile!;
  }
}

class _FakeGuestStartupService implements GuestStartupService {
  const _FakeGuestStartupService({this.profile});

  final CustomerProfile? profile;

  @override
  Future<void> ensureSession() async {}

  @override
  Future<CustomerProfile?> getProfile() async => profile;
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

const _fakeRecommendations = [
  PlanRecommendation(
    id: 'balanced-id',
    code: 'BALANCED',
    name: 'Balanced Living',
    description: 'Balanced meals selected for your profile.',
    mealCount: 20,
    durationDays: 7,
    isRecommended: true,
    isAllergenCompatible: true,
  ),
];
