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

  @override
  Future<bool> isLoggedIn() async {
    final values = await Future.wait([
      _storage.read(SecureStorageService.accessTokenKey),
      _storage.read(SecureStorageService.accessTokenExpiresAtKey),
    ]);
    final accessToken = values[0]?.trim() ?? '';
    final expiresAt = DateTime.tryParse(values[1] ?? '');
    return accessToken.isNotEmpty &&
        expiresAt != null &&
        expiresAt.isAfter(DateTime.now().toUtc());
  }

  @override
  // OTP writes credentials before calling this hook. A local flag cannot grant
  // access when those credentials are missing or expired.
  Future<void> markAuthenticated() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signIn({
    required String identity,
    required String password,
  }) async {
    await markAuthenticated();
  }
}
