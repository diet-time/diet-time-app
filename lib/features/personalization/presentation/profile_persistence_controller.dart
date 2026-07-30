import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePersistenceState {
  const ProfilePersistenceState({
    this.isLoading = false,
    this.isSaving = false,
    this.hasLoaded = false,
    this.errorMessage,
    this.resumeStep = 0,
    this.authenticated = false,
  });

  final bool isLoading;
  final bool isSaving;
  final bool hasLoaded;
  final String? errorMessage;
  final int resumeStep;
  final bool authenticated;

  ProfilePersistenceState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? hasLoaded,
    Object? errorMessage = _unset,
    int? resumeStep,
    bool? authenticated,
  }) {
    return ProfilePersistenceState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      resumeStep: resumeStep ?? this.resumeStep,
      authenticated: authenticated ?? this.authenticated,
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

  Future<CustomerProfile?> load({required bool authenticated}) async {
    if (state.isLoading) return null;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await ref
          .read(customerProfileServiceProvider)
          .load(authenticated: authenticated);
      if (profile != null) {
        ref.read(personalizationControllerProvider.notifier).replace(profile);
      }
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        resumeStep: profile == null ? 0 : resumeStepFor(profile),
        authenticated: authenticated,
      );
      return profile;
    } on Object {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: 'Unable to load your saved profile.',
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
          ? await ref
                .read(customerProfileServiceProvider)
                .complete(profile, authenticated: state.authenticated)
          : await ref
                .read(customerProfileServiceProvider)
                .saveProgress(profile, authenticated: state.authenticated);
      ref.read(personalizationControllerProvider.notifier).replace(saved);
      state = state.copyWith(isSaving: false);
      return true;
    } on Object {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Could not save your progress. Check your connection.',
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

int resumeStepFor(CustomerProfile profile) {
  if (profile.isCompleted) return 9;
  if (profile.goalCode == null) return 1;
  if (profile.dailyRoutineCode == null) return 3;
  if (profile.activityLevelCode == null) return 4;
  if (!profile.preferencesConfirmed) return 5;
  if (!profile.allergensConfirmed) return 6;
  return 7;
}
