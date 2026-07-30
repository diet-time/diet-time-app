import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/features/personalization/data/guest_session_repository.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final guestProfileRepositoryProvider = Provider<GuestProfileRepository>(
  (ref) => GuestProfileRepository(
    apiClient: ref.watch(apiClientProvider),
    sessions: ref.watch(guestSessionRepositoryProvider),
  ),
);

class GuestProfileRepository {
  const GuestProfileRepository({
    required this.apiClient,
    required this.sessions,
  });

  final ApiClient apiClient;
  final GuestSessionRepository sessions;

  Future<CustomerProfile?> getProfile() {
    return _withGuestSession((token) async {
      final response = await apiClient.request(
        method: 'GET',
        path: ApiEndpoints.guestProfile,
        headers: {'X-Guest-Token': token},
      );
      if (response.statusCode == 404) return null;
      if (!response.isSuccess) throw ApiException.fromResponse(response);
      return _profileFromResponse(response);
    });
  }

  Future<CustomerProfile> saveProfile(CustomerProfile profile) {
    return _withGuestSession((token) async {
      final response = await apiClient.request(
        method: 'PUT',
        path: ApiEndpoints.guestProfile,
        headers: {'X-Guest-Token': token},
        body: profile.toJson(),
      );
      if (!response.isSuccess) throw ApiException.fromResponse(response);
      return _profileFromResponse(response, fallback: profile) ?? profile;
    });
  }

  Future<T> _withGuestSession<T>(
    Future<T> Function(String token) action,
  ) async {
    var session = await sessions.ensureSession();
    try {
      return await action(session.token);
    } on ApiException catch (error) {
      if (error.failure != ApiFailure.unauthorized) rethrow;
      await sessions.clear();
      session = await sessions.createSession();
      return action(session.token);
    }
  }
}

CustomerProfile? _profileFromResponse(
  ApiResponse response, {
  CustomerProfile fallback = const CustomerProfile(),
}) {
  final data = response.body['data'];
  if (data == null) return null;
  if (data is! Map<String, dynamic>) {
    throw const ApiException(ApiFailure.invalidResponse);
  }
  return CustomerProfile.fromJson(data, fallback: fallback);
}
