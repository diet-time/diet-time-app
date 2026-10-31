import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/checkout/presentation/checkout_entry_screen.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/authenticated_landing_screen.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:diet_time/features/plans/domain/meal_plan_option.dart';
import 'package:diet_time/features/plans/domain/meal_plan_package.dart';
import 'package:diet_time/features/plans/domain/meal_plan_purchase_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('dashboard offers explicit resume while a selection is pending', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        otpAuthControllerProvider.overrideWith(() => _Auth(true)),
        customerDashboardControllerProvider.overrideWith(_Dashboard.new),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(checkoutControllerProvider.notifier)
        .selectPackage(_selection);
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const CustomerDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.checkoutEntry,
          builder: (_, _) => const Text('Checkout resumed'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('resumeSelectedPlan')), findsOneWidget);
    expect(
      container.read(checkoutControllerProvider).orderConfirmation,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('resumeSelectedPlan')));
    await tester.pumpAndSettle();
    expect(find.text('Checkout resumed'), findsOneWidget);
    expect(
      container.read(checkoutControllerProvider).selection,
      same(_selection),
    );
    container.read(checkoutControllerProvider.notifier).clear();
    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('resumeSelectedPlan')), findsNothing);
  });
  for (final authenticated in [false, true]) {
    for (final completed in [false, true]) {
      testWidgets(
        'Start Your Plan authenticated=$authenticated completed=$completed',
        (tester) async {
          final profiles = _Profiles(
            completed
                ? _complete
                : const CustomerProfile(goalCode: 'LOSE_WEIGHT'),
          );
          final container = _container(profiles, authenticated: authenticated);
          addTearDown(container.dispose);
          container
              .read(checkoutControllerProvider.notifier)
              .selectPackage(_selection);
          // A locally changed profile must not replace the backend completion check.
          container
              .read(profilePersistenceControllerProvider.notifier)
              .restore(_complete);
          PendingAuthDestination? destination;
          late final GoRouter router;
          router = GoRouter(
            initialLocation: AppRoutes.startPlan,
            routes: [
              GoRoute(
                path: AppRoutes.startPlan,
                builder: (_, _) => const CheckoutEntryScreen(startPlan: true),
              ),
              GoRoute(
                path: AppRoutes.phoneLogin,
                builder: (_, state) {
                  destination = state.extra as PendingAuthDestination;
                  return TextButton(
                    onPressed: () {
                      (container.read(otpAuthControllerProvider.notifier)
                              as _Auth)
                          .signIn();
                      router.go(destination!.route);
                    },
                    child: const Text('Sign in'),
                  );
                },
              ),
              GoRoute(
                path: AppRoutes.checkoutQuestionnaire,
                builder: (_, state) => Text(
                  state.extra == true
                      ? 'Resume questionnaire'
                      : 'Unexpected questionnaire',
                ),
              ),
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const Text('Dashboard'),
              ),
              GoRoute(
                path: AppRoutes.plans,
                builder: (_, _) => const Text('Plans'),
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(routerConfig: router),
            ),
          );
          await tester.pumpAndSettle();
          if (!authenticated) {
            expect(find.text('Sign in'), findsOneWidget);
            expect(profiles.loads, 0);
            await tester.tap(find.text('Sign in'));
            await tester.pumpAndSettle();
            expect(destination!.route, AppRoutes.startPlan);
          }
          expect(
            find.text(completed ? 'Dashboard' : 'Resume questionnaire'),
            findsOneWidget,
          );
          expect(find.text('Sign in'), findsNothing);
          expect(router.canPop(), isFalse);
          expect(profiles.loads, 1);
          expect(
            container.read(checkoutControllerProvider).selection,
            same(_selection),
          );
          expect(
            container.read(checkoutControllerProvider).orderConfirmation,
            isNull,
          );
        },
      );
    }
  }

  test(
    'failed profile load never grants access using a cached completion',
    () async {
      final profiles = _Profiles(_complete)..failLoad = true;
      final container = _container(profiles);
      addTearDown(container.dispose);
      container
          .read(checkoutControllerProvider.notifier)
          .selectPackage(_selection);
      container
          .read(profilePersistenceControllerProvider.notifier)
          .restore(_complete);
      await expectLater(
        container.read(checkoutAccessProvider).resolve(refreshProfile: true),
        throwsStateError,
      );
    },
  );

  test(
    'successful save with incomplete backend response is not completion',
    () async {
      final container = _container(_Profiles(const CustomerProfile()));
      addTearDown(container.dispose);
      expect(
        await container
            .read(profilePersistenceControllerProvider.notifier)
            .save(complete: true),
        isFalse,
      );
      expect(
        container.read(profilePersistenceControllerProvider).errorMessage,
        isNotNull,
      );
    },
  );
  test(
    'guest keeps selected plan, package and price through login and partial questionnaire',
    () async {
      final profiles = _Profiles(
        const CustomerProfile(goalCode: 'LOSE_WEIGHT'),
      );
      final container = _container(profiles, authenticated: false);
      addTearDown(container.dispose);
      final checkout = container.read(checkoutControllerProvider.notifier);
      checkout.selectPackage(_selection);
      final access = container.read(checkoutAccessProvider);
      expect(await access.resolve(), CheckoutAccess.login);
      expect(profiles.loads, 0);
      (container.read(otpAuthControllerProvider.notifier) as _Auth).signIn();
      expect(await access.resolve(), CheckoutAccess.questionnaire);
      expect(
        container.read(personalizationControllerProvider).goalCode,
        'LOSE_WEIGHT',
      );
      expect(
        container.read(checkoutControllerProvider).selection,
        same(_selection),
      );
      expect(
        container.read(checkoutControllerProvider).selection!.totalPrice,
        900,
      );
      container
          .read(profilePersistenceControllerProvider.notifier)
          .restore(_complete);
      expect(await access.resolve(), CheckoutAccess.summary);
      expect(profiles.loads, 1);
      checkout.begin(
        _selection,
        MealPlanServiceSchedule(serviceDates: [DateTime(2026, 10, 27)]),
      );
      expect(await access.resolve(), CheckoutAccess.summary);
      expect(
        container.read(checkoutControllerProvider).mealPlanPriceId,
        'price-id',
      );
    },
  );

  test(
    'completed questionnaire is reused for additional orders without another profile load',
    () async {
      final profiles = _Profiles(_complete);
      final container = _container(profiles);
      addTearDown(container.dispose);
      final checkout = container.read(checkoutControllerProvider.notifier);
      checkout.selectPackage(_selection);
      expect(
        await container.read(checkoutAccessProvider).resolve(),
        CheckoutAccess.summary,
      );
      checkout.beginNewOrder();
      checkout.selectPackage(_selection);
      expect(
        await container.read(checkoutAccessProvider).resolve(),
        CheckoutAccess.summary,
      );
      expect(profiles.loads, 1);
    },
  );

  test('a completion flag cannot bypass missing mandatory answers', () {
    expect(
      const CustomerProfile(
        onboardingStatus: 'COMPLETED',
        nextStepCode: 'PROFILE_COMPLETED',
        shouldShowOnboarding: false,
      ).isCompleted,
      isFalse,
    );
    expect(_complete.isCompleted, isTrue);
  });

  for (final hasOrders in [false, true]) {
    testWidgets(
      'ordinary or restored login opens dashboard with orders: $hasOrders',
      (tester) async {
        final profiles = _Profiles(
          const CustomerProfile(
            profileId: 'profile-id',
            goalCode: 'LOSE_WEIGHT',
          ),
        );
        final orders = _Orders(hasOrders);
        final container = _container(profiles, orders: orders);
        addTearDown(container.dispose);
        final router = GoRouter(
          initialLocation: '/entry',
          routes: [
            GoRoute(
              path: '/entry',
              builder: (_, _) => const AuthenticatedLandingScreen(),
            ),
            GoRoute(
              path: AppRoutes.plans,
              builder: (_, _) => const Text('Browse plans'),
            ),
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) => const Text('Dashboard'),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Browse plans'), findsNothing);
        expect(
          orders.loads,
          0,
        ); // Routing does not depend on order availability.
      },
    );
  }
}

ProviderContainer _container(
  _Profiles profiles, {
  bool authenticated = true,
  _Orders? orders,
}) => ProviderContainer(
  overrides: [
    otpAuthControllerProvider.overrideWith(() => _Auth(authenticated)),
    customerProfileServiceProvider.overrideWithValue(profiles),
    ordersRepositoryProvider.overrideWithValue(orders ?? _Orders(false)),
  ],
);

class _Auth extends OtpAuthController {
  _Auth(this.authenticated);
  final bool authenticated;
  void signIn() => state = const OtpAuthState(isAuthenticated: true);
  @override
  OtpAuthState build() => OtpAuthState(isAuthenticated: authenticated);
  @override
  Future<bool> restoreSession() async => state.isAuthenticated;
}

class _Dashboard extends CustomerDashboardController {
  @override
  CustomerDashboardState build() => const DashboardWithoutActivePlan([]);
  @override
  Future<void> initialize({String? profileId, bool force = false}) async {}
}

class _Profiles implements ProfilePersistenceService {
  _Profiles(this.profile);
  CustomerProfile profile;
  int loads = 0;
  bool failLoad = false;
  @override
  Future<CustomerProfile?> load() async {
    loads++;
    if (failLoad) throw StateError('offline');
    return profile;
  }

  @override
  Future<CustomerProfile> saveProgress(CustomerProfile value) async =>
      profile = value;
  @override
  Future<CustomerProfile> complete(CustomerProfile value) async =>
      profile = value;
}

class _Orders extends OrdersRepository {
  _Orders(this.hasOrders)
    : super(apiClient: ApiClient(), accessTokenProvider: () async => 'token');
  final bool hasOrders;
  int loads = 0;
  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
  }) async {
    loads++;
    return hasOrders
        ? [
            CustomerOrderSummary(
              id: 'order-id',
              orderNumber: 'ORD-1',
              planName: 'Plan',
              planDurationName: 'Package',
              status: 'CONFIRMED',
              paymentStatus: 'PENDING',
              totalAmount: 900,
              currencyCode: 'QAR',
              startDate: DateTime(2026, 10, 27),
              endDate: DateTime(2026, 11, 20),
              placedAt: DateTime(2026, 10, 26),
            ),
          ]
        : [];
  }
}

const _complete = CustomerProfile(
  profileId: 'profile-id',
  genderCode: 'FEMALE',
  dateOfBirth: '1995-01-01',
  heightCm: 165,
  weightKg: 70,
  goalCode: 'LOSE_WEIGHT',
  dailyRoutineCode: 'OFFICE_WORK',
  activityLevelCode: 'MODERATE',
  onboardingStatus: 'COMPLETED',
  nextStepCode: 'PROFILE_COMPLETED',
  shouldShowOnboarding: false,
);
final _selection = MealPlanPurchaseSelection(
  mealPlan: const MealPlanOption(id: 'plan-id', code: 'PLAN', name: 'Plan'),
  mealCombination: const MealPlanConfiguration(
    id: 'option-id',
    name: 'Meals',
    packages: [],
  ),
  pricingOption: MealPlanPackage(
    mealPlanPriceId: 'price-id',
    name: '9 Days',
    serviceDays: 9,
    totalPrice: 900,
    dailyPrice: 100,
    currencyCode: 'QAR',
    serverNow: DateTime.utc(2026, 10, 26),
    serverReceivedAt: DateTime.now().toUtc(),
  ),
);
