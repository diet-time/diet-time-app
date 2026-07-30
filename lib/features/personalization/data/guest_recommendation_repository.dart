import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/network/api_endpoints.dart';
import 'package:diet_time/features/personalization/data/guest_session_repository.dart';
import 'package:diet_time/features/personalization/domain/plan_recommendation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final guestRecommendationRepositoryProvider =
    Provider<GuestRecommendationRepository>(
      (ref) => GuestRecommendationRepository(
        apiClient: ref.watch(apiClientProvider),
        sessions: ref.watch(guestSessionRepositoryProvider),
      ),
    );

final guestPlanRecommendationsProvider =
    FutureProvider.family<List<PlanRecommendation>, String>((ref, language) {
      return ref
          .watch(guestRecommendationRepositoryProvider)
          .getRecommendations(language: language);
    });

class GuestRecommendationRepository {
  const GuestRecommendationRepository({
    required this.apiClient,
    required this.sessions,
  });

  final ApiClient apiClient;
  final GuestSessionRepository sessions;

  Future<List<PlanRecommendation>> getRecommendations({
    required String language,
  }) async {
    var session = await sessions.ensureSession();
    ApiResponse response;
    try {
      response = await _request(session.token, language);
      if (response.statusCode == 401) {
        throw ApiException.fromResponse(response);
      }
    } on ApiException catch (error) {
      if (error.failure != ApiFailure.unauthorized) rethrow;
      await sessions.clear();
      session = await sessions.createSession();
      response = await _request(session.token, language);
    }
    if (!response.isSuccess) throw ApiException.fromResponse(response);
    final data = response.body['data'];
    final rawPlans = data is List
        ? data
        : data is Map<String, dynamic> && data['plans'] is List
        ? data['plans'] as List
        : const [];
    return rawPlans
        .whereType<Map<String, dynamic>>()
        .map(PlanRecommendation.fromJson)
        .where((plan) => plan.id.isNotEmpty && plan.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<ApiResponse> _request(String token, String language) {
    return apiClient.request(
      method: 'GET',
      path: ApiEndpoints.guestPlanRecommendations,
      queryParameters: {'language': language},
      headers: {'X-Guest-Token': token},
    );
  }
}
