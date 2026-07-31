import 'package:diet_time/app/theme/app_theme.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/personalization/data/display_name_repository.dart';
import 'package:diet_time/features/personalization/presentation/display_name_panel.dart';
import 'package:diet_time/features/personalization/presentation/post_login_landing_screen.dart';
import 'package:diet_time/features/personalization/presentation/post_login_name_gate.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      SecureStorageService.accessTokenKey: 'access-token',
    });
  });

  testWidgets('asks for a missing name after login and saves it', (
    tester,
  ) async {
    final api = _DisplayNameApiClient();
    await tester.pumpWidget(_app(api));
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
    expect(api.savedDisplayName, 'Noor');
    expect(api.patchCalls, 1);
    expect(find.byType(DisplayNamePanel), findsNothing);
  });

  testWidgets('does not ask again when the name is already captured', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      DisplayNameRepository.displayNameKey: 'Noor',
      DisplayNameRepository.capturedKey: true,
    });

    final api = _DisplayNameApiClient(profileDisplayName: 'Noor');
    await tester.pumpWidget(_app(api));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PostLoginLandingScreen), findsOneWidget);
    expect(find.byType(DisplayNamePanel), findsNothing);
    expect(api.patchCalls, 0);
  });
}

Widget _app(ApiClient api) {
  const locale = Locale('en');
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(api)],
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

class _DisplayNameApiClient extends ApiClient {
  _DisplayNameApiClient({this.profileDisplayName});

  String? profileDisplayName;
  String? savedDisplayName;
  int patchCalls = 0;

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    expect(headers['Authorization'], 'Bearer access-token');
    if (method == 'GET' && path == ApiEndpoints.customerProfile) {
      if (profileDisplayName == null) {
        return const ApiResponse(statusCode: 404, body: {});
      }
      return ApiResponse(
        statusCode: 200,
        body: {
          'data': {'preferredName': profileDisplayName},
        },
      );
    }
    if (method == 'PATCH' &&
        path == '${ApiEndpoints.customerProfile}/preferred-name') {
      patchCalls++;
      savedDisplayName = body?['preferredName']?.toString();
      profileDisplayName = savedDisplayName;
      return ApiResponse(
        statusCode: 200,
        body: {
          'data': {'preferredName': profileDisplayName},
        },
      );
    }
    throw StateError('Unexpected request: $method $path');
  }
}
