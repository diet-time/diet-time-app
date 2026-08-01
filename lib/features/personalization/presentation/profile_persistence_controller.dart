import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/domain/onboarding_route_resolver.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePersistenceState {
  const ProfilePersistenceState({
    this.isLoading = false,
    this.isSaving = false,
    this.hasLoaded = false,
    this.errorMessage,
    this.resumeStep = 0,
  });

  final bool isLoading;
  final bool isSaving;
  final bool hasLoaded;
  final String? errorMessage;
  final int resumeStep;

  ProfilePersistenceState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? hasLoaded,
    Object? errorMessage = _unset,
    int? resumeStep,
  }) {
    return ProfilePersistenceState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      resumeStep: resumeStep ?? this.resumeStep,
    );
  }
}

const _unset = Object();

final profilePersistenceControllerProvider =
    NotifierProvider<ProfilePersistenceController, ProfilePersistenceState>(
      ProfilePersistenceController.new,
    );

class ProfilePersistenceController extends Notifier<ProfilePersistenceState> {
  @override
  ProfilePersistenceState build() => const ProfilePersistenceState();

  void restore(CustomerProfile profile) {
    ref.read(personalizationControllerProvider.notifier).replace(profile);
    state = state.copyWith(
      isLoading: false,
      hasLoaded: true,
      resumeStep: resumeStepFor(profile),
      errorMessage: null,
    );
  }

  Future<CustomerProfile?> load() async {
    if (state.isLoading) return null;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await ref.read(customerProfileServiceProvider).load();
      if (profile != null) {
        ref.read(personalizationControllerProvider.notifier).replace(profile);
      }
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        resumeStep: profile == null
            ? OnboardingRouteResolver.pageFor(OnboardingStepCode.basicDetails)
            : resumeStepFor(profile),
      );
      return profile;
    } on Object {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: 'profile_load',
      );
      return null;
    }
  }

  Future<bool> save({required bool complete}) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final profile = ref.read(personalizationControllerProvider);
      final saved = complete
          ? await ref.read(customerProfileServiceProvider).complete(profile)
          : await ref
                .read(customerProfileServiceProvider)
                .saveProgress(profile);
      ref.read(personalizationControllerProvider.notifier).replace(saved);
      state = state.copyWith(isSaving: false, resumeStep: resumeStepFor(saved));
      return true;
    } on Object catch (error) {
      if (error is ApiException && error.failure == ApiFailure.conflict) {
        final latest = await ref.read(customerProfileServiceProvider).load();
        if (latest != null) {
          ref.read(personalizationControllerProvider.notifier).replace(latest);
        }
        state = state.copyWith(
          isSaving: false,
          resumeStep: latest == null ? state.resumeStep : resumeStepFor(latest),
          errorMessage: 'profile_conflict',
        );
        return false;
      }
      state = state.copyWith(isSaving: false, errorMessage: 'profile_save');
      return false;
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

int resumeStepFor(CustomerProfile profile) {
  return OnboardingRouteResolver.pageFor(profile.nextStepCode);
}
