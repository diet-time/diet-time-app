import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/features/dashboard/data/customer_account_profile_repository.dart';
import 'package:diet_time/features/dashboard/domain/customer_account_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads the authenticated profile and nested default address', () async {
    final api = _ProfileApiClient();
    final repository = ApiCustomerAccountProfileRepository(
      apiClient: api,
      accessTokenProvider: () async => 'access-token',
    );

    final profile = await repository.getProfile();

    expect(api.method, 'GET');
    expect(api.path, ApiEndpoints.customerAccountProfile);
    expect(api.headers['Authorization'], 'Bearer access-token');
    expect(profile.fullName, 'Aisha Noor');
    expect(profile.mobileNumber, '+97450000000');
    expect(profile.defaultAddress?.addressName, 'Home');
    expect(profile.defaultAddress?.isDefault, isTrue);
  });

  test('profile update sends only editable account fields', () async {
    final api = _ProfileApiClient();
    final repository = ApiCustomerAccountProfileRepository(
      apiClient: api,
      accessTokenProvider: () async => 'access-token',
    );

    await repository.updateProfile(
      UpdateCustomerProfileRequest(
        fullName: '  Aisha Noor  ',
        dateOfBirth: DateTime(1990, 8, 13),
        gender: 'FEMALE',
      ),
    );

    expect(api.method, 'PUT');
    expect(api.body, {
      'fullName': 'Aisha Noor',
      'dateOfBirth': '1990-08-13',
      'gender': 'FEMALE',
    });
    expect(api.body, isNot(contains('mobileNumber')));
    expect(api.body, isNot(contains('customerId')));
  });
}

class _ProfileApiClient extends ApiClient {
  String? method;
  String? path;
  Map<String, String> headers = const {};
  Map<String, dynamic>? body;

  @override
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
  }) async {
    this.method = method;
    this.path = path;
    this.headers = headers;
    this.body = body;
    return const ApiResponse(
      statusCode: 200,
      body: {
        'data': {
          'id': 'customer-id',
          'fullName': 'Aisha Noor',
          'mobileNumber': '+97450000000',
          'dateOfBirth': '1990-08-13',
          'gender': 'FEMALE',
          'addresses': [
            {
              'id': 'address-id',
              'addressName': 'Home',
              'addressType': 'HOME',
              'unitNumber': '12',
              'buildingNo': '8',
              'streetNo': '20',
              'zoneNo': '31',
              'area': 'Doha',
              'latitude': 25.28,
              'longitude': 51.53,
              'formattedAddress': 'Pinned location, Doha',
              'isDefault': true,
            },
          ],
        },
      },
    );
  }
}
