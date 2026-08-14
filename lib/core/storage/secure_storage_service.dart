import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const accessTokenKey = 'accessToken';
  static const accessTokenExpiresAtKey = 'accessTokenExpiresAt';
  static const refreshTokenKey = 'refreshToken';
  static const refreshTokenExpiresAtKey = 'refreshTokenExpiresAt';
  static const temporaryCustomerPhoneKey = 'temporaryCustomerPhone';
  static const authenticatedUserIdKey = 'authenticatedUserId';

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clear() => _storage.deleteAll();
}
