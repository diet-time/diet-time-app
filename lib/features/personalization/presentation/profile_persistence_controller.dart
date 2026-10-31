import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/domain/customer_onboarding.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';

class ProfilePersistenceState {
  const ProfilePersistenceState({
    this.isLoading = false,
    this.isSaving = false,
    this.hasLoaded = false,
    this.errorMessage,
    this.resumeStep = 0,
    this.requiresLogin = false,
    this.persistedProfile,
  });

  final bool isLoading;
  final bool isSaving;
  final bool hasLoaded;
  final String? errorMessage;
  final int resumeStep;
  final bool requiresLogin;
  final CustomerProfile? persistedProfile;

  ProfilePersistenceState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? hasLoaded,
    Object? errorMessage = _unset,
    int? resumeStep,
    bool? requiresLogin,
    Object? persistedProfile = _unset,
  }) {
    return ProfilePersistenceState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      resumeStep: resumeStep ?? this.resumeStep,
      requiresLogin: requiresLogin ?? this.requiresLogin,
      persistedProfile: identical(persistedProfile, _unset)
          ? this.persistedProfile
          : persistedProfile as CustomerProfile?,
    );
  }
}

const _unset = Object();

final profilePersistenceControllerProvider =
    NotifierProvider<ProfilePersistenceController, ProfilePersistenceState>(
      ProfilePersistenceController.new,
    );

class ProfilePersistenceController extends Notifier<ProfilePersistenceState> {
  Future<CustomerProfile?>? _pendingLoad;
  int _generation = 0;
  @override
  ProfilePersistenceState build() {
    _generation++;
    _pendingLoad = null;
    ref.onDispose(() => _generation++);
    return const ProfilePersistenceState();
  }

  void restore(CustomerProfile profile) {
    _generation++;
    _pendingLoad = null;
    ref.read(personalizationControllerProvider.notifier).replace(profile);
    state = state.copyWith(
      isLoading: false,
      hasLoaded: true,
      resumeStep: resumeStepFor(profile),
      errorMessage: null,
      requiresLogin: false,
      persistedProfile: profile.profileId == null ? null : profile,
    );
  }

  Future<CustomerProfile?> load() {
    if (_pendingLoad != null) return _pendingLoad!;
    final request = _load();
    _pendingLoad = request;
    return request.whenComplete(() {
      if (identical(_pendingLoad, request)) _pendingLoad = null;
    });
  }

  Future<CustomerProfile?> _load() async {
    final generation = _generation;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      requiresLogin: false,
    );
    try {
      final profile = await _withSessionRecovery(
        () => ref.read(customerProfileServiceProvider).load(),
      );
      if (!ref.mounted || generation != _generation) return null;
      ref
          .read(personalizationControllerProvider.notifier)
          .replace(profile ?? const CustomerProfile());
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        persistedProfile: profile,
        resumeStep: resumeStepFor(profile ?? const CustomerProfile()),
      );
      return profile;
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return null;
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: 'profile_load',
        requiresLogin:
            error is CustomerProfileException && error.statusCode == 401,
      );
      return null;
    }
  }

  Future<bool> save({required bool complete}) async {
    if (state.isSaving) return false;
    final generation = _generation;
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      requiresLogin: false,
    );
    try {
      final profile = ref.read(personalizationControllerProvider);
      final saved = await _withSessionRecovery(
        () async => complete
            ? await ref.read(customerProfileServiceProvider).complete(profile)
            : await ref
                  .read(customerProfileServiceProvider)
                  .saveProgress(profile),
      );
      if (!ref.mounted || generation != _generation) return false;
      ref.read(personalizationControllerProvider.notifier).replace(saved);
      if (complete && !saved.isCompleted) {
        throw const CustomerProfileException(statusCode: 422);
      }
      state = state.copyWith(
        isSaving: false,
        hasLoaded: true,
        resumeStep: resumeStepFor(saved),
        persistedProfile: saved,
      );
      return true;
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return false;
      state = state.copyWith(
        isSaving: false,
        requiresLogin:
            error is CustomerProfileException && error.statusCode == 401,
        errorMessage: error is CustomerProfileException
            ? error.message
            : 'Your answers are kept on this phone. Please retry saving.',
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  Future<T> _withSessionRecovery<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on CustomerProfileException catch (error) {
      if (error.statusCode != 401) rethrow;
      if (!await ref
          .read(otpAuthControllerProvider.notifier)
          .refreshAfterUnauthorized()) {
        rethrow;
      }
      return action();
    }
  }
}

int resumeStepFor(CustomerProfile profile) {
  return CustomerQuestionnaire.firstIncompletePage(profile);
}
