import 'dart:math';

import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';

class MockOtpSessionRepository {
  const MockOtpSessionRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage;

  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  Future<String?> createSession(String phoneNumber) async {
    final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (normalizedPhone.isEmpty) return null;

    final storedPhone = await _secureStorage.read(
      SecureStorageService.mockAuthPhoneKey,
    );
    var password = storedPhone == normalizedPhone
        ? await _secureStorage.read(SecureStorageService.mockAuthPasswordKey)
        : null;
    password ??= _newPassword();
    await _secureStorage.write(
      SecureStorageService.mockAuthPhoneKey,
      normalizedPhone,
    );
    await _secureStorage.write(
      SecureStorageService.mockAuthPasswordKey,
      password,
    );

    final credentials = {
      'email': 'mobile+$normalizedPhone@diettime.local',
      'password': password,
    };
    var response = await _apiClient.request(
      method: 'POST',
      path: ApiEndpoints.authRegister,
      body: credentials,
    );
    if (response.statusCode == 409) {
      response = await _apiClient.request(
        method: 'POST',
        path: ApiEndpoints.authLogin,
        body: credentials,
      );
    }
    if (!response.isSuccess) throw ApiException.fromResponse(response);

    final data = response.body['data'];
    if (data is! Map<String, dynamic>) return null;
    final accessToken = data['accessToken']?.toString().trim();
    final refreshToken = data['refreshToken']?.toString().trim();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.write(
        SecureStorageService.refreshTokenKey,
        refreshToken,
      );
    }
    return accessToken == null || accessToken.isEmpty ? null : accessToken;
  }

  String _newPassword() {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    final suffix = List.generate(
      28,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
    return 'Dt1!$suffix';
  }
}
