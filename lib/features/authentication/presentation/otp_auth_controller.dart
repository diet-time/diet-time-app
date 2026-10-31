import 'dart:async';
import 'package:diet_time/features/personalization/presentation/profile_persistence_controller.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';

import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/features/authentication/data/authentication_repository.dart';
import 'package:diet_time/features/authentication/data/mock_authentication_service.dart';
import 'package:diet_time/features/authentication/data/otp_service_provider.dart';
import 'package:diet_time/features/authentication/domain/auth_models.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diet_time/features/personalization/presentation/questionnaire_deferral_controller.dart';

enum OtpUiError {
  requestFailed,
  incorrectCode,
  validation,
  accountConflict,
  tooManyAttempts,
  unavailable,
  connection,
  server,
  resendUnavailable,
}

class OtpAuthState {
  const OtpAuthState({
    this.isAuthenticated = false,
    this.sessionExpired = false,
    this.phoneNumber = '',
    this.otpCode = '',
    this.otpChannel = OtpChannel.sms,
    this.requestId,
    this.expiresInSeconds = 0,
    this.resendSecondsRemaining = 0,
    this.isRequestingOtp = false,
    this.isVerifyingOtp = false,
    this.requestError,
    this.verificationError,
    this.verificationMessage,
    this.session,
    this.pendingDestination,
    this.resendConfirmation = false,
  });

  final bool isAuthenticated;
  final bool sessionExpired;
  final String phoneNumber;
  final String otpCode;
  final OtpChannel otpChannel;
  final String? requestId;
  final int expiresInSeconds;
  final int resendSecondsRemaining;
  final bool isRequestingOtp;
  final bool isVerifyingOtp;
  final OtpUiError? requestError;
  final OtpUiError? verificationError;
  final String? verificationMessage;
  final AuthSession? session;
  AuthUser? get user => session?.user;
  final PendingAuthDestination? pendingDestination;
  final bool resendConfirmation;

  OtpAuthState copyWith({
    bool? isAuthenticated,
    bool? sessionExpired,
    String? phoneNumber,
    String? otpCode,
    OtpChannel? otpChannel,
    Object? requestId = _unset,
    int? expiresInSeconds,
    int? resendSecondsRemaining,
    bool? isRequestingOtp,
    bool? isVerifyingOtp,
    Object? requestError = _unset,
    Object? verificationError = _unset,
    Object? verificationMessage = _unset,
    Object? session = _unset,
    Object? pendingDestination = _unset,
    bool? resendConfirmation,
  }) {
    return OtpAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      sessionExpired: sessionExpired ?? this.sessionExpired,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otpCode: otpCode ?? this.otpCode,
      otpChannel: otpChannel ?? this.otpChannel,
      requestId: identical(requestId, _unset)
          ? this.requestId
          : requestId as String?,
      expiresInSeconds: expiresInSeconds ?? this.expiresInSeconds,
      resendSecondsRemaining:
          resendSecondsRemaining ?? this.resendSecondsRemaining,
      isRequestingOtp: isRequestingOtp ?? this.isRequestingOtp,
      isVerifyingOtp: isVerifyingOtp ?? this.isVerifyingOtp,
      requestError: identical(requestError, _unset)
          ? this.requestError
          : requestError as OtpUiError?,
      verificationError: identical(verificationError, _unset)
          ? this.verificationError
          : verificationError as OtpUiError?,
      verificationMessage: identical(verificationMessage, _unset)
          ? this.verificationMessage
          : verificationMessage as String?,
      session: identical(session, _unset)
          ? this.session
          : session as AuthSession?,
      pendingDestination: identical(pendingDestination, _unset)
          ? this.pendingDestination
          : pendingDestination as PendingAuthDestination?,
      resendConfirmation: resendConfirmation ?? this.resendConfirmation,
    );
  }
}

const _unset = Object();

final otpAuthControllerProvider =
    NotifierProvider<OtpAuthController, OtpAuthState>(OtpAuthController.new);

class OtpAuthController extends Notifier<OtpAuthState> {
  Timer? _resendTimer;
  Future<bool>? _sessionRestore;
  int _sessionGeneration = 0;
  Future<void>? _credentialWrite;

  @override
  OtpAuthState build() {
    ref.onDispose(() => _resendTimer?.cancel());
    unawaited(Future<bool>.microtask(restoreSession));
    return const OtpAuthState();
  }

  Future<bool> restoreSession() {
    if (state.isAuthenticated) return Future.value(true);
    return _sessionRestore ??= _restoreSession().whenComplete(() {
      _sessionRestore = null;
    });
  }

  /// Recheck expiry even if this controller previously restored the session.
  Future<bool> ensureCurrentSession() async {
    final generation = _sessionGeneration;
    await _sessionRestore;
    final session = state.session;
    final valid =
        session != null &&
            !session.accessTokenExpiresAt.isAfter(DateTime.now().toUtc())
        ? await _refreshStoredSession(preserveSessionOnTransientFailure: false)
        : await _restoreSession();
    if (!ref.mounted || generation != _sessionGeneration) return false;
    state = state.copyWith(
      isAuthenticated: valid,
      session: valid ? state.session : null,
    );
    return valid;
  }

  Future<bool> _restoreSession() async {
    final generation = _sessionGeneration;
    try {
      final authenticated = await ref
          .read(authenticationServiceProvider)
          .isLoggedIn();
      if (!ref.mounted || generation != _sessionGeneration) return false;
      if (authenticated) {
        state = state.copyWith(isAuthenticated: true);
        return true;
      }
      return _refreshStoredSession();
    } catch (_) {
      // A missing platform storage implementation must not block guest use.
      return false;
    }
  }

  Future<bool> _refreshStoredSession({
    bool preserveSessionOnTransientFailure = true,
  }) async {
    final generation = _sessionGeneration;
    final storage = ref.read(secureStorageServiceProvider);
    final values = await Future.wait([
      storage.read(SecureStorageService.refreshTokenKey),
      storage.read(SecureStorageService.refreshTokenExpiresAtKey),
    ]);
    if (!ref.mounted || generation != _sessionGeneration) return false;
    final refreshToken = values[0]?.trim() ?? '';
    final refreshExpiresAt = DateTime.tryParse(values[1] ?? '');
    if (refreshToken.isEmpty ||
        refreshExpiresAt == null ||
        !refreshExpiresAt.isAfter(DateTime.now().toUtc())) {
      return false;
    }

    try {
      final repository = ref.read(authenticationRepositoryProvider);
      if (repository is! SessionRefreshRepository) return false;
      final refreshRepository = repository as SessionRefreshRepository;
      final refreshed = await refreshRepository.refreshSession(
        refreshToken: refreshToken,
        refreshTokenExpiresAt: refreshExpiresAt,
      );
      if (!await _persistSession(generation, () async {
        await Future.wait([
          storage.write(
            SecureStorageService.accessTokenKey,
            refreshed.accessToken,
          ),
          storage.write(
            SecureStorageService.accessTokenExpiresAtKey,
            refreshed.accessTokenExpiresAt.toIso8601String(),
          ),
          storage.write(
            SecureStorageService.refreshTokenKey,
            refreshed.refreshToken,
          ),
          storage.write(
            SecureStorageService.refreshTokenExpiresAtKey,
            refreshed.refreshTokenExpiresAt.toIso8601String(),
          ),
        ]);
        await ref.read(authenticationServiceProvider).markAuthenticated();
      })) {
        return false;
      }
      state = state.copyWith(isAuthenticated: true);
      return true;
    } on PhoneOtpException catch (error) {
      if (!ref.mounted || generation != _sessionGeneration) return false;
      if (error.failure == PhoneOtpFailure.invalidOtp ||
          error.failure == PhoneOtpFailure.invalidResponse ||
          !preserveSessionOnTransientFailure) {
        await _clearStoredSession(storage);
        return false;
      }
      // A valid, unexpired refresh token still represents a resumable session
      // when the network or API is temporarily unavailable.
      state = state.copyWith(isAuthenticated: true);
      return true;
    }
  }

  /// Retries the application's existing refresh-token flow after a protected
  /// endpoint returns 401. A failed refresh clears the resumable session.
  Future<bool> refreshAfterUnauthorized() async {
    final generation = _sessionGeneration;
    final refreshed = await _refreshStoredSession(
      preserveSessionOnTransientFailure: false,
    );
    if (!ref.mounted || generation != _sessionGeneration) return false;
    if (!refreshed) {
      await signOut(sessionExpired: true);
    }
    return refreshed;
  }

  Future<void> signOut({bool sessionExpired = false}) async {
    _sessionGeneration++;
    try {
      await _credentialWrite;
    } catch (_) {}
    ref.invalidate(questionnaireDeferralProvider);
    ref.invalidate(profilePersistenceControllerProvider);
    ref.invalidate(personalizationControllerProvider);
    _resendTimer?.cancel();
    final storage = ref.read(secureStorageServiceProvider);
    await Future.wait([
      _clearStoredSession(storage),
      storage.delete(SecureStorageService.temporaryCustomerPhoneKey),
      storage.delete(SecureStorageService.authenticatedUserIdKey),
    ]);
    final authentication = ref.read(authenticationServiceProvider);
    if (authentication is SignOutAuthenticationService) {
      await (authentication as SignOutAuthenticationService).signOut();
    }
    state = OtpAuthState(sessionExpired: sessionExpired);
  }

  Future<bool> _persistSession(
    int generation,
    Future<void> Function() write,
  ) async {
    if (!ref.mounted || generation != _sessionGeneration) return false;
    final previous = _credentialWrite;
    final pending = () async {
      try {
        await previous;
      } catch (_) {}
      if (!ref.mounted || generation != _sessionGeneration) return;
      await write();
    }();
    _credentialWrite = pending;
    await pending;
    return ref.mounted && generation == _sessionGeneration;
  }

  Future<void> _clearStoredSession(SecureStorageService storage) =>
      Future.wait([
        storage.delete(SecureStorageService.accessTokenKey),
        storage.delete(SecureStorageService.accessTokenExpiresAtKey),
        storage.delete(SecureStorageService.refreshTokenKey),
        storage.delete(SecureStorageService.refreshTokenExpiresAtKey),
      ]);

  void begin(PendingAuthDestination destination) {
    state = state.copyWith(
      pendingDestination: destination,
      requestError: null,
      verificationError: null,
      resendConfirmation: false,
    );
  }

  void clearPendingDestination() =>
      state = state.copyWith(pendingDestination: null);

  void setPhoneNumber(String phoneNumber) {
    state = state.copyWith(
      phoneNumber: phoneNumber,
      requestError: null,
      verificationError: null,
    );
  }

  void setOtpCode(String code) {
    state = state.copyWith(
      otpCode: code,
      verificationError: code.isEmpty ? state.verificationError : null,
      verificationMessage: code.isEmpty ? state.verificationMessage : null,
    );
  }

  Future<bool> requestOtp({
    OtpChannel channel = OtpChannel.sms,
    bool showConfirmation = false,
  }) async {
    if (state.isRequestingOtp || state.phoneNumber.isEmpty) return false;
    state = state.copyWith(
      isRequestingOtp: true,
      otpChannel: channel,
      requestError: null,
      verificationError: null,
      resendConfirmation: false,
    );
    if (!AppEnvironment.enableRequestOtpApi) {
      state = state.copyWith(
        isRequestingOtp: false,
        requestId: 'local-verification',
        expiresInSeconds: 0,
        resendSecondsRemaining: 0,
      );
      return true;
    }
    try {
      final result = await ref
          .read(otpServiceProvider)
          .requestOtp(phoneNumber: state.phoneNumber, channel: channel);
      if (!result.success) {
        state = state.copyWith(
          isRequestingOtp: false,
          requestError: _requestError(result.failure),
        );
        return false;
      }
      state = state.copyWith(
        isRequestingOtp: false,
        requestId: result.requestId,
        expiresInSeconds: result.expiresInSeconds,
        resendSecondsRemaining: 30,
        resendConfirmation: showConfirmation,
      );
      _startResendTimer();
      return true;
    } catch (_) {
      state = state.copyWith(
        isRequestingOtp: false,
        requestError: OtpUiError.requestFailed,
      );
      return false;
    }
  }

  Future<bool> verifyOtp() async {
    if (state.isVerifyingOtp || state.otpCode.length != 6) return false;
    final generation = ++_sessionGeneration;
    state = state.copyWith(
      isVerifyingOtp: true,
      verificationError: null,
      verificationMessage: null,
    );
    try {
      final session = await ref
          .read(authenticationRepositoryProvider)
          .verifyPhoneOtp(
            PhoneOtpLoginRequest(
              phoneNumber: state.phoneNumber,
              otp: state.otpCode,
            ),
          );
      final storage = ref.read(secureStorageServiceProvider);
      if (!await _persistSession(generation, () async {
        await Future.wait([
          storage.write(
            SecureStorageService.accessTokenKey,
            session.accessToken,
          ),
          storage.write(
            SecureStorageService.authenticatedUserIdKey,
            session.user.id,
          ),
          storage.write(
            SecureStorageService.accessTokenExpiresAtKey,
            session.accessTokenExpiresAt.toIso8601String(),
          ),
          storage.write(
            SecureStorageService.refreshTokenKey,
            session.refreshToken,
          ),
          storage.write(
            SecureStorageService.refreshTokenExpiresAtKey,
            session.refreshTokenExpiresAt.toIso8601String(),
          ),
        ]);
        try {
          await ref.read(authenticationServiceProvider).markAuthenticated();
        } catch (_) {
          // The in-memory development session remains valid.
        }
      })) {
        return false;
      }
      _resendTimer?.cancel();
      ref.invalidate(profilePersistenceControllerProvider);
      ref.invalidate(personalizationControllerProvider);
      state = state.copyWith(
        isAuthenticated: true,
        otpCode: '',
        isVerifyingOtp: false,
        verificationError: null,
        verificationMessage: null,
        session: session,
      );
      return true;
    } on PhoneOtpException catch (error) {
      if (!ref.mounted || generation != _sessionGeneration) return false;
      final uiError = _verificationError(error.failure);
      state = state.copyWith(
        isVerifyingOtp: false,
        otpCode: uiError == OtpUiError.incorrectCode ? '' : state.otpCode,
        verificationError: uiError,
        verificationMessage: error.failure == PhoneOtpFailure.validation
            ? error.message
            : null,
      );
      return false;
    } catch (_) {
      if (!ref.mounted || generation != _sessionGeneration) return false;
      state = state.copyWith(
        isVerifyingOtp: false,
        verificationError: OtpUiError.server,
      );
      return false;
    }
  }

  Future<bool> resendOtp() async {
    if (!AppEnvironment.enableRequestOtpApi) {
      state = state.copyWith(requestError: OtpUiError.resendUnavailable);
      return false;
    }
    if (state.resendSecondsRemaining > 0 || state.isRequestingOtp) return false;
    return requestOtp(channel: state.otpChannel, showConfirmation: true);
  }

  void clearOtpForBackNavigation() {
    _sessionGeneration++;
    state = state.copyWith(
      otpCode: '',
      verificationError: null,
      isVerifyingOtp: false,
    );
  }

  void cancel() {
    _sessionGeneration++;
    _resendTimer?.cancel();
    state = OtpAuthState(
      isAuthenticated: state.isAuthenticated,
      session: state.session,
      sessionExpired: state.sessionExpired,
    );
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.resendSecondsRemaining - 1;
      if (next <= 0) {
        timer.cancel();
        state = state.copyWith(resendSecondsRemaining: 0);
      } else {
        state = state.copyWith(resendSecondsRemaining: next);
      }
    });
  }

  OtpUiError _requestError(OtpFailure? failure) {
    return switch (failure) {
      OtpFailure.resendUnavailable => OtpUiError.resendUnavailable,
      OtpFailure.tooManyAttempts => OtpUiError.tooManyAttempts,
      _ => OtpUiError.requestFailed,
    };
  }

  OtpUiError _verificationError(PhoneOtpFailure failure) {
    return switch (failure) {
      PhoneOtpFailure.validation => OtpUiError.validation,
      PhoneOtpFailure.invalidOtp => OtpUiError.incorrectCode,
      PhoneOtpFailure.accountConflict => OtpUiError.accountConflict,
      PhoneOtpFailure.tooManyAttempts => OtpUiError.tooManyAttempts,
      PhoneOtpFailure.unavailable => OtpUiError.unavailable,
      PhoneOtpFailure.connection => OtpUiError.connection,
      PhoneOtpFailure.server ||
      PhoneOtpFailure.invalidResponse => OtpUiError.server,
    };
  }
}
