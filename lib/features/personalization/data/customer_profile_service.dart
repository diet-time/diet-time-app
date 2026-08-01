import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerProfileServiceProvider = Provider<ProfilePersistenceService>(
  (ref) => CustomerProfileService(
    customerRepository: ref.watch(customerProfileRepositoryProvider),
  ),
);

abstract interface class ProfilePersistenceService {
  Future<CustomerProfile?> load();

  Future<CustomerProfile> saveProgress(CustomerProfile profile);

  Future<CustomerProfile> complete(CustomerProfile profile);
}

class CustomerProfileService implements ProfilePersistenceService {
  const CustomerProfileService({required this.customerRepository});

  final CustomerProfileRepository customerRepository;

  @override
  Future<CustomerProfile?> load() => customerRepository.getProfile();

  @override
  Future<CustomerProfile> saveProgress(CustomerProfile profile) {
    final pending = profile.copyWith(onboardingStatus: 'IN_PROGRESS');
    return customerRepository.updateProfile(pending);
  }

  @override
  Future<CustomerProfile> complete(CustomerProfile profile) {
    return customerRepository.updateProfile(
      profile.copyWith(onboardingStatus: 'COMPLETED'),
    );
  }
}
