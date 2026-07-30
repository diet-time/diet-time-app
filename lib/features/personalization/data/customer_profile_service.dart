import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/data/guest_profile_repository.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerProfileServiceProvider = Provider<ProfilePersistenceService>(
  (ref) => CustomerProfileService(
    customerRepository: ref.watch(customerProfileRepositoryProvider),
    guestRepository: ref.watch(guestProfileRepositoryProvider),
  ),
);

abstract interface class ProfilePersistenceService {
  Future<CustomerProfile?> load({required bool authenticated});

  Future<CustomerProfile> saveProgress(
    CustomerProfile profile, {
    required bool authenticated,
  });

  Future<CustomerProfile> complete(
    CustomerProfile profile, {
    required bool authenticated,
  });
}

class CustomerProfileService implements ProfilePersistenceService {
  const CustomerProfileService({
    required this.customerRepository,
    required this.guestRepository,
  });

  final CustomerProfileRepository customerRepository;
  final GuestProfileRepository guestRepository;

  @override
  Future<CustomerProfile?> load({required bool authenticated}) => authenticated
      ? customerRepository.getProfile()
      : guestRepository.getProfile();

  @override
  Future<CustomerProfile> saveProgress(
    CustomerProfile profile, {
    required bool authenticated,
  }) {
    final pending = profile.copyWith(onboardingStatus: 'IN_PROGRESS');
    return authenticated
        ? customerRepository.updateProfile(pending)
        : guestRepository.saveProfile(pending);
  }

  @override
  Future<CustomerProfile> complete(
    CustomerProfile profile, {
    required bool authenticated,
  }) {
    if (!authenticated) {
      // Guest completion is determined exclusively by the API response.
      return guestRepository.saveProfile(
        profile.copyWith(onboardingStatus: 'IN_PROGRESS'),
      );
    }
    return customerRepository.updateProfile(
      profile.copyWith(onboardingStatus: 'COMPLETED'),
    );
  }
}
