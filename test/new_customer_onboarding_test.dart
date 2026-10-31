import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/authenticated_landing_screen.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const completeProfile = CustomerProfile(
  profileId: 'profile',
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
);

void main() {
  for (final profile in <CustomerProfile?>[
    null,
    const CustomerProfile(profileId: 'profile'),
  ]) {
    test(
      'dashboard defers dependent requests for ${profile == null ? 'missing' : 'incomplete'} profile',
      () async {
        final profiles = _Repository(profile);
        final orders = _Orders();
        final container = ProviderContainer(
          overrides: [
            customerProfileRepositoryProvider.overrideWithValue(profiles),
            ordersRepositoryProvider.overrideWithValue(orders),
          ],
        );
        addTearDown(container.dispose);
        final dashboard = container.read(
          customerDashboardControllerProvider.notifier,
        );
        await dashboard.initialize();
        expect(
          container.read(customerDashboardControllerProvider),
          profile == null
              ? isA<DashboardProfileNotFound>()
              : isA<DashboardNeedsOnboarding>(),
        );
        await dashboard.initialize();
        expect(profiles.gets, 1);
        expect(orders.gets, 0);
      },
    );
  }
  for (final profile in <CustomerProfile?>[
    null,
    const CustomerProfile(profileId: 'profile', goalCode: 'LOSE_WEIGHT'),
    completeProfile,
  ]) {
    testWidgets(
      'login gates persisted profile ${profile?.onboardingStatus ?? 'missing'}',
      (tester) async {
        final service = _Profiles(profile);
        final container = _container(service);
        addTearDown(container.dispose);
        final router = _router();
        addTearDown(router.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            profile?.isCompleted == true
                ? 'Dashboard'
                : 'Profile and questionnaire',
          ),
          findsOneWidget,
        );
        expect(service.loads, 1);
        expect(service.saves, 0);
        expect(
          container.read(otpAuthControllerProvider).isAuthenticated,
          isTrue,
        );
        expect(router.canPop(), isFalse);
        if (profile != null) {
          expect(
            container.read(personalizationControllerProvider).goalCode,
            profile.goalCode,
          );
        }
      },
    );
  }

  for (final error in <Object>[
    const CustomerProfileException(statusCode: 500),
    TimeoutException('offline'),
    const CustomerProfileException(statusCode: 404, code: 'route_not_found'),
  ]) {
    testWidgets(
      '$error offers retry and preserves the session without creating a profile',
      (tester) async {
        final service = _Profiles(completeProfile)..error = error;
        final container = _container(service);
        addTearDown(container.dispose);
        final router = _router();
        addTearDown(router.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('authenticatedLandingError')),
          findsOneWidget,
        );
        expect(find.text('Profile and questionnaire'), findsNothing);
        expect(service.saves, 0);
        expect(
          container.read(otpAuthControllerProvider).isAuthenticated,
          isTrue,
        );
        service.error = null;
        await tester.tap(find.text('TRY AGAIN'));
        await tester.pumpAndSettle();
        expect(find.text('Dashboard'), findsOneWidget);
        expect(service.loads, 2);
      },
    );
  }

  for (final recover in [true, false]) {
    testWidgets(
      'expired profile request uses existing session recovery: $recover',
      (tester) async {
        final service = _Profiles(completeProfile)
          ..error = const CustomerProfileException(statusCode: 401);
        final container = _container(service, recover: recover);
        addTearDown(container.dispose);
        final router = _router();
        addTearDown(router.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(recover ? 'Dashboard' : 'Sign in'), findsOneWidget);
        expect(
          (container.read(otpAuthControllerProvider.notifier) as _Auth)
              .refreshes,
          1,
        );
        expect(service.saves, 0);
      },
    );
  }

  test('only a stable profile_not_found 404 is onboarding', () async {
    final client = _Client(404, {
      'errors': [
        {'code': 'profile_not_found'},
      ],
    });
    final repository = HttpCustomerProfileRepository(
      clientFactory: () => client,
    );
    expect(await repository.getProfile(), isNull);
    for (final response in [
      (404, <String, dynamic>{}),
      (
        404,
        <String, dynamic>{
          'errors': [
            {'code': 'route_not_found'},
          ],
        },
      ),
      (500, <String, dynamic>{}),
      (200, <String, dynamic>{'data': null}),
      (
        200,
        <String, dynamic>{
          'data': {'goalCode': 'LOSE_WEIGHT'},
        },
      ),
    ]) {
      final repository = HttpCustomerProfileRepository(
        clientFactory: () => _Client(response.$1, response.$2),
      );
      await expectLater(
        repository.getProfile(),
        throwsA(isA<CustomerProfileException>()),
      );
    }
  });

  test(
    'first save requests create-only while subsequent saves update the owned profile',
    () async {
      final client = _Client(200, {
        'data': {'id': 'profile', 'genderCode': 'FEMALE'},
      });
      final repository = HttpCustomerProfileRepository(
        clientFactory: () => client,
      );
      final saved = await repository.updateProfile(
        const CustomerProfile(genderCode: 'FEMALE'),
      );
      expect((jsonDecode(client.body) as Map)['createOnly'], isTrue);
      await repository.updateProfile(saved);
      expect(
        (jsonDecode(client.body) as Map).containsKey('createOnly'),
        isFalse,
      );
    },
  );
  test('creation with no saved profile identifier is an API failure', () async {
    final repository = HttpCustomerProfileRepository(
      clientFactory: () => _Client(200, {'data': {}}),
    );
    await expectLater(
      repository.updateProfile(const CustomerProfile(genderCode: 'FEMALE')),
      throwsA(isA<CustomerProfileException>()),
    );
  });
}

GoRouter _router() => GoRouter(
  initialLocation: '/entry',
  routes: [
    GoRoute(
      path: '/entry',
      builder: (_, _) => const AuthenticatedLandingScreen(),
    ),
    GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('Dashboard')),
    GoRoute(
      path: AppRoutes.customerSetup,
      builder: (_, _) => const Text('Profile and questionnaire'),
    ),
    GoRoute(
      path: AppRoutes.phoneLogin,
      builder: (_, _) => const Text('Sign in'),
    ),
  ],
);

ProviderContainer _container(_Profiles profiles, {bool recover = true}) =>
    ProviderContainer(
      overrides: [
        customerProfileServiceProvider.overrideWithValue(profiles),
        otpAuthControllerProvider.overrideWith(() => _Auth(profiles, recover)),
      ],
    );

class _Profiles implements ProfilePersistenceService {
  _Profiles(this.profile);
  final CustomerProfile? profile;
  Object? error;
  int loads = 0, saves = 0;
  @override
  Future<CustomerProfile?> load() async {
    loads++;
    if (error != null) throw error!;
    return profile;
  }

  @override
  Future<CustomerProfile> saveProgress(CustomerProfile profile) async {
    saves++;
    return profile;
  }

  @override
  Future<CustomerProfile> complete(CustomerProfile profile) =>
      saveProgress(profile);
}

class _Auth extends OtpAuthController {
  _Auth(this.profiles, this.recover);
  final _Profiles profiles;
  final bool recover;
  int refreshes = 0;
  @override
  OtpAuthState build() => const OtpAuthState(isAuthenticated: true);
  @override
  Future<bool> refreshAfterUnauthorized() async {
    refreshes++;
    if (recover) {
      profiles.error = null;
      return true;
    }
    ref.invalidate(profilePersistenceControllerProvider);
    ref.invalidate(personalizationControllerProvider);
    state = const OtpAuthState();
    return false;
  }
}

class _Headers implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  String? value(String name) => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Repository implements CustomerProfileRepository {
  _Repository(this.profile);
  final CustomerProfile? profile;
  int gets = 0;
  @override
  Future<CustomerProfile?> getProfile() async {
    gets++;
    return profile;
  }

  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async =>
      throw StateError('dashboard must not create');
}

class _Orders extends OrdersRepository {
  _Orders()
    : super(apiClient: ApiClient(), accessTokenProvider: () async => 'token');
  int gets = 0;
  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
  }) async {
    gets++;
    return [];
  }
}

class _Client implements HttpClient {
  _Client(this.status, this.data);
  final int status;
  final Map<String, dynamic> data;
  String body = '';
  @override
  set connectionTimeout(Duration? value) {}
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _Request(this);
  @override
  Future<HttpClientRequest> putUrl(Uri url) async {
    body = '';
    return _Request(this);
  }

  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Request implements HttpClientRequest {
  _Request(this.client);
  final _Client client;
  @override
  final headers = _Headers();
  @override
  void write(Object? object) {
    client.body += object.toString();
  }

  @override
  Future<HttpClientResponse> close() async => _Response(client);
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.client);
  final _Client client;
  @override
  int get statusCode => client.status;
  @override
  final headers = _Headers();
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(utf8.encode(jsonEncode(client.data))).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
