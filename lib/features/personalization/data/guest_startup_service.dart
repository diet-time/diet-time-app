import 'package:diet_time/features/personalization/data/guest_profile_repository.dart';
import 'package:diet_time/features/personalization/data/guest_session_repository.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class GuestStartupService {
  Future<void> ensureSession();
  Future<CustomerProfile?> getProfile();
}

final guestStartupServiceProvider = Provider<GuestStartupService>(
  (ref) => RepositoryGuestStartupService(
    sessions: ref.watch(guestSessionRepositoryProvider),
    profiles: ref.watch(guestProfileRepositoryProvider),
  ),
);

class RepositoryGuestStartupService implements GuestStartupService {
  const RepositoryGuestStartupService({
    required this.sessions,
    required this.profiles,
  });

  final GuestSessionRepository sessions;
  final GuestProfileRepository profiles;

  @override
  Future<void> ensureSession() async {
    await sessions.ensureSession();
  }

  @override
  Future<CustomerProfile?> getProfile() => profiles.getProfile();
}
