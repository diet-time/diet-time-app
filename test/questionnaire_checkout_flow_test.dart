import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/checkout/data/orders_repository.dart';
import 'package:diet_time/features/checkout/domain/order_models.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/checkout/presentation/checkout_entry_screen.dart';
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
    testWidgets('ordinary login honors active subscriptions: $hasOrders', (
      tester,
    ) async {
      final profiles = _Profiles(
        const CustomerProfile(profileId: 'profile-id', goalCode: 'LOSE_WEIGHT'),
      );
      final container = _container(profiles, orders: _Orders(hasOrders));
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
      expect(
        find.text(hasOrders ? 'Dashboard' : 'Browse plans'),
        findsOneWidget,
      );
    });
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

class _Profiles implements ProfilePersistenceService {
  _Profiles(this.profile);
  CustomerProfile profile;
  int loads = 0;
  @override
  Future<CustomerProfile?> load() async {
    loads++;
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
  @override
  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String profileId, {
    int pageSize = 20,
  }) async => hasOrders
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
