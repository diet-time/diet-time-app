import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderingAuth extends OtpAuthController {
  @override
  OtpAuthState build() => const OtpAuthState(isAuthenticated: true);
}

class GuestOrderingAuth extends OtpAuthController {
  @override
  OtpAuthState build() => const OtpAuthState();
}

void prepareOrderingCustomer(ProviderContainer container) {
  container
      .read(profilePersistenceControllerProvider.notifier)
      .restore(
        const CustomerProfile(
          preferredName: 'Noor',
          profileId: 'profile-id',
          genderCode: 'FEMALE',
          dateOfBirth: '1995-03-17',
          heightCm: 165,
          weightKg: 70,
          goalCode: 'LOSE_WEIGHT',
          dailyRoutineCode: 'OFFICE_WORK',
          activityLevelCode: 'MOSTLY_SITTING',
          preferencesConfirmed: true,
          allergensConfirmed: true,
          onboardingStatus: 'COMPLETED',
          nextStepCode: 'PROFILE_COMPLETED',
          shouldShowOnboarding: false,
        ),
      );
}
