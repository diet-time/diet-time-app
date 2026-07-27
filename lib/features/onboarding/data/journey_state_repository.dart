import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final journeyStateRepositoryProvider = Provider<JourneyStateRepository>(
  (ref) => const JourneyStateRepository(),
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
  const JourneyStateRepository();

  static const _onboardingKey = 'hasCompletedOnboarding';
  static const _personalizationKey = 'hasCompletedPersonalization';
  static const _profileKey = 'hasCompletedProfile';

  Future<JourneyState> load() async {
    final preferences = await SharedPreferences.getInstance();
    return JourneyState(
      hasCompletedOnboarding: preferences.getBool(_onboardingKey) ?? false,
      hasCompletedPersonalization:
          preferences.getBool(_personalizationKey) ?? false,
      hasCompletedProfile: preferences.getBool(_profileKey) ?? false,
    );
  }

  Future<void> markOnboardingComplete() => _set(_onboardingKey, true);

  Future<void> markPersonalizationComplete() => _set(_personalizationKey, true);

  Future<void> markProfileComplete() => _set(_profileKey, true);

  Future<void> _set(String key, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }
}
