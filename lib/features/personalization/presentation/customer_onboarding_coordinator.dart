import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/personalization/data/customer_profile_repository.dart';
import 'package:diet_time/features/personalization/data/display_name_repository.dart';
import 'package:diet_time/features/personalization/domain/customer_onboarding.dart';
import 'package:diet_time/features/personalization/domain/customer_profile.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerOnboardingState {
  const CustomerOnboardingState({
    this.phase = CustomerOnboardingPhase.unauthenticated,
    this.intent = CustomerJourneyIntent.normalLogin,
    this.profile,
    this.isSaving = false,
  });
  final CustomerOnboardingPhase phase;
  final CustomerJourneyIntent intent;
  final CustomerProfile? profile;
  final bool isSaving;
  int get questionnairePage => CustomerQuestionnaire.firstIncompletePage(
    profile ?? const CustomerProfile(),
  );
}

final customerOnboardingCoordinatorProvider =
    NotifierProvider<CustomerOnboardingCoordinator, CustomerOnboardingState>(
      CustomerOnboardingCoordinator.new,
    );

/// Readiness used by route guards and order entry. Local edits cannot grant access.
final customerOnboardingReadyProvider = Provider<bool>((ref) {
  final persisted = ref.watch(profilePersistenceControllerProvider);
  return ref.watch(otpAuthControllerProvider).isAuthenticated &&
      persisted.hasLoaded &&
      persisted.errorMessage == null &&
      CustomerOnboardingPolicy.ready(persisted.persistedProfile);
});

class CustomerOnboardingCoordinator extends Notifier<CustomerOnboardingState> {
  Future<CustomerOnboardingState>? _checking;
  int _generation = 0;
  bool _saving = false;

  @override
  CustomerOnboardingState build() {
    ref.onDispose(() => _generation++);
    ref.listen(
      otpAuthControllerProvider.select(
        (auth) => (auth.isAuthenticated, auth.user?.id, auth.sessionExpired),
      ),
      (previous, next) {
        if (previous == null) return;
        if ((previous.$1 && !next.$1) ||
            (previous.$1 && next.$1 && previous.$2 != next.$2)) {
          _generation++;
          _checking = null;
          _saving = false;
          state = CustomerOnboardingState(
            intent: next.$3 ? state.intent : CustomerJourneyIntent.normalLogin,
          );
        }
      },
    );
    return const CustomerOnboardingState();
  }

  void begin(CustomerJourneyIntent intent) => state = CustomerOnboardingState(
    phase: state.phase,
    profile: state.profile,
    intent: intent,
    isSaving: state.isSaving,
  );

  CustomerOnboardingState _set(
    CustomerOnboardingPhase phase, {
    CustomerProfile? profile,
    bool saving = false,
  }) {
    state = CustomerOnboardingState(
      phase: phase,
      profile: profile,
      intent: state.intent,
      isSaving: saving,
    );
    return state;
  }

  Future<CustomerOnboardingState> check({bool refresh = false}) {
    if (_checking != null) return _checking!;
    final request = _check(refresh: refresh);
    _checking = request;
    return request.whenComplete(() {
      if (identical(_checking, request)) _checking = null;
    });
  }

  Future<CustomerOnboardingState> _check({required bool refresh}) async {
    final generation = _generation;
    _set(CustomerOnboardingPhase.loadingProfile, profile: state.profile);
    try {
      final authenticated = await ref
          .read(otpAuthControllerProvider.notifier)
          .restoreSession();
      if (!ref.mounted) return const CustomerOnboardingState();
      if (generation != _generation) return state;
      if (!authenticated) return _set(CustomerOnboardingPhase.unauthenticated);
      var persisted = ref.read(profilePersistenceControllerProvider);
      if (refresh || !persisted.hasLoaded || persisted.errorMessage != null) {
        await ref.read(profilePersistenceControllerProvider.notifier).load();
      }
      if (!ref.mounted) return const CustomerOnboardingState();
      if (generation != _generation) return state;
      persisted = ref.read(profilePersistenceControllerProvider);
      if (persisted.requiresLogin ||
          !ref.read(otpAuthControllerProvider).isAuthenticated) {
        return _set(CustomerOnboardingPhase.unauthenticated);
      }
      if (persisted.errorMessage != null || !persisted.hasLoaded) {
        return _set(CustomerOnboardingPhase.recoverableError);
      }
      return _set(
        CustomerOnboardingPolicy.phase(persisted.persistedProfile),
        profile: persisted.persistedProfile,
      );
    } on Object {
      if (!ref.mounted) return const CustomerOnboardingState();
      if (generation != _generation) return state;
      return _set(CustomerOnboardingPhase.recoverableError);
    }
  }

  Future<bool> saveName(String name) async {
    if (_saving || !CustomerOnboardingPolicy.validName(name)) return false;
    _saving = true;
    final generation = _generation;
    _set(state.phase, profile: state.profile, saving: true);
    try {
      Future<CustomerProfile> save() => ref
          .read(displayNameRepositoryProvider)
          .saveAuthenticatedProfileName(name);
      CustomerProfile saved;
      try {
        saved = await save();
      } on CustomerProfileException catch (error) {
        if (error.statusCode != 401 ||
            !await ref
                .read(otpAuthControllerProvider.notifier)
                .refreshAfterUnauthorized()) {
          rethrow;
        }
        saved = await save();
      }
      if (!ref.mounted || generation != _generation) return false;
      ref.read(profilePersistenceControllerProvider.notifier).restore(saved);
      _set(CustomerOnboardingPolicy.phase(saved), profile: saved);
      return true;
    } on Object {
      if (ref.mounted && generation == _generation) {
        _set(
          ref.read(otpAuthControllerProvider).isAuthenticated
              ? CustomerOnboardingPolicy.phase(state.profile)
              : CustomerOnboardingPhase.unauthenticated,
          profile: state.profile,
        );
      }
      return false;
    } finally {
      if (generation == _generation) _saving = false;
    }
  }

  Future<bool> saveQuestionnaire({required bool complete}) async {
    if (_saving) return false;
    _saving = true;
    final generation = _generation;
    try {
      final saved = await ref
          .read(profilePersistenceControllerProvider.notifier)
          .save(complete: complete);
      if (!ref.mounted || generation != _generation) return false;
      if (saved) await check();
      return saved;
    } finally {
      if (generation == _generation) _saving = false;
    }
  }

  CustomerJourneyIntent consumeIntent() {
    if (state.phase != CustomerOnboardingPhase.ready) {
      throw StateError('Onboarding is not ready');
    }
    final intent = state.intent;
    begin(CustomerJourneyIntent.normalLogin);
    ref.read(otpAuthControllerProvider.notifier).clearPendingDestination();
    return intent;
  }
}
