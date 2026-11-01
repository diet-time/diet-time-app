import 'dart:async';
import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/authentication/data/authentication_repository.dart';
import 'package:diet_time/features/authentication/data/mock_authentication_service.dart';
import 'package:diet_time/features/authentication/domain/auth_models.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/authentication/presentation/phone_login_page.dart';
import 'package:diet_time/features/authentication/presentation/otp_verification_page.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/data/display_name_repository.dart';
import 'package:diet_time/features/personalization/domain/customer_onboarding.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/authenticated_landing_screen.dart';
import 'package:diet_time/features/personalization/presentation/customer_onboarding_coordinator.dart';
import 'package:diet_time/features/personalization/presentation/display_name_panel.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _completed = CustomerProfile(
  profileId: 'profile',
  userId: 'a',
  genderCode: 'FEMALE',
  dateOfBirth: '1995-03-17',
  heightCm: 165,
  weightKg: 70,
  goalCode: 'LOSE_WEIGHT',
  dailyRoutineCode: 'OFFICE_WORK',
  activityLevelCode: 'MOSTLY_SITTING',
  preferencesConfirmed: true,
  allergensConfirmed: true,
  onboardingStatus: 'COMPLETED',
  nextStepCode: 'PROFILE_COMPLETED',
  shouldShowOnboarding: false,
  allergens: {'milk-id'},
  preferences: {'HIGH_PROTEIN'},
);

void main() {
  for (final startPlan in [false, true]) {
    testWidgets('valid restored customer skips login: plan=$startPlan', (
      tester,
    ) async {
      final storage = _SessionStorage();
      storage.values[SecureStorageService.accessTokenKey] = 'token';
      storage.values[SecureStorageService.accessTokenExpiresAtKey] =
          DateTime.utc(2099).toIso8601String();
      final api = _NameApi()
        ..profile = _completed.copyWith(preferredName: 'Noor');
      final container = ProviderContainer(
        overrides: [
          secureStorageServiceProvider.overrideWithValue(storage),
          authenticationServiceProvider.overrideWithValue(
            SecureStorageAuthenticationService(storage),
          ),
          customerProfileServiceProvider.overrideWithValue(_Profiles(api)),
        ],
      );
      addTearDown(container.dispose);
      final router = _router(startPlan);
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(container, router, 'en'));
      await tester.pumpAndSettle();
      expect(find.byType(PhoneLoginPage), findsNothing);
      expect(find.byType(DisplayNamePanel), findsNothing);
      expect(
        find.text(startPlan ? 'Plan selection' : 'Dashboard'),
        findsOneWidget,
      );
    });

    for (final initial in ['guest', 'stale flag', 'expired token']) {
      testWidgets('login and OTP precede name: $initial plan=$startPlan', (
        tester,
      ) async {
        final api = _NameApi();
        final profiles = _Profiles(api);
        final storage = _SessionStorage();
        if (initial == 'expired token') {
          storage.values[SecureStorageService.accessTokenKey] = 'old-token';
          storage.values[SecureStorageService.accessTokenExpiresAtKey] =
              DateTime.utc(2000).toIso8601String();
        }
        final container = ProviderContainer(
          overrides: [
            if (initial != 'guest')
              otpAuthControllerProvider.overrideWith(_StaleAuth.new),
            secureStorageServiceProvider.overrideWithValue(storage),
            authenticationServiceProvider.overrideWithValue(
              SecureStorageAuthenticationService(storage),
            ),
            authenticationRepositoryProvider.overrideWithValue(
              _OtpRepository(),
            ),
            customerProfileServiceProvider.overrideWithValue(profiles),
            apiClientProvider.overrideWithValue(api),
          ],
        );
        addTearDown(container.dispose);
        final router = _router(startPlan);
        addTearDown(router.dispose);
        await tester.pumpWidget(_app(container, router, 'en'));
        await tester.pumpAndSettle();
        expect(find.byType(PhoneLoginPage), findsOneWidget);
        expect(find.byType(DisplayNamePanel), findsNothing);
        expect(profiles.loads, 0);

        await tester.enterText(
          find.byKey(const ValueKey('phoneNumberInput')),
          '74452435',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('phoneContinueButton')));
        await tester.pumpAndSettle();
        expect(find.byType(OtpVerificationPage), findsOneWidget);
        expect(find.byType(DisplayNamePanel), findsNothing);
        expect(profiles.loads, 0);
        await tester.enterText(
          find.byKey(const ValueKey('otpCell0')),
          '123456',
        );
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(const ValueKey('verifyOtpButton')),
        );
        await tester.tap(find.byKey(const ValueKey('verifyOtpButton')));
        await tester.pumpAndSettle();
        expect(find.byType(DisplayNamePanel), findsOneWidget);
        expect(find.byType(PhoneLoginPage), findsNothing);
        expect(find.byType(OtpVerificationPage), findsNothing);
        expect(profiles.loads, 1);
        expect(
          container.read(customerOnboardingCoordinatorProvider).intent,
          startPlan
              ? CustomerJourneyIntent.startNewPlan
              : CustomerJourneyIntent.normalLogin,
        );
      });
    }
  }
  for (final startPlan in [false, true]) {
    for (final language in ['en', 'ar']) {
      testWidgets(
        'new customer collects name before questions: plan=$startPlan language=$language',
        (tester) async {
          final api = _NameApi();
          final container = _container(api);
          addTearDown(container.dispose);
          final router = _router(startPlan);
          addTearDown(router.dispose);
          await tester.pumpWidget(_app(container, router, language));
          await tester.pumpAndSettle();
          expect(find.byType(DisplayNamePanel), findsOneWidget);
          expect(find.text('Questionnaire'), findsNothing);
          expect(api.profile, isNull);
          expect(
            Directionality.of(tester.element(find.byType(DisplayNamePanel))),
            language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          await tester.enterText(
            find.byKey(const ValueKey('displayNameInput')),
            language == 'ar' ? 'نور' : '  Noor  ',
          );
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('displayNameContinue')));
          await tester.pumpAndSettle();
          expect(find.text('Questionnaire'), findsOneWidget);
          expect(find.byType(DisplayNamePanel), findsNothing);
          expect(api.patchCalls, 1);
          expect(api.lastBody, {
            'preferredName': language == 'ar' ? 'نور' : 'Noor',
          });
          final state = container.read(customerOnboardingCoordinatorProvider);
          expect(state.questionnairePage, 1);
          expect(
            state.intent,
            startPlan
                ? CustomerJourneyIntent.startNewPlan
                : CustomerJourneyIntent.normalLogin,
          );
          expect(
            container
                .read(profilePersistenceControllerProvider)
                .persistedProfile!
                .preferredName,
            api.profile!.preferredName,
          );
          expect(router.canPop(), isFalse);
        },
      );
    }
  }

  for (final startPlan in [false, true]) {
    testWidgets(
      'completed customer missing name saves it and skips questionnaire: $startPlan',
      (tester) async {
        final api = _NameApi()..profile = _completed;
        final container = _container(api);
        addTearDown(container.dispose);
        final router = _router(startPlan);
        addTearDown(router.dispose);
        await tester.pumpWidget(_app(container, router, 'en'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('displayNameInput')),
          'Noor',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('displayNameContinue')));
        await tester.pumpAndSettle();
        expect(
          find.text(startPlan ? 'Plan selection' : 'Dashboard'),
          findsOneWidget,
        );
        expect(find.text('Questionnaire'), findsNothing);
        expect(api.profile!.allergens, _completed.allergens);
        expect(api.profile!.preferences, _completed.preferences);
        expect(api.profile!.isCompleted, isTrue);
        expect(
          container.read(customerOnboardingCoordinatorProvider).intent,
          CustomerJourneyIntent.normalLogin,
        );
        expect(api.patchCalls, 1);
      },
    );
  }

  testWidgets(
    'failed name save retains input; retry and repeated taps save once',
    (tester) async {
      final api = _NameApi()..fail = true;
      final container = _container(api);
      addTearDown(container.dispose);
      final router = _router(false);
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(container, router, 'en'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('displayNameInput')),
        'Noor',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('displayNameContinue')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('displayNameSaveError')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('displayNameInput')))
            .controller!
            .text,
        'Noor',
      );
      expect(api.profile, isNull);
      api.fail = false;
      api.pending = Completer<void>();
      await tester.tap(find.byKey(const ValueKey('displayNameContinue')));
      await tester.tap(find.byKey(const ValueKey('displayNameContinue')));
      await tester.pump();
      expect(api.patchCalls, 2);
      expect(find.text('Questionnaire'), findsNothing);
      api.pending!.complete();
      await tester.pumpAndSettle();
      expect(api.patchCalls, 2);
      expect(find.text('Questionnaire'), findsOneWidget);
    },
  );

  testWidgets(
    'whitespace and phone numbers are not names; previous account cache is ignored',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        DisplayNameRepository.displayNameKey: 'Another customer',
        DisplayNameRepository.capturedKey: true,
      });
      final api = _NameApi();
      final container = _container(api);
      addTearDown(container.dispose);
      final router = _router(false);
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(container, router, 'en'));
      await tester.pumpAndSettle();
      for (final name in [' ', '+974 7445 2435', 'x']) {
        await tester.enterText(
          find.byKey(const ValueKey('displayNameInput')),
          name,
        );
        await tester.pump();
        expect(
          tester
              .widget<FilledButton>(
                find.descendant(
                  of: find.byKey(const ValueKey('displayNameContinue')),
                  matching: find.byType(FilledButton),
                ),
              )
              .onPressed,
          isNull,
        );
      }
      expect(api.patchCalls, 0);
      expect(find.byType(DisplayNamePanel), findsOneWidget);
    },
  );
}

ProviderContainer _container(_NameApi api) => ProviderContainer(
  overrides: [
    otpAuthControllerProvider.overrideWith(_Auth.new),
    customerProfileServiceProvider.overrideWithValue(_Profiles(api)),
    apiClientProvider.overrideWithValue(api),
    secureStorageServiceProvider.overrideWithValue(_Storage()),
  ],
);
GoRouter _router(bool startPlan) => GoRouter(
  initialLocation: '/entry',
  routes: [
    GoRoute(
      path: AppRoutes.phoneLogin,
      builder: (_, state) => PhoneLoginPage(
        pendingDestination: state.extra! as PendingAuthDestination,
      ),
    ),
    GoRoute(
      path: AppRoutes.otp,
      builder: (_, _) => const OtpVerificationPage(),
    ),
    GoRoute(
      path: AppRoutes.authenticatedLanding,
      builder: (_, _) => const AuthenticatedLandingScreen(),
    ),
    GoRoute(
      path: AppRoutes.startPlan,
      builder: (_, _) => const AuthenticatedLandingScreen(startNewPlan: true),
    ),
    GoRoute(
      path: '/entry',
      builder: (_, _) => AuthenticatedLandingScreen(startNewPlan: startPlan),
    ),
    GoRoute(
      path: AppRoutes.customerSetup,
      builder: (_, _) => const Text('Questionnaire'),
    ),
    GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('Dashboard')),
    GoRoute(
      path: AppRoutes.plans,
      builder: (_, _) => const Text('Plan selection'),
    ),
  ],
);
Widget _app(ProviderContainer container, GoRouter router, String language) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

class _Auth extends OtpAuthController {
  @override
  Future<bool> ensureCurrentSession() async => state.isAuthenticated;

  @override
  OtpAuthState build() => const OtpAuthState(isAuthenticated: true);
}

class _Storage extends SecureStorageService {
  @override
  Future<String?> read(String key) async =>
      key == SecureStorageService.accessTokenKey ? 'token' : null;
}

class _Profiles implements ProfilePersistenceService {
  _Profiles(this.api);
  final _NameApi api;
  int loads = 0;
  @override
  Future<CustomerProfile?> load() async {
    loads++;
    return api.profile;
  }

  @override
  Future<CustomerProfile> saveProgress(CustomerProfile profile) async =>
      throw StateError('name gate must not save questions');
  @override
  Future<CustomerProfile> complete(CustomerProfile profile) =>
      saveProgress(profile);
}

// Deliberately inherits the real validation methods: a cached flag is not proof
// of a valid session and must never open the profile-name dialog.
class _StaleAuth extends OtpAuthController {
  @override
  OtpAuthState build() => const OtpAuthState(isAuthenticated: true);
}

class _SessionStorage extends SecureStorageService {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

class _OtpRepository implements AuthenticationRepository {
  @override
  Future<AuthSession> verifyPhoneOtp(PhoneOtpLoginRequest request) async =>
      AuthSession(
        accessToken: 'token',
        refreshToken: 'refresh',
        accessTokenExpiresAt: DateTime.utc(2099),
        refreshTokenExpiresAt: DateTime.utc(2099),
        user: const AuthUser(
          id: 'a',
          email: '',
          name: '',
          roles: ['Customer'],
          phoneNumber: '+97474452435',
        ),
      );
}

class _NameApi extends ApiClient {
  CustomerProfile? profile;
  int patchCalls = 0;
  bool fail = false;
  Completer<void>? pending;
  Map<String, dynamic>? lastBody;
  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    expect(method, 'PATCH');
    expect(path, '/api/v1/customer/profile/preferred-name');
    expect(headers['Authorization'], 'Bearer token');
    patchCalls++;
    lastBody = body;
    if (pending != null) await pending!.future;
    if (fail) return const ApiResponse(statusCode: 500, body: {});
    profile =
        (profile ?? const CustomerProfile(profileId: 'profile', userId: 'a'))
            .copyWith(preferredName: body!['preferredName'] as String);
    return ApiResponse(
      statusCode: 200,
      body: {
        'data': {
          ...profile!.toJson(),
          'id': profile!.profileId,
          'userId': 'a',
          'preferredName': profile!.preferredName,
          'nextStepCode': profile!.nextStepCode,
          'shouldShowOnboarding': profile!.shouldShowOnboarding,
        },
      },
    );
  }
}
