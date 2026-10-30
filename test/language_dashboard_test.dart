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

void main() {
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
      await tester.binding.setSurfaceSize(const Size(360, 800));
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
      expect(find.text('Explore Menu'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dashboardLanguage-ar')));
      await tester.pumpAndSettle();
      expect(find.text('استكشف القائمة'), findsOneWidget);
      expect(find.text('الطلبات'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(CustomerDashboardScreen))),
        TextDirection.rtl,
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(LanguageRepository.preferenceKey), 'ar');
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('dashboardLanguage-en')));
      await tester.pumpAndSettle();
      expect(find.text('Explore Menu'), findsOneWidget);
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
