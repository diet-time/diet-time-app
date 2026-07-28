import 'package:flutter_riverpod/flutter_riverpod.dart';

final journeyStateRepositoryProvider = Provider<JourneyStateRepository>(
  (ref) => JourneyStateRepository(),
);

class JourneyState {
  const JourneyState({
    required this.hasCompletedOnboarding,
    required this.hasCompletedPersonalization,
    required this.hasCompletedProfile,
  });

  final bool hasCompletedOnboarding;
  final bool hasCompletedPersonalization;
  final bool hasCompletedProfile;
}

class JourneyStateRepository {
  JourneyState _state = const JourneyState(
    hasCompletedOnboarding: false,
    hasCompletedPersonalization: false,
    hasCompletedProfile: false,
  );

  Future<JourneyState> load() async => _state;

  Future<void> markOnboardingComplete() async {
    _state = JourneyState(
      hasCompletedOnboarding: true,
      hasCompletedPersonalization: _state.hasCompletedPersonalization,
      hasCompletedProfile: _state.hasCompletedProfile,
    );
  }

  Future<void> markPersonalizationComplete() async {
    _state = JourneyState(
      hasCompletedOnboarding: _state.hasCompletedOnboarding,
      hasCompletedPersonalization: true,
      hasCompletedProfile: _state.hasCompletedProfile,
    );
  }

  Future<void> markProfileComplete() async {
    _state = JourneyState(
      hasCompletedOnboarding: _state.hasCompletedOnboarding,
      hasCompletedPersonalization: _state.hasCompletedPersonalization,
      hasCompletedProfile: true,
    );
  }
}
