import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authenticationServiceProvider = Provider<AuthenticationService>((ref) {
  return SecureStorageAuthenticationService(
    ref.watch(secureStorageServiceProvider),
  );
});

abstract interface class AuthenticationService {
  Future<bool> isLoggedIn();

  Future<void> signIn({required String identity, required String password});

  Future<void> markAuthenticated();
}

abstract interface class SignOutAuthenticationService {
  Future<void> signOut();
}

class MockAuthenticationService
    implements AuthenticationService, SignOutAuthenticationService {
  bool _isAuthenticated = false;

  @override
  Future<bool> isLoggedIn() async => _isAuthenticated;

  @override
  Future<void> signIn({
    required String identity,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await markAuthenticated();
  }

  @override
  Future<void> markAuthenticated() async {
    _isAuthenticated = true;
  }

  @override
  Future<void> signOut() async => _isAuthenticated = false;
}

class SecureStorageAuthenticationService
    implements AuthenticationService, SignOutAuthenticationService {
  SecureStorageAuthenticationService(this._storage);

  final SecureStorageService _storage;
  bool _authenticatedInMemory = false;

  @override
  Future<bool> isLoggedIn() async {
    if (_authenticatedInMemory) return true;
    final values = await Future.wait([
      _storage.read(SecureStorageService.accessTokenKey),
      _storage.read(SecureStorageService.accessTokenExpiresAtKey),
    ]);
    final accessToken = values[0]?.trim() ?? '';
    final expiresAt = DateTime.tryParse(values[1] ?? '');
    final isValid =
        accessToken.isNotEmpty &&
        expiresAt != null &&
        expiresAt.isAfter(DateTime.now().toUtc());
    if (isValid) _authenticatedInMemory = true;
    return isValid;
  }

  @override
  Future<void> markAuthenticated() async {
    _authenticatedInMemory = true;
  }

  @override
  Future<void> signOut() async {
    _authenticatedInMemory = false;
  }

  @override
  Future<void> signIn({
    required String identity,
    required String password,
  }) async {
    await markAuthenticated();
  }
}
