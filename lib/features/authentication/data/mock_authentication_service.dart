import 'package:flutter_riverpod/flutter_riverpod.dart';

final authenticationServiceProvider = Provider<AuthenticationService>((ref) {
  return MockAuthenticationService();
});

abstract interface class AuthenticationService {
  Future<bool> isLoggedIn();

  Future<void> signIn({required String identity, required String password});

  Future<void> markAuthenticated();
}

class MockAuthenticationService implements AuthenticationService {
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
}
