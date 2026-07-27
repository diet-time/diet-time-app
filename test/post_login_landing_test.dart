import 'package:diet_time/app/theme/app_theme.dart';
import 'package:diet_time/features/personalization/presentation/post_login_landing_screen.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the English welcome experience on a small screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(onContinue: () {}));
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Welcome to Diet Time'), findsOneWidget);
    expect(
      find.text('Your plan starts\nwith you', findRichText: true),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('mainFoodPlate')), findsOneWidget);

    final cta = find.byKey(const ValueKey('postLoginCta'));
    await tester.ensureVisible(cta);
    await tester.pump();
    expect(cta, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CTA is unobstructed and only continues once', (tester) async {
    var continueCount = 0;
    await tester.pumpWidget(_app(onContinue: () => continueCount++));
    await tester.pump(const Duration(milliseconds: 1200));

    final cta = find.byKey(const ValueKey('postLoginCta'));
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.tap(cta);
    await tester.pump();

    expect(continueCount, 1);
  });

  testWidgets('uses Arabic copy and right-to-left layout', (tester) async {
    await tester.pumpWidget(
      _app(locale: const Locale('ar'), onContinue: () {}),
    );
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('مرحباً بك في دايت تايم'), findsOneWidget);
    expect(find.text('خطتك تبدأ\nمنك', findRichText: true), findsOneWidget);
    expect(find.text('خصّص خطتي'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(PostLoginLandingScreen))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('respects the platform reduce-motion setting', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    await tester.pumpWidget(_app(onContinue: () {}));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('reducedMotionFoodComposition')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('animatedFoodComposition')), findsNothing);
  });

  testWidgets('remains scrollable with large accessibility text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 620));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(_app(onContinue: () {}));
    await tester.pump(const Duration(milliseconds: 1200));

    final cta = find.byKey(const ValueKey('postLoginCta'));
    await tester.ensureVisible(cta);
    await tester.pump();

    expect(cta, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({
  required VoidCallback onContinue,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    theme: AppTheme.light(locale),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: PostLoginLandingScreen(onContinue: onContinue),
  );
}
