import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesServiceProvider = Provider<SharedPreferencesService>(
  (ref) => SharedPreferencesService(),
);

class SharedPreferencesService {
  SharedPreferencesService({Future<SharedPreferences> Function()? factory})
    : _factory = factory ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _factory;

  Future<String?> getString(String key) async {
    final preferences = await _factory();
    return preferences.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final preferences = await _factory();
    await preferences.setString(key, value);
  }

  Future<void> remove(String key) async {
    final preferences = await _factory();
    await preferences.remove(key);
  }
}
