import 'package:diet_time/app/theme/app_theme.dart';
import 'package:diet_time/features/personalization/data/display_name_repository.dart';
import 'package:diet_time/features/personalization/presentation/display_name_panel.dart';
import 'package:diet_time/features/personalization/presentation/post_login_landing_screen.dart';
import 'package:diet_time/features/personalization/presentation/post_login_name_gate.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('asks for a missing name after login and saves it', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PostLoginLandingScreen), findsOneWidget);
    expect(find.byType(DisplayNamePanel), findsOneWidget);
    expect(find.text('What should we call you?'), findsOneWidget);

    final continueButton = find.descendant(
      of: find.byKey(const ValueKey('displayNameContinue')),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('displayNameInput')),
      '  Noor  ',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('displayNameContinue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(DisplayNameRepository.displayNameKey), 'Noor');
    expect(preferences.getBool(DisplayNameRepository.capturedKey), isTrue);
    expect(find.byType(DisplayNamePanel), findsNothing);
  });

  testWidgets('does not ask again when the name is already captured', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      DisplayNameRepository.displayNameKey: 'Noor',
      DisplayNameRepository.capturedKey: true,
    });

    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PostLoginLandingScreen), findsOneWidget);
    expect(find.byType(DisplayNamePanel), findsNothing);
  });
}

Widget _app() {
  const locale = Locale('en');
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      theme: AppTheme.light(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: PostLoginNameGate(onContinue: _noop),
    ),
  );
}

void _noop() {}
