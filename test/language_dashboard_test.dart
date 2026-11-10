import 'package:go_router/go_router.dart';
import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/menu/data/guest_menu_repository.dart';
import 'package:diet_time/features/menu/domain/guest_home_models.dart';
import 'package:diet_time/features/menu/presentation/browse_menu_screen.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_screen.dart';
import 'package:diet_time/features/language/presentation/language_controller.dart';
import 'package:diet_time/features/language/data/language_repository.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' show Intl;
import 'package:diet_time/app/theme/app_theme.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets(
      'Menu and Language have matching flat rounded surfaces on $platform',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerDashboardControllerProvider.overrideWith(
                _EmptyDashboard.new,
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(
                const Locale('en'),
              ).copyWith(platform: platform),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const CustomerDashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final menu = find.byKey(const ValueKey('dashboardMenuButton'));
        final language = find.byKey(
          const ValueKey('dashboardLanguageSelector'),
        );
        expect(tester.getSize(menu).height, 44);
        expect(tester.getSize(language).height, 44);
        final support = find.byKey(const ValueKey('dashboardSupportButton'));
        expect(tester.getSize(support), const Size(48, 48));
        expect(tester.widget<IconButton>(support).tooltip, 'Support');
        expect(
          tester.getRect(support).left,
          closeTo(tester.getRect(menu).right + 6, .1),
        );
        expect(
          tester.getRect(language).right,
          greaterThan(tester.getRect(support).right),
        );
        final button = tester.widget<FilledButton>(menu);
        expect(button.clipBehavior, Clip.antiAlias);
        expect(button.style!.elevation!.resolve({}), 0);
        const child = SizedBox();
        expect(
          button.style!.backgroundBuilder!(tester.element(menu), {}, child),
          same(child),
        );
        await tester.tap(support);
        await tester.pumpAndSettle();
        expect(find.text('Support will be available soon.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'compact Menu shortcut opens existing screen and arrow restores the same dashboard',
    (tester) async {
      final repository = _HeaderMenuRepository();
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const CustomerDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.menu,
            builder: (context, state) =>
                BrowseMenuScreen(fromDashboard: state.extra == 'dashboard'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(
              _EmptyDashboard.new,
            ),
            otpAuthControllerProvider.overrideWith(_HeaderAuth.new),
            guestMenuRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final original = tester.state(find.byType(CustomerDashboardScreen));
      expect(find.byKey(const ValueKey('dashboardExploreMenu')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('dashboardMenuButton')));
      await tester.pumpAndSettle();
      expect(find.byType(BrowseMenuScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('backToDashboard')), findsNothing);
      expect(find.byKey(const ValueKey('guestStartPlan')), findsOneWidget);
      final reads = repository.reads;
      await tester.tap(find.byKey(const ValueKey('guestMenuBack')));
      await tester.pumpAndSettle();
      expect(
        tester.state(find.byType(CustomerDashboardScreen)),
        same(original),
      );
      expect(router.canPop(), isFalse);
      expect(repository.reads, reads);
      await tester.pumpWidget(const SizedBox());
    },
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Intl.defaultLocale = 'en';
  });
  tearDown(() {
    Intl.defaultLocale = 'en';
  });
  testWidgets(
    'dashboard switch updates shortcut, tabs, direction and saved preference',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerDashboardControllerProvider.overrideWith(
              _EmptyDashboard.new,
            ),
          ],
          child: const _App(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Menu'), findsOneWidget);
      expect(find.byKey(const ValueKey('dashboardExploreMenu')), findsNothing);
      expect(find.text('Explore Menu'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('dashboardLanguageSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dashboard-language-ar')));
      await tester.pumpAndSettle();
      expect(find.text('القائمة'), findsOneWidget);
      expect(find.text('الطلبات'), findsWidgets);
      expect(
        Directionality.of(tester.element(find.byType(CustomerDashboardScreen))),
        TextDirection.rtl,
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(LanguageRepository.preferenceKey), 'ar');
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('dashboardLanguageSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dashboard-language-en')));
      await tester.pumpAndSettle();
      expect(find.text('Menu'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(CustomerDashboardScreen))),
        TextDirection.ltr,
      );
      expect(preferences.getString(LanguageRepository.preferenceKey), 'en');
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('language preference restores in a new provider container', () async {
    final first = ProviderContainer();
    await first.read(languageControllerProvider.notifier).selectLanguage('ar');
    first.dispose();
    final second = ProviderContainer();
    addTearDown(second.dispose);
    second.read(languageControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(second.read(languageControllerProvider).languageCode, 'ar');
  });
}

class _App extends ConsumerWidget {
  const _App();
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    locale: ref.watch(languageControllerProvider),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: const CustomerDashboardScreen(),
  );
}

class _EmptyDashboard extends CustomerDashboardController {
  @override
  CustomerDashboardState build() => const DashboardNoOrders();
  @override
  Future<void> initialize({String? profileId, bool force = false}) async {}
  @override
  Future<void> refresh() async {}
}

class _HeaderAuth extends OtpAuthController {
  @override
  Future<bool> ensureCurrentSession() async => state.isAuthenticated;

  @override
  OtpAuthState build() => const OtpAuthState(isAuthenticated: true);
}

class _HeaderMenuRepository implements GuestMenuRepository {
  int reads = 0;
  @override
  Future<GuestHomeResponse> getGuestHome({
    required String language,
    DateTime? date,
    String? planCode,
  }) async {
    reads++;
    return const GuestHomeResponse.empty();
  }

  @override
  Future<GuestMenuResponse> getGuestMenu({
    required String language,
    required String planCode,
    required DateTime date,
  }) async {
    reads++;
    return GuestMenuResponse.empty(planCode: planCode, date: date);
  }
}
