import 'dart:async';

import 'package:diet_time/app/theme/app_theme.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/authentication/data/authentication_repository.dart';
import 'package:diet_time/features/authentication/data/mock_authentication_service.dart';
import 'package:diet_time/features/authentication/data/otp_service_provider.dart';
import 'package:diet_time/features/authentication/domain/auth_models.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/authentication/presentation/otp_verification_page.dart';
import 'package:diet_time/features/authentication/presentation/phone_login_page.dart';
import 'package:diet_time/features/personalization/presentation/post_login_landing_screen.dart';
import 'package:diet_time/features/plans/data/meal_plan_repository.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_details_screen.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _testOtp = List.generate(6, (index) => (index + 1).toString()).join();
final _invalidOtp = List.filled(6, '9').join();

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('secure session restores while the access token is valid', () async {
    final storage = SecureStorageService(storage: const FlutterSecureStorage());
    await storage.write(SecureStorageService.accessTokenKey, 'access-token');
    await storage.write(
      SecureStorageService.accessTokenExpiresAtKey,
      DateTime.now().toUtc().add(const Duration(hours: 1)).toIso8601String(),
    );

    final service = SecureStorageAuthenticationService(storage);

    expect(await service.isLoggedIn(), isTrue);
  });

  test('expired secure access token does not restore a session', () async {
    final storage = SecureStorageService(storage: const FlutterSecureStorage());
    await storage.write(SecureStorageService.accessTokenKey, 'access-token');
    await storage.write(
      SecureStorageService.accessTokenExpiresAtKey,
      DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 1))
          .toIso8601String(),
    );

    final service = SecureStorageAuthenticationService(storage);

    expect(await service.isLoggedIn(), isFalse);
  });

  testWidgets('valid Qatar phone is normalized and requests OTP once', (
    tester,
  ) async {
    final otp = _FakeOtpService();
    await tester.pumpWidget(_app(otp: otp));
    await tester.pump();

    final button = find.byKey(const ValueKey('phoneContinueButton'));
    expect(_isButtonEnabled(tester, button), isFalse);

    await tester.enterText(
      find.byKey(const ValueKey('phoneNumberInput')),
      '74452435',
    );
    await tester.pump();
    expect(_isButtonEnabled(tester, button), isTrue);

    await tester.tap(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(otp.requestCount, 0);
    expect(find.byType(OtpVerificationPage), findsOneWidget);
    expect(find.text('+974 7445 2435'), findsOneWidget);
  });

  testWidgets('invalid Qatar phone cannot continue', (tester) async {
    final otp = _FakeOtpService();
    await tester.pumpWidget(_app(otp: otp));
    await tester.enterText(
      find.byKey(const ValueKey('phoneNumberInput')),
      '24452435',
    );
    await tester.pump();

    expect(find.text('Enter a valid mobile number.'), findsOneWidget);
    expect(
      _isButtonEnabled(
        tester,
        find.byKey(const ValueKey('phoneContinueButton')),
      ),
      isFalse,
    );
    expect(otp.requestCount, 0);
  });

  testWidgets('pasted E.164 Qatar number does not duplicate the prefix', (
    tester,
  ) async {
    final otp = _FakeOtpService();
    await tester.pumpWidget(_app(otp: otp));
    final input = find.byKey(const ValueKey('phoneNumberInput'));

    await tester.enterText(input, '+974 7445 2435');
    await tester.pump();

    expect(tester.widget<TextField>(input).controller?.text, '74452435');
    expect(
      _isButtonEnabled(
        tester,
        find.byKey(const ValueKey('phoneContinueButton')),
      ),
      isTrue,
    );
  });

  testWidgets('returning from OTP keeps phone and re-enables Continue', (
    tester,
  ) async {
    final otp = _FakeOtpService();
    await tester.pumpWidget(_app(otp: otp));
    await _openOtp(tester);

    await tester.tap(find.byKey(const ValueKey('otpFlowBack')));
    await tester.pumpAndSettle();

    final input = find.byKey(const ValueKey('phoneNumberInput'));
    final button = find.byKey(const ValueKey('phoneContinueButton'));
    expect(find.byType(PhoneLoginPage), findsOneWidget);
    expect(tester.widget<TextField>(input).controller?.text, '74452435');
    expect(_isButtonEnabled(tester, button), isTrue);
    expect(otp.requestCount, 0);
  });

  testWidgets('six digit code verifies and keeps pending destination', (
    tester,
  ) async {
    final otp = _FakeOtpService();
    final auth = _FakeAuthenticationService();
    await tester.pumpWidget(_app(otp: otp, authentication: auth));
    await _openOtp(tester);

    final verify = find.byKey(const ValueKey('verifyOtpButton'));
    expect(_isButtonEnabled(tester, verify), isFalse);

    await tester.enterText(find.byKey(const ValueKey('otpCell0')), _testOtp);
    await tester.pump();
    expect(_isButtonEnabled(tester, verify), isTrue);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(OtpVerificationPage)),
    );
    final pending = container
        .read(otpAuthControllerProvider)
        .pendingDestination;
    expect(pending?.planCode, 'KETO');
    expect(pending?.planName, 'Keto');

    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(auth.markAuthenticatedCount, 1);
    expect(
      await const FlutterSecureStorage().read(
        key: SecureStorageService.accessTokenKey,
      ),
      'access-token',
    );
    expect(find.byKey(const ValueKey('otpDestination')), findsOneWidget);
    expect(container.read(otpAuthControllerProvider).otpCode, isEmpty);
  });

  testWidgets('incorrect code shows an inline error and clears digits', (
    tester,
  ) async {
    final otp = _FakeOtpService();
    await tester.pumpWidget(_app(otp: otp));
    await _openOtp(tester);

    await tester.enterText(find.byKey(const ValueKey('otpCell0')), _invalidOtp);
    await tester.pump();
    final verify = find.byKey(const ValueKey('verifyOtpButton'));
    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.pumpAndSettle();

    expect(find.text('Invalid OTP. Please try again.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('otpCell0')))
          .controller
          ?.text,
      '',
    );
  });

  testWidgets('OTP submission shows loading and prevents duplicate requests', (
    tester,
  ) async {
    final repository = _ControlledAuthenticationRepository();
    await tester.pumpWidget(
      _app(otp: _FakeOtpService(), repository: repository),
    );
    await _openOtp(tester);
    await tester.enterText(find.byKey(const ValueKey('otpCell0')), _testOtp);
    await tester.pump();

    final verify = find.byKey(const ValueKey('verifyOtpButton'));
    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.tap(verify);
    await tester.pump();

    expect(repository.callCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_isButtonEnabled(tester, verify), isFalse);

    repository.succeed();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('otpDestination')), findsOneWidget);
  });

  testWidgets('connection error keeps OTP so verification can be retried', (
    tester,
  ) async {
    final repository = _ControlledAuthenticationRepository();
    await tester.pumpWidget(
      _app(otp: _FakeOtpService(), repository: repository),
    );
    await _openOtp(tester);
    await tester.enterText(find.byKey(const ValueKey('otpCell0')), _testOtp);
    await tester.pump();

    final verify = find.byKey(const ValueKey('verifyOtpButton'));
    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.pump();
    repository.fail(PhoneOtpFailure.connection);
    await tester.pumpAndSettle();

    expect(
      find.text('Could not connect. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('otpCell0')))
          .controller
          ?.text,
      '1',
    );
    expect(_isButtonEnabled(tester, verify), isTrue);
  });

  testWidgets('resend is unavailable while there is no request endpoint', (
    tester,
  ) async {
    final otp = _FakeOtpService();
    await tester.pumpWidget(_app(otp: otp));
    await _openOtp(tester);

    final resend = find.byKey(const ValueKey('resendOtpButton'));
    expect(_isTextButtonEnabled(tester, resend), isFalse);
    expect(find.text('Resend unavailable in test mode'), findsOneWidget);
    expect(otp.requestCount, 0);
  });

  testWidgets('Arabic flow uses RTL while phone and OTP remain LTR', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(otp: _FakeOtpService(), locale: const Locale('ar')),
    );
    await tester.pump();

    expect(
      Directionality.of(tester.element(find.byType(PhoneLoginPage))),
      TextDirection.rtl,
    );
    expect(
      Directionality.of(
        tester.element(find.byKey(const ValueKey('phoneNumberInput'))),
      ),
      TextDirection.ltr,
    );
  });

  testWidgets('phone and OTP screens avoid overflow on a small device', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(otp: _FakeOtpService()));
    await tester.pump();

    expect(find.byKey(const ValueKey('otpLanguageSelector')), findsNothing);
    expect(find.byKey(const ValueKey('googleSignInButton')), findsNothing);
    expect(find.byKey(const ValueKey('appleSignInButton')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey('phoneNumberInput')),
      '74452435',
    );
    await tester.pump();
    final continueButton = find.byKey(const ValueKey('phoneContinueButton'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(OtpVerificationPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OTP layout remains scrollable with keyboard inset', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(otp: _FakeOtpService()));
    await _openOtp(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('otpCell0')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('verifyOtpButton')));

    expect(find.byType(OtpVerificationPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authenticated user skips phone login from plan continuation', (
    tester,
  ) async {
    final authentication = _FakeAuthenticationService(loggedIn: true);
    await tester.pumpWidget(_planApp(authentication));
    await tester.pump();
    await tester.pump();

    final continueButton = find.text('Continue');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(MealPlanDetailsScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('detailsContinue')));
    await tester.pumpAndSettle();

    expect(find.byType(PhoneLoginPage), findsNothing);
    expect(
      find.byKey(const ValueKey('authenticatedDestination')),
      findsOneWidget,
    );
  });
}

Future<void> _openOtp(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('phoneNumberInput')),
    '74452435',
  );
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('phoneContinueButton')));
  await tester.pumpAndSettle();
}

bool _isButtonEnabled(WidgetTester tester, Finder finder) {
  final button = tester.widget<FilledButton>(
    find.descendant(of: finder, matching: find.byType(FilledButton)),
  );
  return button.onPressed != null;
}

bool _isTextButtonEnabled(WidgetTester tester, Finder finder) =>
    tester.widget<TextButton>(finder).onPressed != null;

Widget _app({
  required OtpService otp,
  AuthenticationService? authentication,
  AuthenticationRepository? repository,
  Locale locale = const Locale('en'),
}) {
  final router = GoRouter(
    initialLocation: '/phone',
    routes: [
      GoRoute(
        path: '/phone',
        builder: (context, state) => const PhoneLoginPage(
          pendingDestination: PendingAuthDestination(
            route: '/destination',
            planCode: 'KETO',
            planName: 'Keto',
          ),
        ),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpVerificationPage(),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) => const OtpVerificationPage(),
      ),
      GoRoute(
        path: '/post-login',
        builder: (context, state) {
          final nextRoute = state.extra! as String;
          return PostLoginLandingScreen(
            onContinue: () => context.go(nextRoute),
          );
        },
      ),
      GoRoute(
        path: '/destination',
        builder: (context, state) =>
            const SizedBox(key: ValueKey('otpDestination')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      otpServiceProvider.overrideWithValue(otp),
      authenticationRepositoryProvider.overrideWithValue(
        repository ?? _OtpAuthenticationRepository(otp),
      ),
      authenticationServiceProvider.overrideWithValue(
        authentication ?? _FakeAuthenticationService(),
      ),
    ],
    child: MaterialApp.router(
      locale: locale,
      theme: AppTheme.light(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

Widget _planApp(AuthenticationService authentication) {
  final router = GoRouter(
    initialLocation: '/plans',
    routes: [
      GoRoute(
        path: '/plans',
        builder: (context, state) => const MealPlanScreen(),
      ),
      GoRoute(
        path: '/plan-details',
        builder: (context, state) =>
            MealPlanDetailsScreen(plan: state.extra! as MealPlanOption),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) =>
            const SizedBox(key: ValueKey('authenticatedDestination')),
      ),
      GoRoute(
        path: '/phone-login',
        builder: (context, state) => PhoneLoginPage(
          pendingDestination: state.extra! as PendingAuthDestination,
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authenticationServiceProvider.overrideWithValue(authentication),
      mealPlansProvider.overrideWith(
        (ref, language) async => const [
          MealPlanOption(
            id: 'classic-id',
            code: 'CLASSIC',
            name: 'Classic',
            description: 'Everyday balanced meals.',
            dailyCaloriesKcal: 1840,
            startingPrice: 349,
            currencyCode: 'QAR',
            priceDurationDays: 7,
            mealConfigurations: [
              MealPlanConfiguration(
                id: 'three-meals',
                name: '3 Meals',
                packages: [
                  MealPlanPackage(
                    mealPlanPriceId: 'classic-week',
                    name: '1 Week',
                    serviceDays: 6,
                    totalPrice: 600,
                    dailyPrice: 100,
                    currencyCode: 'QAR',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(const Locale('en')),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

class _FakeOtpService implements OtpService {
  int requestCount = 0;
  String? requestedPhone;

  @override
  Future<OtpRequestResult> requestOtp({
    required String phoneNumber,
    required OtpChannel channel,
  }) async {
    requestCount++;
    requestedPhone = phoneNumber;
    return OtpRequestResult(success: true, requestId: 'request-$requestCount');
  }

  @override
  Future<OtpVerificationResult> verifyOtp({
    required String phoneNumber,
    required String code,
  }) async {
    return OtpVerificationResult(success: code == _testOtp);
  }
}

class _OtpAuthenticationRepository implements AuthenticationRepository {
  const _OtpAuthenticationRepository(this.otpService);

  final OtpService otpService;

  @override
  Future<AuthSession> verifyPhoneOtp(PhoneOtpLoginRequest request) async {
    final result = await otpService.verifyOtp(
      phoneNumber: request.phoneNumber,
      code: request.otp,
    );
    if (!result.success) {
      throw const PhoneOtpException(PhoneOtpFailure.invalidOtp);
    }
    return AuthSession(
      accessToken: 'access-token',
      accessTokenExpiresAt: DateTime.utc(2026, 8, 6, 20),
      refreshToken: 'refresh-token',
      refreshTokenExpiresAt: DateTime.utc(2026, 9, 6, 20),
      user: AuthUser(
        id: 'user-1',
        email: '',
        name: '',
        roles: const [],
        phoneNumber: request.phoneNumber,
      ),
    );
  }
}

class _ControlledAuthenticationRepository implements AuthenticationRepository {
  final _completer = Completer<AuthSession>();
  int callCount = 0;
  PhoneOtpLoginRequest? request;

  @override
  Future<AuthSession> verifyPhoneOtp(PhoneOtpLoginRequest request) {
    callCount++;
    this.request = request;
    return _completer.future;
  }

  void succeed() => _completer.complete(_session(request!.phoneNumber));

  void fail(PhoneOtpFailure failure) {
    _completer.completeError(PhoneOtpException(failure));
  }
}

AuthSession _session(String phoneNumber) => AuthSession(
  accessToken: 'access-token',
  accessTokenExpiresAt: DateTime.utc(2026, 8, 6, 20),
  refreshToken: 'refresh-token',
  refreshTokenExpiresAt: DateTime.utc(2026, 9, 6, 20),
  user: AuthUser(
    id: 'user-1',
    email: '',
    name: '',
    roles: const [],
    phoneNumber: phoneNumber,
  ),
);

class _FakeAuthenticationService implements AuthenticationService {
  _FakeAuthenticationService({this.loggedIn = false});

  final bool loggedIn;
  int markAuthenticatedCount = 0;

  @override
  Future<bool> isLoggedIn() async => loggedIn;

  @override
  Future<void> markAuthenticated() async {
    markAuthenticatedCount++;
  }

  @override
  Future<void> signIn({
    required String identity,
    required String password,
  }) async {}
}
