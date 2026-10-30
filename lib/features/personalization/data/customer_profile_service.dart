import 'dart:convert';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerProfileServiceProvider = Provider<ProfilePersistenceService>(
  (ref) => CustomerProfileService(
    customerRepository: ref.watch(customerProfileRepositoryProvider),
    storage: ref.watch(secureStorageServiceProvider),
  ),
);

abstract interface class ProfilePersistenceService {
  Future<CustomerProfile?> load();

  Future<CustomerProfile> saveProgress(CustomerProfile profile);

  Future<CustomerProfile> complete(CustomerProfile profile);
}

class CustomerProfileService implements ProfilePersistenceService {
  const CustomerProfileService({
    required this.customerRepository,
    this.storage,
  });

  final CustomerProfileRepository customerRepository;
  final SecureStorageService? storage;
  static const guestDraftKey = 'questionnaire.guest';

  Future<String> _key() async {
    if (storage == null) return 'questionnaire.auth';
    final token = await storage!.read(SecureStorageService.accessTokenKey);
    var user = await storage!.read(SecureStorageService.authenticatedUserIdKey);
    if (token == null || token.isEmpty) return guestDraftKey;
    if (user == null || user.isEmpty) {
      // Sessions from older app versions may not have persisted the identity key.
      // This only scopes the local cache; the API always derives ownership from the token.
      try {
        final claims =
            jsonDecode(
                  utf8.decode(
                    base64Url.decode(base64Url.normalize(token.split('.')[1])),
                  ),
                )
                as Map<String, dynamic>;
        user =
            (claims['sub'] ??
                    claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'])
                ?.toString();
      } on Object {
        throw const CustomerProfileException(statusCode: 401);
      }
      if (user == null || user.isEmpty) {
        throw const CustomerProfileException(statusCode: 401);
      }
      await storage!.write(SecureStorageService.authenticatedUserIdKey, user);
    }
    return 'questionnaire.user.$user';
  }

  Future<CustomerProfile?> _draft(String key) async {
    final raw = await storage?.read(key);
    return raw == null
        ? null
        : CustomerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _cache(String key, CustomerProfile profile) async {
    await storage?.write(
      key,
      jsonEncode({
        ...profile.toJson(),
        'preferredLanguage': profile.preferredLanguage,
        'profileId': profile.profileId,
        'preferences': profile.preferences.toList(),
        'allergens': profile.allergens.toList(),
      }),
    );
  }

  @override
  Future<CustomerProfile?> load() async {
    final key = await _key();
    if (key == guestDraftKey) return _draft(key);
    var pending = await _draft(key);
    final guest = await _draft(guestDraftKey);
    if (guest != null) {
      pending ??= guest;
      // Claim a guest draft for this identity before any network request.
      await _cache(key, pending);
      await storage?.delete(guestDraftKey);
    }
    final remote = await customerRepository.getProfile();
    // A guest draft must never overwrite a returning customer's completed answers.
    if (remote?.isCompleted == true &&
        pending?.profileId != remote!.profileId) {
      await storage?.delete(key);
      return remote;
    }
    if (pending == null) return remote;
    if (remote != null) {
      pending = remote.copyWith(
        genderCode: pending.genderCode,
        dateOfBirth: pending.dateOfBirth,
        heightCm: pending.heightCm,
        weightKg: pending.weightKg,
        goalCode: pending.goalCode,
        dailyRoutineCode: pending.dailyRoutineCode,
        activityLevelCode: pending.activityLevelCode,
        preferences: pending.preferencesConfirmed
            ? pending.preferences
            : remote.preferences,
        allergens: pending.allergensConfirmed
            ? pending.allergens
            : remote.allergens,
        preferencesConfirmed:
            pending.preferencesConfirmed || remote.preferencesConfirmed,
        allergensConfirmed:
            pending.allergensConfirmed || remote.allergensConfirmed,
        onboardingStatus: pending.onboardingStatus,
      );
    }
    final saved = await customerRepository.updateProfile(
      pending.copyWith(
        profileId: remote?.profileId,
        rowVersion: remote?.rowVersion,
      ),
    );
    await storage?.delete(key);
    return saved;
  }

  Future<CustomerProfile> _save(CustomerProfile profile) async {
    final key = await _key();
    await _cache(key, profile);
    if (key == guestDraftKey) return profile;
    final saved = await customerRepository.updateProfile(profile);
    await storage?.delete(key);
    return saved;
  }

  @override
  Future<CustomerProfile> saveProgress(CustomerProfile profile) {
    final pending = profile.copyWith(onboardingStatus: 'IN_PROGRESS');
    return _save(pending);
  }

  @override
  Future<CustomerProfile> complete(CustomerProfile profile) {
    return _save(profile.copyWith(onboardingStatus: 'COMPLETED'));
  }
}
