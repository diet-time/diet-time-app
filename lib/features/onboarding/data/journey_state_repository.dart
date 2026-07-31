import 'package:diet_time/core/storage/shared_preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final journeyStateRepositoryProvider = Provider<JourneyStateRepository>(
  (ref) => JourneyStateRepository(ref.watch(sharedPreferencesServiceProvider)),
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
  JourneyStateRepository(this._preferences);

  static const _onboardingKey = 'hasCompletedOnboarding';
  static const _personalizationKey = 'hasCompletedPersonalization';
  static const _profileKey = 'hasCompletedProfile';

  final SharedPreferencesService _preferences;

  Future<JourneyState> load() async => JourneyState(
    hasCompletedOnboarding:
        await _preferences.getBool(_onboardingKey) ?? false,
    hasCompletedPersonalization:
        await _preferences.getBool(_personalizationKey) ?? false,
    hasCompletedProfile: await _preferences.getBool(_profileKey) ?? false,
  );

  Future<void> markOnboardingComplete() async {
    await _preferences.setBool(_onboardingKey, true);
  }

  Future<void> markPersonalizationComplete() async {
    await _preferences.setBool(_personalizationKey, true);
  }

  Future<void> markProfileComplete() async {
    await _preferences.setBool(_profileKey, true);
  }
}
