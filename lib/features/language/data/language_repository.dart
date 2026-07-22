import 'package:diet_time/core/storage/shared_preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  return LanguageRepository(ref.watch(sharedPreferencesServiceProvider));
});

class LanguageRepository {
  LanguageRepository(this._preferences);

  static const preferenceKey = 'preferredLanguage';

  final SharedPreferencesService _preferences;

  Future<String?> loadPreferredLanguage() =>
      _preferences.getString(preferenceKey);

  Future<void> savePreferredLanguage(String languageCode) =>
      _preferences.setString(preferenceKey, languageCode);
}
