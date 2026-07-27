import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authenticationServiceProvider = Provider<AuthenticationService>((ref) {
  return MockAuthenticationService(ref.watch(secureStorageServiceProvider));
});

abstract interface class AuthenticationService {
  Future<bool> isLoggedIn();

  Future<void> signIn({required String identity, required String password});

  Future<void> markAuthenticated();
}

class MockAuthenticationService implements AuthenticationService {
  const MockAuthenticationService(this._storage);

  final SecureStorageService _storage;

  @override
  Future<bool> isLoggedIn() async =>
      (await _storage.read('auth_token'))?.isNotEmpty == true;

  @override
  Future<void> signIn({
    required String identity,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await markAuthenticated();
  }

  @override
  Future<void> markAuthenticated() =>
      _storage.write('auth_token', 'mock-session');
}
