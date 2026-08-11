import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/core/storage/shared_preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final installationSessionGuardProvider = Provider<InstallationSessionGuard>(
  (ref) => InstallationSessionGuard(
    preferences: ref.watch(sharedPreferencesServiceProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  ),
);

/// Prevents credentials retained outside the app sandbox from authenticating a
/// newly installed copy of the app.
///
/// Android backup is disabled in the manifest. This additional marker handles
/// platforms such as iOS, where keychain entries can survive an uninstall.
class InstallationSessionGuard {
  const InstallationSessionGuard({
    required SharedPreferencesService preferences,
    required SecureStorageService secureStorage,
  }) : _preferences = preferences,
       _secureStorage = secureStorage;

  static const markerKey = 'installationSessionInitializedV1';
  static const _languageKey = 'preferredLanguage';
  static const _languageSelectionKey = 'languageSelectionCompletedV2';

  final SharedPreferencesService _preferences;
  final SecureStorageService _secureStorage;

  Future<void> prepare() async {
    if (await _preferences.getBool(markerKey) == true) return;

    // Preserve the session for users upgrading from a version that predates
    // this marker. A true fresh install has no ordinary app preferences.
    final hasExistingInstallation =
        (await _preferences.getString(_languageKey)) != null ||
        (await _preferences.getBool(_languageSelectionKey)) == true;
    if (!hasExistingInstallation) {
      try {
        await _secureStorage.clear();
      } on Object {
        // Secure storage can be unavailable on unsupported platforms. The
        // authentication check will still treat an unreadable session as guest.
      }
    }
    await _preferences.setBool(markerKey, true);
  }
}
