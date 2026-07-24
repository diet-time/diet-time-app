import 'package:diet_time/core/storage/shared_preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  return LanguageRepository(ref.watch(sharedPreferencesServiceProvider));
});

class LanguageRepository {
  LanguageRepository(this._preferences);

  static const preferenceKey = 'preferredLanguage';
  static const selectionCompletedKey = 'languageSelectionCompletedV2';

  final SharedPreferencesService _preferences;

  Future<String?> loadPreferredLanguage() =>
      _preferences.getString(preferenceKey);

  Future<bool> hasCompletedLanguageSelection() async =>
      await _preferences.getBool(selectionCompletedKey) ?? false;

  Future<void> savePreferredLanguage(String languageCode) async {
    await _preferences.setString(preferenceKey, languageCode);
    await _preferences.setBool(selectionCompletedKey, true);
  }
}
