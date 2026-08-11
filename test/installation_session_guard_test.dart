import 'package:diet_time/core/storage/installation_session_guard.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/core/storage/shared_preferences_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'fresh installation clears credentials retained by the platform',
    () async {
      final storage = SecureStorageService(
        storage: const FlutterSecureStorage(),
      );
      await storage.write(SecureStorageService.accessTokenKey, 'old-token');
      await storage.write(SecureStorageService.refreshTokenKey, 'old-refresh');
      final guard = InstallationSessionGuard(
        preferences: SharedPreferencesService(),
        secureStorage: storage,
      );

      await guard.prepare();

      expect(await storage.read(SecureStorageService.accessTokenKey), isNull);
      expect(await storage.read(SecureStorageService.refreshTokenKey), isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool(InstallationSessionGuard.markerKey), isTrue);
    },
  );

  test('upgrade from an existing installation preserves credentials', () async {
    SharedPreferences.setMockInitialValues({'preferredLanguage': 'en'});
    final storage = SecureStorageService(storage: const FlutterSecureStorage());
    await storage.write(SecureStorageService.accessTokenKey, 'active-token');
    final guard = InstallationSessionGuard(
      preferences: SharedPreferencesService(),
      secureStorage: storage,
    );

    await guard.prepare();

    expect(
      await storage.read(SecureStorageService.accessTokenKey),
      'active-token',
    );
  });
}
