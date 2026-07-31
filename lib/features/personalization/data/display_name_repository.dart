import 'package:diet_time/core/storage/shared_preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final displayNameRepositoryProvider = Provider<DisplayNameRepository>((ref) {
  return DisplayNameRepository(ref.watch(sharedPreferencesServiceProvider));
});

class DisplayNameRepository {
  const DisplayNameRepository(this._preferences);

  static const displayNameKey = 'profileDisplayName';
  static const capturedKey = 'profileDisplayNameCaptured';

  final SharedPreferencesService _preferences;

  Future<String?> load() async {
    final captured = await _preferences.getBool(capturedKey) ?? false;
    if (!captured) return null;
    final name = (await _preferences.getString(displayNameKey))?.trim();
    return name == null || name.isEmpty ? null : name;
  }

  Future<void> save(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return;
    await _preferences.setString(displayNameKey, normalized);
    await _preferences.setBool(capturedKey, true);
  }
}
