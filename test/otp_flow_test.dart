import 'package:diet_time/app/theme/app_theme.dart';
import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/features/authentication/data/mock_authentication_service.dart';
import 'package:diet_time/features/authentication/data/mock_otp_service.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/authentication/presentation/otp_verification_page.dart';
import 'package:diet_time/features/authentication/presentation/phone_login_page.dart';
import 'package:diet_time/features/plans/presentation/meal_plan_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('mock service accepts only the development code', () async {
    const service = MockOtpService(
      requestDelay: Duration.zero,
      verificationDelay: Duration.zero,
    );

    expect(
      (await service.verifyOtp(
        phoneNumber: '+97474452435',
        code: '123456',
      )).success,
      isTrue,
    );
    expect(
      (await service.verifyOtp(
        phoneNumber: '+97474452435',
        code: '654321',
      )).success,
      isFalse,
    );
  });

  test('service factory selects mock and API implementations', () {
    expect(createOtpService(useMockOtp: true), isA<MockOtpService>());
    expect(createOtpService(useMockOtp: false), isA<ApiOtpService>());
  });

  test('service factory follows the compiled USE_MOCK_OTP flag', () {
    final service = createOtpService();
    if (AppEnvironment.useMockOtp) {
      expect(service, isA<MockOtpService>());
    } else {
      expect(service, isA<ApiOtpService>());
    }
  });

  test('mock OTP is the default while the backend is unavailable', () {
    expect(AppEnvironment.useMockOtp, isTrue);
    expect(createOtpService(), isA<MockOtpService>());
  });

  test('mock OTP request succeeds without a network dependency', () async {
    const service = MockOtpService(
      requestDelay: Duration.zero,
      verificationDelay: Duration.zero,
    );

    final result = await service.requestOtp(
      phoneNumber: '+97474452435',
      channel: OtpChannel.sms,
    );

    expect(result.success, isTrue);
    expect(result.expiresInSeconds, 120);
    expect(result.requestId, startsWith('mock-'));
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

    expect(otp.requestCount, 1);
    expect(otp.requestedPhone, '+97474452435');
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

  testWidgets('six digit mock code verifies and keeps pending destination', (
    tester,
  ) async {
    final otp = _FakeOtpService();
    final auth = _FakeAuthenticationService();
    await tester.pumpWidget(_app(otp: otp, authentication: auth));
    await _openOtp(tester);

    final verify = find.byKey(const ValueKey('verifyOtpButton'));
    expect(_isButtonEnabled(tester, verify), isFalse);

    await tester.enterText(find.byKey(const ValueKey('otpCell0')), '123456');
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
    await tester.pumpAndSettle();

    expect(auth.markAuthenticatedCount, 1);
    expect(find.byKey(const ValueKey('otpDestination')), findsOneWidget);
    expect(container.read(otpAuthControllerProvider).otpCode, isEmpty);
  });

  testWidgets('incorrect code shows an inline error and keeps digits', (
    tester,
  ) async {
    final otp = _FakeOtpService();
    await tester.pumpWidget(_app(otp: otp));
    await _openOtp(tester);

    await tester.enterText(find.byKey(const ValueKey('otpCell0')), '654321');
    await tester.pump();
    final verify = find.byKey(const ValueKey('verifyOtpButton'));
    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.pumpAndSettle();

    expect(
      find.text('The verification code is incorrect. Please try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('otpCell0')))
          .controller
          ?.text,
      '6',
    );
  });

  testWidgets('resend is throttled and requests once after countdown', (
    tester,
  ) async {
    final otp = _FakeOtpService();
    await tester.pumpWidget(_app(otp: otp));
    await _openOtp(tester);

    final resend = find.byKey(const ValueKey('resendOtpButton'));
    expect(_isTextButtonEnabled(tester, resend), isFalse);
    await tester.pump(const Duration(seconds: 30));
    expect(_isTextButtonEnabled(tester, resend), isTrue);

    await tester.tap(resend);
    await tester.tap(resend);
    await tester.pump();

    expect(otp.requestCount, 2);
    expect(find.text('A new verification code has been sent.'), findsOneWidget);
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
        path: '/destination',
        builder: (context, state) =>
            const SizedBox(key: ValueKey('otpDestination')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      otpServiceProvider.overrideWithValue(otp),
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
    return OtpVerificationResult(success: code == '123456');
  }
}

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
