import 'package:diet_time/features/personalization/data/guest_startup_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/domain/onboarding_route_resolver.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GuestStartupPhase {
  initial,
  startingSession,
  loadingProfile,
  profileLoaded,
  networkError,
}

class GuestStartupState {
  const GuestStartupState({
    this.phase = GuestStartupPhase.initial,
    this.destination,
  });

  final GuestStartupPhase phase;
  final String? destination;

  bool get isLoading =>
      phase == GuestStartupPhase.startingSession ||
      phase == GuestStartupPhase.loadingProfile;
}

final guestStartupControllerProvider =
    NotifierProvider<GuestStartupController, GuestStartupState>(
      GuestStartupController.new,
    );

class GuestStartupController extends Notifier<GuestStartupState> {
  bool _resolving = false;

  @override
  GuestStartupState build() => const GuestStartupState();

  Future<String?> resolve({required String languageCode}) async {
    if (_resolving) return state.destination;
    _resolving = true;
    try {
      state = const GuestStartupState(phase: GuestStartupPhase.startingSession);
      await ref.read(guestStartupServiceProvider).ensureSession();
      state = const GuestStartupState(phase: GuestStartupPhase.loadingProfile);
      final profile = await ref.read(guestStartupServiceProvider).getProfile();
      final resolvedProfile =
          profile ??
          CustomerProfile(
            preferredLanguage: languageCode,
            nextStepCode: OnboardingStepCode.basicDetails,
          );
      ref
          .read(profilePersistenceControllerProvider.notifier)
          .restore(resolvedProfile, authenticated: false);
      final destination = OnboardingRouteResolver.routeFor(
        stepCode: resolvedProfile.nextStepCode,
        shouldShowOnboarding: resolvedProfile.shouldShowOnboarding,
      );
      state = GuestStartupState(
        phase: GuestStartupPhase.profileLoaded,
        destination: destination,
      );
      return destination;
    } on Object {
      state = const GuestStartupState(phase: GuestStartupPhase.networkError);
      return null;
    } finally {
      _resolving = false;
    }
  }
}
