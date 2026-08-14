import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/storage/shared_preferences_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/checkout/presentation/checkout_controller.dart';
import 'package:diet_time/features/dashboard/data/customer_account_profile_repository.dart';
import 'package:diet_time/features/dashboard/domain/customer_account_profile.dart';
import 'package:diet_time/features/dashboard/presentation/customer_dashboard_controller.dart';
import 'package:diet_time/features/personalization/data/display_name_repository.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'package:diet_time/features/personalization/presentation/plan_selection_controller.dart';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerProfileState {
  const CustomerProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.hasLoaded = false,
    this.errorMessage,
    this.saveError,
    this.fieldErrors = const {},
    this.requiresLogin = false,
  });

  final CustomerAccountProfile? profile;
  final bool isLoading;
  final bool isSaving;
  final bool hasLoaded;
  final String? errorMessage;
  final String? saveError;
  final Map<String, String> fieldErrors;
  final bool requiresLogin;

  CustomerProfileState copyWith({
    Object? profile = _unset,
    bool? isLoading,
    bool? isSaving,
    bool? hasLoaded,
    Object? errorMessage = _unset,
    Object? saveError = _unset,
    Map<String, String>? fieldErrors,
    bool? requiresLogin,
  }) => CustomerProfileState(
    profile: identical(profile, _unset)
        ? this.profile
        : profile as CustomerAccountProfile?,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    hasLoaded: hasLoaded ?? this.hasLoaded,
    errorMessage: identical(errorMessage, _unset)
        ? this.errorMessage
        : errorMessage as String?,
    saveError: identical(saveError, _unset)
        ? this.saveError
        : saveError as String?,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    requiresLogin: requiresLogin ?? this.requiresLogin,
  );
}

const _unset = Object();

final customerProfileControllerProvider =
    NotifierProvider<CustomerProfileController, CustomerProfileState>(
      CustomerProfileController.new,
    );

class CustomerProfileController extends Notifier<CustomerProfileState> {
  @override
  CustomerProfileState build() => const CustomerProfileState();

  Future<void> load({bool force = false}) async {
    if (state.isLoading ||
        (!force && state.hasLoaded && state.profile != null)) {
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _withRefresh(
        () => ref.read(customerAccountProfileRepositoryProvider).getProfile(),
      );
      if (profile == null) return;
      _syncSharedProfile(profile);
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        hasLoaded: true,
        errorMessage: null,
      );
    } on Object {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: 'Unable to load your profile.',
      );
    }
  }

  Future<bool> save(UpdateCustomerProfileRequest request) async {
    if (state.isSaving) return false;
    state = state.copyWith(
      isSaving: true,
      saveError: null,
      fieldErrors: const {},
    );
    try {
      final saved = await _withRefresh(
        () => ref
            .read(customerAccountProfileRepositoryProvider)
            .updateProfile(request),
      );
      if (saved == null) return false;
      _syncSharedProfile(saved);
      state = state.copyWith(profile: saved, isSaving: false);
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(
        isSaving: false,
        saveError: error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Unable to update profile. Please try again.',
        fieldErrors: _fieldErrors(error),
      );
      return false;
    } on Object {
      state = state.copyWith(
        isSaving: false,
        saveError: 'Unable to update profile. Please try again.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(otpAuthControllerProvider.notifier).signOut();
    final preferences = ref.read(sharedPreferencesServiceProvider);
    await Future.wait([
      preferences.remove(DisplayNameRepository.displayNameKey),
      preferences.remove(DisplayNameRepository.capturedKey),
    ]);
    ref.read(personalizationControllerProvider.notifier).clear();
    ref.read(checkoutControllerProvider.notifier).clear();
    ref.read(customerDashboardControllerProvider.notifier).clear();
    ref.invalidate(planSelectionControllerProvider);
    ref.invalidate(profilePersistenceControllerProvider);
    state = const CustomerProfileState(requiresLogin: true);
  }

  Future<T?> _withRefresh<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on ApiException catch (error) {
      if (error.failure != ApiFailure.unauthorized) rethrow;
      final refreshed = await ref
          .read(otpAuthControllerProvider.notifier)
          .refreshAfterUnauthorized();
      if (refreshed) return operation();
      state = state.copyWith(
        requiresLogin: true,
        isLoading: false,
        isSaving: false,
      );
      return null;
    }
  }

  void _syncSharedProfile(CustomerAccountProfile profile) {
    final current = ref.read(personalizationControllerProvider);
    ref
        .read(personalizationControllerProvider.notifier)
        .replace(
          current.copyWith(
            profileId: profile.id.isEmpty ? current.profileId : profile.id,
            preferredName: profile.fullName,
            dateOfBirth: profile.dateOfBirth == null
                ? current.dateOfBirth
                : _apiDate(profile.dateOfBirth!),
            genderCode: profile.gender ?? current.genderCode,
          ),
        );
  }

  Map<String, String> _fieldErrors(ApiException error) {
    if (error.fieldErrors.isNotEmpty) {
      final mapped = <String, String>{};
      for (final entry in error.fieldErrors.entries) {
        final field = entry.key.toLowerCase();
        if (field.contains('name')) mapped['fullName'] = entry.value;
        if (field.contains('birth') || field == 'dob') {
          mapped['dateOfBirth'] = entry.value;
        }
        if (field.contains('gender')) mapped['gender'] = entry.value;
      }
      if (mapped.isNotEmpty) return mapped;
    }
    final message = error.message?.trim();
    if (message == null || message.isEmpty) return const {};
    final lower = message.toLowerCase();
    if (lower.contains('name')) return {'fullName': message};
    if (lower.contains('birth') || lower.contains('date')) {
      return {'dateOfBirth': message};
    }
    if (lower.contains('gender')) return {'gender': message};
    return const {};
  }
}

String _apiDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
