import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authenticationServiceProvider = Provider<AuthenticationService>((ref) {
  return MockAuthenticationService(ref.watch(secureStorageServiceProvider));
});

abstract interface class AuthenticationService {
  Future<bool> isLoggedIn();

  Future<void> signIn({required String identity, required String password});
}

class MockAuthenticationService implements AuthenticationService {
  const MockAuthenticationService(this._storage);

  final SecureStorageService _storage;

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<void> signIn({
    required String identity,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await _storage.delete('auth_token');
  }
}
