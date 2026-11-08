import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/dashboard/domain/customer_account_profile.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/dashboard/presentation/customer_profile_controller.dart';
import 'package:diet_time/features/onboarding/presentation/onboarding_screen.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/customer_onboarding_coordinator.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:diet_time/features/personalization/presentation/questionnaire_deferral_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _new = CustomerProfile(profileId: 'profile', preferredName: 'Noor');
final _partial = _new.copyWith(goalCode: 'LOSE_WEIGHT');

void main() {
  for (final startPlan in [false, true]) {
    for (final profile in [_new, _partial]) {
      testWidgets(
        'intro waits for Start and resumes saved step: plan=$startPlan goal=${profile.goalCode}',
        (tester) async {
          final profiles = _Profiles(profile);
          final container = _container(profiles);
          addTearDown(container.dispose);
          final router = container.read(appRouterProvider);
          router.go(
            startPlan ? AppRoutes.startPlan : AppRoutes.authenticatedLanding,
          );
          await tester.pumpWidget(_app(container));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('onboardingStep-0')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('personalizationNotNow')),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('onboardingStep-1')), findsNothing);
          expect(profiles.writes, 0);
          await tester.tap(find.byKey(const ValueKey('onboardingContinue')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(
              ValueKey(
                profile.goalCode == null
                    ? 'onboardingStep-1'
                    : 'onboardingStep-2',
              ),
            ),
            findsOneWidget,
          );
          expect(profiles.writes, 0);
        },
      );
    }

    testWidgets(
      'Not Now reaches Dashboard and Profile can resume: plan=$startPlan',
      (tester) async {
        final profiles = _Profiles(_partial);
        final container = _container(profiles);
        addTearDown(container.dispose);
        final router = container.read(appRouterProvider);
        router.go(
          startPlan ? AppRoutes.startPlan : AppRoutes.authenticatedLanding,
        );
        await tester.pumpWidget(_app(container));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('personalizationNotNow')),
        );
        await tester.tap(find.byKey(const ValueKey('personalizationNotNow')));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));
        expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
        expect(find.byType(PersonalizationScreen), findsNothing);
        expect(container.read(customerDashboardAvailableProvider), isTrue);
        expect(container.read(customerOnboardingReadyProvider), isFalse);
        expect(
          container
              .read(profilePersistenceControllerProvider)
              .persistedProfile!
              .isCompleted,
          isFalse,
        );
        expect(profiles.profile.goalCode, 'LOSE_WEIGHT');
        expect(profiles.writes, 0);
        expect(container.read(checkoutControllerProvider).selection, isNull);
        expect(
          container.read(customerOnboardingCoordinatorProvider).intent.name,
          'normalLogin',
        );
        await tester.tap(find.byKey(const ValueKey('dashboardProfileTab')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('customerQuestionnaireOption')),
        );
        await tester.tap(
          find.byKey(const ValueKey('customerQuestionnaireOption')),
        );
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.last.route.path,
          AppRoutes.customerQuestionnaire,
        );
        expect(find.byKey(const ValueKey('onboardingStep-0')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('onboardingContinue')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('onboardingStep-2')), findsOneWidget);
        expect(profiles.writes, 0);
      },
    );
  }

  test(
    'real dashboard initialization accepts explicit questionnaire deferral',
    () async {
      final orders = _Orders();
      final container = ProviderContainer(
        overrides: [
          otpAuthControllerProvider.overrideWith(_Auth.new),
          customerProfileServiceProvider.overrideWithValue(_Profiles(_partial)),
          checkoutControllerProvider.overrideWith(_Checkout.new),
          ordersRepositoryProvider.overrideWithValue(orders),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(questionnaireDeferralProvider.notifier)
          .defer(cacheDraft: false);
      await container
          .read(customerDashboardControllerProvider.notifier)
          .initialize();
      expect(
        container.read(customerDashboardControllerProvider),
        isA<DashboardNoOrders>(),
      );
      expect(orders.reads, 1);
      expect(container.read(customerOnboardingReadyProvider), isFalse);
    },
  );
}

ProviderContainer _container(_Profiles profiles) => ProviderContainer(
  overrides: [
    otpAuthControllerProvider.overrideWith(_Auth.new),
    secureStorageServiceProvider.overrideWithValue(_Storage()),
    customerProfileServiceProvider.overrideWithValue(profiles),
    customerDashboardControllerProvider.overrideWith(_Dashboard.new),
    customerProfileControllerProvider.overrideWith(_Account.new),
  ],
);

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp.router(
    routerConfig: container.read(appRouterProvider),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ),
);

class _Profiles implements ProfilePersistenceService {
  _Profiles(this.profile);
  final CustomerProfile profile;
  int writes = 0;
  @override
  Future<CustomerProfile?> load() async => profile;
  @override
  Future<CustomerProfile> saveProgress(CustomerProfile profile) async {
    writes++;
    throw StateError('No writes from introduction or deferral');
  }

  @override
  Future<CustomerProfile> complete(CustomerProfile profile) =>
      saveProgress(profile);
}

class _Auth extends OtpAuthController {
  @override
  OtpAuthState build() => const OtpAuthState(isAuthenticated: true);
  @override
  Future<bool> ensureCurrentSession() async => true;
}

class _Storage extends SecureStorageService {
  @override
  Future<String?> read(String key) async => null;
}

class _Dashboard extends CustomerDashboardController {
  @override
  CustomerDashboardState build() => const DashboardNoOrders();
  @override
  Future<void> initialize({String? profileId, bool force = false}) async {}
}

class _Account extends CustomerProfileController {
  @override
  CustomerProfileState build() => const CustomerProfileState(
    hasLoaded: true,
    profile: CustomerAccountProfile(
      id: 'profile',
      fullName: 'Noor',
      mobileNumber: '+97474452435',
    ),
  );
}

class _Checkout extends CheckoutController {
  @override
  Future<void> loadAddressesForProfile(String profileId) async {}
}

class _Orders extends OrdersRepository {
  _Orders()
    : super(apiClient: ApiClient(), accessTokenProvider: () async => 'token');
  int reads = 0;
  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
    bool dashboard = false,
  }) async {
    reads++;
    return [];
  }
}
