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
    final user = await storage!.read(
      SecureStorageService.authenticatedUserIdKey,
    );
    return token == null || token.isEmpty || user == null || user.isEmpty
        ? guestDraftKey
        : 'questionnaire.user.$user';
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
    if (pending == null) return remote;
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
