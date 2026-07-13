import 'package:diet_time/features/authentication/data/mock_authentication_service.dart';
import 'package:diet_time/features/authentication/domain/login_credentials.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, AsyncValue<void>>(
      LoginController.new,
    );

class LoginController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> signIn(LoginCredentials credentials) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authenticationServiceProvider)
          .signIn(
            identity: credentials.identity,
            password: credentials.password,
          ),
    );
    return !state.hasError;
  }
}
