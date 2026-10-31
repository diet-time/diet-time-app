import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/domain/onboarding_route_resolver.dart';
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
  });

  final bool isLoading;
  final bool isSaving;
  final bool hasLoaded;
  final String? errorMessage;
  final int resumeStep;
  final bool requiresLogin;

  ProfilePersistenceState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? hasLoaded,
    Object? errorMessage = _unset,
    int? resumeStep,
    bool? requiresLogin,
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
  @override
  ProfilePersistenceState build() => const ProfilePersistenceState();

  void restore(CustomerProfile profile) {
    ref.read(personalizationControllerProvider.notifier).replace(profile);
    state = state.copyWith(
      isLoading: false,
      hasLoaded: true,
      resumeStep: resumeStepFor(profile),
      errorMessage: null,
      requiresLogin: false,
    );
  }

  Future<CustomerProfile?> load() =>
      _pendingLoad ??= _load().whenComplete(() => _pendingLoad = null);

  Future<CustomerProfile?> _load() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      requiresLogin: false,
    );
    try {
      final profile = await _withSessionRecovery(
        () => ref.read(customerProfileServiceProvider).load(),
      );
      if (!ref.mounted) return null;
      ref
          .read(personalizationControllerProvider.notifier)
          .replace(profile ?? const CustomerProfile());
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        resumeStep: profile == null
            ? OnboardingRouteResolver.pageFor(OnboardingStepCode.basicDetails)
            : resumeStepFor(profile),
      );
      return profile;
    } on Object catch (error) {
      if (!ref.mounted) return null;
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
      if (!ref.mounted) return false;
      ref.read(personalizationControllerProvider.notifier).replace(saved);
      if (complete && !saved.isCompleted) {
        throw const CustomerProfileException(statusCode: 422);
      }
      state = state.copyWith(
        isSaving: false,
        hasLoaded: true,
        resumeStep: resumeStepFor(saved),
      );
      return true;
    } on Object catch (error) {
      if (!ref.mounted) return false;
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
  return OnboardingRouteResolver.pageFor(profile.nextStepCode);
}
