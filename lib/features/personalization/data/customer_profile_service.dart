import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerProfileServiceProvider = Provider<CustomerProfileService>(
  (ref) => CustomerProfileService(
    repository: ref.watch(customerProfileRepositoryProvider),
  ),
);

class CustomerProfileService {
  const CustomerProfileService({required this.repository});

  final CustomerProfileRepository repository;

  Future<CustomerProfile?> load() => repository.getProfile();

  Future<CustomerProfile> saveProgress(CustomerProfile profile) {
    return repository.updateProfile(
      profile.copyWith(onboardingStatus: 'IN_PROGRESS'),
    );
  }

  Future<CustomerProfile> complete(CustomerProfile profile) {
    return repository.updateProfile(
      profile.copyWith(onboardingStatus: 'COMPLETED'),
    );
  }
}
