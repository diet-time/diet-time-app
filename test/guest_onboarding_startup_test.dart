import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/features/personalization/data/guest_startup_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/domain/onboarding_route_resolver.dart';
import 'package:diet_time/features/personalization/presentation/guest_startup_controller.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'startup ensures a session and treats no profile as BASIC_DETAILS',
    () async {
      final service = _FakeStartupService();
      final container = ProviderContainer(
        overrides: [guestStartupServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      final destination = await container
          .read(guestStartupControllerProvider.notifier)
          .resolve(languageCode: 'en');

      expect(service.ensureCalls, 1);
      expect(service.profileCalls, 1);
      expect(destination, AppRoutes.personalization);
      expect(
        container.read(personalizationControllerProvider).nextStepCode,
        OnboardingStepCode.basicDetails,
      );
      expect(
        container.read(profilePersistenceControllerProvider).resumeStep,
        2,
      );
    },
  );

  for (final entry in const {
    'BODY_MEASUREMENTS': 2,
    'GOAL': 1,
    'DAILY_ROUTINE': 3,
    'ACTIVITY_LEVEL': 4,
    'ALLERGENS': 6,
    'PREFERENCES': 5,
  }.entries) {
    test('startup restores ${entry.key}', () async {
      final service = _FakeStartupService(
        profile: CustomerProfile(
          genderCode: 'FEMALE',
          dateOfBirth: '1998-01-01',
          heightCm: 170,
          weightKg: 70,
          nextStepCode: entry.key,
          completionPercentage: 43,
        ),
      );
      final container = ProviderContainer(
        overrides: [guestStartupServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      expect(
        await container
            .read(guestStartupControllerProvider.notifier)
            .resolve(languageCode: 'en'),
        AppRoutes.personalization,
      );
      expect(
        container.read(profilePersistenceControllerProvider).resumeStep,
        entry.value,
      );
      expect(container.read(personalizationControllerProvider).heightCm, 170);
      expect(
        container.read(personalizationControllerProvider).completionPercentage,
        43,
      );
    });
  }

  test('completed server profile skips onboarding', () async {
    final service = _FakeStartupService(
      profile: const CustomerProfile(
        onboardingStatus: 'PROFILE_COMPLETED',
        nextStepCode: 'PROFILE_COMPLETED',
        completionPercentage: 100,
        shouldShowOnboarding: false,
      ),
    );
    final container = ProviderContainer(
      overrides: [guestStartupServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    expect(
      await container
          .read(guestStartupControllerProvider.notifier)
          .resolve(languageCode: 'en'),
      AppRoutes.menu,
    );
  });

  test(
    'network failure exposes retry state without replacing local draft',
    () async {
      final service = _FakeStartupService(failProfile: true);
      final container = ProviderContainer(
        overrides: [guestStartupServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      container
          .read(personalizationControllerProvider.notifier)
          .setGoal('GAIN_WEIGHT');

      expect(
        await container
            .read(guestStartupControllerProvider.notifier)
            .resolve(languageCode: 'en'),
        isNull,
      );
      expect(
        container.read(guestStartupControllerProvider).phase,
        GuestStartupPhase.networkError,
      );
      expect(
        container.read(personalizationControllerProvider).goalCode,
        'GAIN_WEIGHT',
      );
    },
  );
}

class _FakeStartupService implements GuestStartupService {
  _FakeStartupService({this.profile, this.failProfile = false});

  final CustomerProfile? profile;
  final bool failProfile;
  int ensureCalls = 0;
  int profileCalls = 0;

  @override
  Future<void> ensureSession() async {
    ensureCalls++;
  }

  @override
  Future<CustomerProfile?> getProfile() async {
    profileCalls++;
    if (failProfile) throw Exception('offline');
    return profile;
  }
}
