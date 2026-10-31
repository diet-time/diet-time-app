import 'dart:convert';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:go_router/go_router.dart';
import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_screen.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/dashboard/presentation/customer_profile_controller.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/app_tour/app_tour_controller.dart';
import 'package:diet_time/features/app_tour/app_tour_host.dart';
import 'package:diet_time/features/app_tour/tour_copy.dart';
import 'package:diet_time/features/authentication/domain/auth_models.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class TourAuth extends OtpAuthController {
  @override
  OtpAuthState build() => session('a');
  void change(String id) => state = session(id);
  static OtpAuthState session(String id) => OtpAuthState(
    isAuthenticated: true,
    session: AuthSession(
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
      accessTokenExpiresAt: DateTime(2099),
      refreshTokenExpiresAt: DateTime(2099),
      user: AuthUser(
        id: id,
        email: '',
        name: 'Test',
        roles: const ['Customer'],
        phoneNumber: '+97400000000',
      ),
    ),
  );
}

class TourRepository extends AppTourRepository {
  TourRepository() : super(ApiClient());
  bool fail = false;
  final values = <bool>[];
  Completer<void>? pending;
  @override
  Future<Map<String, dynamic>> save(String token, bool enabled) async {
    values.add(enabled);
    if (pending != null) await pending!.future;
    if (fail) throw Exception('offline');
    return {
      'isAppTourEnabled': enabled,
      'rowVersion': 9,
      'updatedAt': '2026-10-31T10:00:00Z',
    };
  }
}

ProviderContainer setup(TourRepository repository, {bool enabled = true}) {
  final container = ProviderContainer(
    overrides: [
      otpAuthControllerProvider.overrideWith(TourAuth.new),
      appTourRepositoryProvider.overrideWithValue(repository),
    ],
  );
  container
      .read(personalizationControllerProvider.notifier)
      .replace(
        CustomerProfile(
          genderCode: 'FEMALE',
          dateOfBirth: '1995-03-17',
          heightCm: 165,
          weightKg: 70,
          goalCode: 'LOSE_WEIGHT',
          dailyRoutineCode: 'OFFICE_WORK',
          activityLevelCode: 'MOSTLY_SITTING',
          onboardingStatus: 'COMPLETED',
          nextStepCode: 'PROFILE_COMPLETED',
          shouldShowOnboarding: false,
          profileId: 'profile-a',
          userId: 'a',
          isAppTourEnabled: enabled,
          preferredName: 'Keep me',
          preferences: const {'VEGETARIAN'},
        ),
      );
  container.read(appTourControllerProvider.notifier).navigate = (_) async {};
  addTearDown(container.dispose);
  return container;
}

class TourDashboard extends CustomerDashboardController {
  @override
  CustomerDashboardState build() => const DashboardLoading();
  @override
  Future<void> initialize({String? profileId, bool force = false}) async {}
  @override
  Future<void> refresh() async {}
  void ready() => state = const DashboardNoOrders();
}

class TourAccount extends CustomerProfileController {
  @override
  CustomerProfileState build() => const CustomerProfileState(hasLoaded: true);
}

class RestoredTourAuth extends TourAuth {
  @override
  OtpAuthState build() => const OtpAuthState(isAuthenticated: true);
}

class TourStorage extends SecureStorageService {
  TourStorage(this.values);
  final Map<String, String> values;
  @override
  Future<String?> read(String key) async => values[key];
}

void main() {
  test(
    'tour waits for questionnaire completion without consuming first-login eligibility',
    () {
      final container = setup(TourRepository());
      final profile = container.read(personalizationControllerProvider);
      container
          .read(personalizationControllerProvider.notifier)
          .replace(
            profile.copyWith(
              onboardingStatus: 'IN_PROGRESS',
              nextStepCode: 'ALLERGENS',
              shouldShowOnboarding: true,
            ),
          );
      final controller = container.read(appTourControllerProvider.notifier);
      controller.maybeStart();
      expect(container.read(appTourControllerProvider).running, isFalse);
      container
          .read(personalizationControllerProvider.notifier)
          .replace(profile);
      controller.maybeStart();
      expect(container.read(appTourControllerProvider).running, isTrue);
    },
  );
  test(
    'customers without plans skip unavailable actions even after enabling detailed guidance',
    () {
      final c = setup(TourRepository());
      final controller = c.read(appTourControllerProvider.notifier);
      controller.maybeStart(hasPlanCards: false, hasActivePlan: false);
      controller.detail(true);
      final ids = c
          .read(appTourControllerProvider)
          .steps
          .map((step) => step.id)
          .toSet();
      expect(
        ids.intersection({
          'viewDetails',
          'orderDetails',
          'tomorrow',
          'chooseMeals',
          'confirmation',
        }),
        isEmpty,
      );
      expect(
        ids,
        containsAll({
          'menuButton',
          'newPlan',
          'navigation',
          'orders',
          'calendar',
          'profileTab',
          'settings',
        }),
      );
      expect(c.read(appTourControllerProvider).steps.last.id, 'settings');
    },
  );
  test(
    'customers with plans receive the matching order and meal-button guidance',
    () {
      final c = setup(TourRepository());
      final controller = c.read(appTourControllerProvider.notifier);
      controller.maybeStart(hasPlanCards: true, hasActivePlan: true);
      controller.detail(true);
      final ids = c
          .read(appTourControllerProvider)
          .steps
          .map((step) => step.id)
          .toList();
      expect(
        ids,
        containsAll({
          'viewDetails',
          'orderDetails',
          'tomorrow',
          'chooseMeals',
          'confirmation',
        }),
      );
      expect(ids.toSet().length, ids.length);
      expect(ids.indexOf('viewDetails') + 1, ids.indexOf('orderDetails'));
      expect(ids.indexOf('newPlan') + 1, ids.indexOf('choosePlan'));
    },
  );

  testWidgets(
    'restored session can enable from Profile and launch on returning Home',
    (tester) async {
      final repository = TourRepository();
      final container = ProviderContainer(
        overrides: [
          otpAuthControllerProvider.overrideWith(RestoredTourAuth.new),
          secureStorageServiceProvider.overrideWithValue(
            TourStorage({
              SecureStorageService.authenticatedUserIdKey: 'a',
              SecureStorageService.accessTokenKey: 'stored-token',
            }),
          ),
          appTourRepositoryProvider.overrideWithValue(repository),
          customerDashboardControllerProvider.overrideWith(TourDashboard.new),
          customerProfileControllerProvider.overrideWith(TourAccount.new),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(personalizationControllerProvider.notifier)
          .replace(
            const CustomerProfile(
              genderCode: 'FEMALE',
              dateOfBirth: '1995-03-17',
              heightCm: 165,
              weightKg: 70,
              goalCode: 'LOSE_WEIGHT',
              dailyRoutineCode: 'OFFICE_WORK',
              activityLevelCode: 'MOSTLY_SITTING',
              onboardingStatus: 'COMPLETED',
              nextStepCode: 'PROFILE_COMPLETED',
              shouldShowOnboarding: false,
              profileId: 'profile-a',
              userId: 'a',
              isAppTourEnabled: false,
            ),
          );
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const CustomerDashboardScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (_, child) => AppTourHost(child: child!),
          ),
        ),
      );
      (container.read(customerDashboardControllerProvider.notifier)
              as TourDashboard)
          .ready();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(container.read(otpAuthControllerProvider).session, isNull);
      expect(find.byKey(const ValueKey('appTourTooltip')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('dashboardProfileTab')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('appTourSetting')));
      await tester.tap(find.byKey(const ValueKey('appTourSetting')));
      await tester.pumpAndSettle();
      expect(repository.values, [true]);
      expect(
        container.read(personalizationControllerProvider).isAppTourEnabled,
        isTrue,
      );
      expect(
        find.text('Tour enabled. Return to Home to start.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('appTourTooltip')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('dashboardHomeTab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.byKey(const ValueKey('appTourTooltip')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tourSkip')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(repository.values, [true, false]);
      expect(
        container.read(personalizationControllerProvider).isAppTourEnabled,
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    },
  );
  test(
    'older restored session resolves identity from token without sharing preference',
    () async {
      final token =
          'header.${base64Url.encode(utf8.encode(jsonEncode({'sub': 'a'})))}.signature';
      final repo = TourRepository();
      final c = ProviderContainer(
        overrides: [
          otpAuthControllerProvider.overrideWith(RestoredTourAuth.new),
          secureStorageServiceProvider.overrideWithValue(
            TourStorage({SecureStorageService.accessTokenKey: token}),
          ),
          appTourRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      c
          .read(personalizationControllerProvider.notifier)
          .replace(
            const CustomerProfile(
              genderCode: 'FEMALE',
              dateOfBirth: '1995-03-17',
              heightCm: 165,
              weightKg: 70,
              goalCode: 'LOSE_WEIGHT',
              dailyRoutineCode: 'OFFICE_WORK',
              activityLevelCode: 'MOSTLY_SITTING',
              onboardingStatus: 'COMPLETED',
              nextStepCode: 'PROFILE_COMPLETED',
              shouldShowOnboarding: false,
              profileId: 'profile-a',
              userId: 'a',
              isAppTourEnabled: true,
            ),
          );
      final controller = c.read(appTourControllerProvider.notifier);
      controller.navigate = (_) async {};
      await c.read(appTourIdentityProvider.future);
      controller.maybeStart();
      expect(c.read(appTourControllerProvider).running, isTrue);
      expect(await controller.setEnabled(false), isTrue);
      expect(repo.values, [false]);
    },
  );
  test(
    'missing restored credentials does not report a successful preference save',
    () async {
      final repo = TourRepository();
      final c = ProviderContainer(
        overrides: [
          otpAuthControllerProvider.overrideWith(RestoredTourAuth.new),
          secureStorageServiceProvider.overrideWithValue(TourStorage({})),
          appTourRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      c
          .read(personalizationControllerProvider.notifier)
          .replace(
            const CustomerProfile(
              genderCode: 'FEMALE',
              dateOfBirth: '1995-03-17',
              heightCm: 165,
              weightKg: 70,
              goalCode: 'LOSE_WEIGHT',
              dailyRoutineCode: 'OFFICE_WORK',
              activityLevelCode: 'MOSTLY_SITTING',
              onboardingStatus: 'COMPLETED',
              nextStepCode: 'PROFILE_COMPLETED',
              shouldShowOnboarding: false,
              profileId: 'profile-a',
              userId: 'a',
            ),
          );
      expect(
        await c.read(appTourControllerProvider.notifier).setEnabled(true),
        isFalse,
      );
      expect(c.read(appTourControllerProvider).failedValue, isTrue);
      expect(
        c.read(personalizationControllerProvider).isAppTourEnabled,
        isFalse,
      );
      expect(repo.values, isEmpty);
    },
  );

  testWidgets(
    'dashboard waits for readiness, navigates existing routes and returns without duplicates',
    (tester) async {
      final repository = TourRepository();
      final container = ProviderContainer(
        overrides: [
          otpAuthControllerProvider.overrideWith(TourAuth.new),
          appTourRepositoryProvider.overrideWithValue(repository),
          customerDashboardControllerProvider.overrideWith(TourDashboard.new),
          customerProfileControllerProvider.overrideWith(TourAccount.new),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(personalizationControllerProvider.notifier)
          .replace(
            const CustomerProfile(
              genderCode: 'FEMALE',
              dateOfBirth: '1995-03-17',
              heightCm: 165,
              weightKg: 70,
              goalCode: 'LOSE_WEIGHT',
              dailyRoutineCode: 'OFFICE_WORK',
              activityLevelCode: 'MOSTLY_SITTING',
              onboardingStatus: 'COMPLETED',
              nextStepCode: 'PROFILE_COMPLETED',
              shouldShowOnboarding: false,
              profileId: 'profile-a',
              userId: 'a',
              isAppTourEnabled: true,
            ),
          );
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const CustomerDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.menu,
            builder: (_, _) => const Scaffold(
              body: SizedBox(
                key: ValueKey('guestMealPlanHeader'),
                height: 100,
                child: Text('Existing menu route'),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.plans,
            builder: (_, _) => const Scaffold(
              body: SizedBox(
                key: ValueKey('tourPlanSelection'),
                height: 100,
                child: Text('Existing plans route'),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (_, child) => AppTourHost(child: child!),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(container.read(appTourControllerProvider).running, isFalse);
      (container.read(customerDashboardControllerProvider.notifier)
              as TourDashboard)
          .ready();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(container.read(appTourControllerProvider).running, isTrue);
      final controller = container.read(appTourControllerProvider.notifier);
      final menuIndex = container
          .read(appTourControllerProvider)
          .steps
          .indexWhere((step) => step.id == 'menu');
      controller.move(menuIndex - 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('Next opens the Menu screen.'), findsOneWidget);
      expect(find.byKey(const ValueKey('dashboardMenuButton')), findsOneWidget);
      expect(find.byKey(const ValueKey('tourProgress')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tourNext')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(
        router.routerDelegate.currentConfiguration.last.route.path,
        AppRoutes.menu,
      );
      expect(router.canPop(), isTrue);
      await tester.tap(find.byKey(const ValueKey('tourPrevious')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(
        router.routerDelegate.currentConfiguration.last.route.path,
        AppRoutes.home,
      );
      expect(router.canPop(), isFalse);
      await tester.tap(find.byKey(const ValueKey('tourNext')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(
        router.routerDelegate.currentConfiguration.last.route.path,
        AppRoutes.menu,
      );
      for (final (id, index) in [
        ('navigation', 0),
        ('orders', 1),
        ('calendar', 2),
        ('profileTab', 3),
      ]) {
        final tour = container.read(appTourControllerProvider);
        final stepIndex = tour.steps.indexWhere((step) => step.id == id);
        controller.move(stepIndex - tour.index);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        expect(
          tester
              .widget<NavigationBar>(
                find.byKey(const ValueKey('dashboardNavigation')),
              )
              .selectedIndex,
          index,
        );
        expect(
          router.routerDelegate.currentConfiguration.last.route.path,
          AppRoutes.home,
        );
      }
      // Final Finish, just like Skip, returns through the same stack and persists false.
      controller.move(
        container.read(appTourControllerProvider).steps.length -
            1 -
            container.read(appTourControllerProvider).index,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tourNext')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(
        router.routerDelegate.currentConfiguration.last.route.path,
        AppRoutes.home,
      );
      expect(router.canPop(), isFalse);
      expect(repository.values, [false]);
      expect(find.byType(CustomerDashboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    },
  );

  test(
    'profile reads tour preference, defaults false and preserves it across unrelated edits',
    () {
      expect(CustomerProfile.fromJson({}).isAppTourEnabled, isFalse);
      final p = CustomerProfile.fromJson({
        'profileId': 'p',
        'userId': 'a',
        'isAppTourEnabled': true,
      });
      expect(p.copyWith(weightKg: 70).isAppTourEnabled, isTrue);
      expect(p.toJson().containsKey('isAppTourEnabled'), isFalse);
      expect(p.userId, 'a');
    },
  );
  test(
    'launch is gated by saved preference, account ownership and once per session',
    () async {
      final c = setup(TourRepository(), enabled: false);
      final controller = c.read(appTourControllerProvider.notifier);
      controller.maybeStart();
      expect(c.read(appTourControllerProvider).running, isFalse);
      await controller.setEnabled(true);
      controller.maybeStart();
      expect(c.read(appTourControllerProvider).running, isTrue);
      controller.move(1);
      controller.maybeStart();
      expect(c.read(appTourControllerProvider).index, 1);
      await controller.finish();
      controller.maybeStart();
      expect(c.read(appTourControllerProvider).running, isFalse);
      await controller.setEnabled(true);
      controller.maybeStart();
      expect(c.read(appTourControllerProvider).running, isTrue);
    },
  );
  test(
    'failed skip keeps persisted ON and supports retry without automatic restart',
    () async {
      final repo = TourRepository()..fail = true;
      final c = setup(repo);
      final controller = c.read(appTourControllerProvider.notifier)
        ..maybeStart();
      await controller.finish();
      expect(c.read(appTourControllerProvider).running, isFalse);
      expect(c.read(appTourControllerProvider).failedValue, false);
      expect(
        c.read(personalizationControllerProvider).isAppTourEnabled,
        isTrue,
      );
      controller.maybeStart();
      expect(c.read(appTourControllerProvider).running, isFalse);
      repo.fail = false;
      await controller.setEnabled(false);
      final profile = c.read(personalizationControllerProvider);
      expect(profile.isAppTourEnabled, isFalse);
      expect(profile.rowVersion, 9);
      expect(profile.preferredName, 'Keep me');
      expect(profile.preferences, {'VEGETARIAN'});
    },
  );
  test(
    'account switch cancels tour and discards previous customer inflight result',
    () async {
      final repo = TourRepository()..pending = Completer<void>();
      final c = setup(repo);
      final controller = c.read(appTourControllerProvider.notifier)
        ..maybeStart();
      final saving = controller.finish();
      (c.read(otpAuthControllerProvider.notifier) as TourAuth).change('b');
      c
          .read(personalizationControllerProvider.notifier)
          .replace(
            const CustomerProfile(
              genderCode: 'FEMALE',
              dateOfBirth: '1995-03-17',
              heightCm: 165,
              weightKg: 70,
              goalCode: 'LOSE_WEIGHT',
              dailyRoutineCode: 'OFFICE_WORK',
              activityLevelCode: 'MOSTLY_SITTING',
              onboardingStatus: 'COMPLETED',
              nextStepCode: 'PROFILE_COMPLETED',
              shouldShowOnboarding: false,
              profileId: 'profile-b',
              userId: 'b',
              isAppTourEnabled: true,
            ),
          );
      repo.pending!.complete();
      await saving;
      expect(c.read(personalizationControllerProvider).profileId, 'profile-b');
      expect(
        c.read(personalizationControllerProvider).isAppTourEnabled,
        isTrue,
      );
      expect(c.read(appTourControllerProvider).saving, isFalse);
    },
  );
  test('stale profile from another account cannot start or save', () async {
    final repo = TourRepository();
    final c = setup(repo);
    (c.read(otpAuthControllerProvider.notifier) as TourAuth).change('b');
    final controller = c.read(appTourControllerProvider.notifier);
    controller.navigate = (_) async {};
    controller.maybeStart();
    await controller.setEnabled(false);
    expect(c.read(appTourControllerProvider).running, isFalse);
    expect(repo.values, isEmpty);
  });
  test(
    'optional missing features are removed, previous and final step remain valid',
    () {
      final c = setup(TourRepository());
      final controller = c.read(appTourControllerProvider.notifier)
        ..maybeStart();
      controller.detail(true);
      expect(
        c.read(appTourControllerProvider).steps.length,
        basicTourSteps.length + detailedTourSteps.length,
      );
      final steps = c.read(appTourControllerProvider).steps;
      final optionalIndex = steps.indexWhere((step) => step.id == 'tomorrow');
      controller.move(optionalIndex);
      controller.unavailable();
      expect(
        c.read(appTourControllerProvider).step.id,
        steps[optionalIndex + 1].id,
      );
      controller.move(-1);
      expect(
        c.read(appTourControllerProvider).step.id,
        steps[optionalIndex - 1].id,
      );
      while (c.read(appTourControllerProvider).index <
          c.read(appTourControllerProvider).steps.length - 1) {
        controller.move(1);
      }
      expect(c.read(appTourControllerProvider).step.id, 'settings');
    },
  );
  test('all tour strings have English and Arabic translations', () {
    expect(tourArabic.keys.toSet(), tourEnglish.keys.toSet());
    for (final step in [...basicTourSteps, ...detailedTourSteps]) {
      expect(tourEnglish.containsKey(step.id), isTrue);
      expect(tourArabic.containsKey('${step.id}.title'), isTrue);
      if (step.nextHint != null) {
        expect(tourEnglish.containsKey(step.nextHint), isTrue);
        expect(tourArabic.containsKey(step.nextHint), isTrue);
      }
    }
  });
  for (final locale in ['en', 'ar']) {
    testWidgets(
      'real spotlight navigates Next/Previous, skips and fits narrow $locale screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = TourRepository();
        final c = setup(repo);
        final destinations = <String>[];
        c.read(appTourControllerProvider.notifier).navigate = (route) async {
          destinations.add(route);
        };
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp(
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => AppTourHost(child: child!),
              home: Scaffold(
                body: ListView(
                  children: const [
                    SizedBox(
                      key: ValueKey('dashboardHeaderControls'),
                      height: 70,
                      child: Text('Header'),
                    ),
                    SizedBox(
                      key: ValueKey('noActivePlan'),
                      height: 100,
                      child: Text('Actual card'),
                    ),
                    AppTourSetting(),
                  ],
                ),
              ),
            ),
          ),
        );
        c.read(appTourControllerProvider.notifier).maybeStart();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
        expect(find.byKey(const ValueKey('appTourTooltip')), findsOneWidget);
        expect(destinations.last, 'home');
        await tester.tap(find.byKey(const ValueKey('tourNext')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
        expect(c.read(appTourControllerProvider).index, 1);
        await tester.tap(find.byKey(const ValueKey('tourPrevious')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
        expect(c.read(appTourControllerProvider).index, 0);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('tourSkip')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        expect(find.byKey(const ValueKey('appTourTooltip')), findsNothing);
        expect(repo.values, [false]);
        expect(
          c.read(personalizationControllerProvider).isAppTourEnabled,
          isFalse,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
      },
    );
  }
}
