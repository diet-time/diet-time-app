import 'dart:async';

import 'package:diet_time/features/authentication/data/mock_authentication_service.dart';
import 'package:diet_time/features/authentication/data/mock_otp_service.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OtpUiError {
  requestFailed,
  incorrectCode,
  expiredCode,
  tooManyAttempts,
  resendUnavailable,
}

class OtpAuthState {
  const OtpAuthState({
    this.isAuthenticated = false,
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
    this.pendingDestination,
    this.resendConfirmation = false,
  });

  final bool isAuthenticated;
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
  final PendingAuthDestination? pendingDestination;
  final bool resendConfirmation;

  OtpAuthState copyWith({
    bool? isAuthenticated,
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
    Object? pendingDestination = _unset,
    bool? resendConfirmation,
  }) {
    return OtpAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
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
  DateTime? _expiresAt;

  @override
  OtpAuthState build() {
    ref.onDispose(() => _resendTimer?.cancel());
    unawaited(_restoreSession());
    return const OtpAuthState();
  }

  Future<void> _restoreSession() async {
    try {
      final authenticated = await ref
          .read(authenticationServiceProvider)
          .isLoggedIn();
      if (authenticated) {
        state = state.copyWith(isAuthenticated: true);
      }
    } catch (_) {
      // A missing platform storage implementation must not block guest use.
    }
  }

  void begin(PendingAuthDestination destination) {
    state = state.copyWith(
      pendingDestination: destination,
      requestError: null,
      verificationError: null,
      resendConfirmation: false,
    );
  }

  void setPhoneNumber(String phoneNumber) {
    state = state.copyWith(
      phoneNumber: phoneNumber,
      requestError: null,
      verificationError: null,
    );
  }

  void setOtpCode(String code) {
    state = state.copyWith(otpCode: code, verificationError: null);
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
      _expiresAt = DateTime.now().add(
        Duration(seconds: result.expiresInSeconds),
      );
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
    if (_expiresAt != null && DateTime.now().isAfter(_expiresAt!)) {
      state = state.copyWith(verificationError: OtpUiError.expiredCode);
      return false;
    }
    state = state.copyWith(isVerifyingOtp: true, verificationError: null);
    try {
      final result = await ref
          .read(otpServiceProvider)
          .verifyOtp(phoneNumber: state.phoneNumber, code: state.otpCode);
      if (!result.success) {
        state = state.copyWith(
          isVerifyingOtp: false,
          verificationError: _verificationError(result.failure),
        );
        return false;
      }
      try {
        await ref.read(authenticationServiceProvider).markAuthenticated();
      } catch (_) {
        // The in-memory development session remains valid.
      }
      _resendTimer?.cancel();
      state = state.copyWith(
        isAuthenticated: true,
        otpCode: '',
        isVerifyingOtp: false,
        verificationError: null,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isVerifyingOtp: false,
        verificationError: OtpUiError.incorrectCode,
      );
      return false;
    }
  }

  Future<bool> resendOtp() async {
    if (state.resendSecondsRemaining > 0 || state.isRequestingOtp) return false;
    setOtpCode('');
    return requestOtp(channel: state.otpChannel, showConfirmation: true);
  }

  void clearOtpForBackNavigation() {
    state = state.copyWith(otpCode: '', verificationError: null);
  }

  void cancel() {
    _resendTimer?.cancel();
    _expiresAt = null;
    state = OtpAuthState(isAuthenticated: state.isAuthenticated);
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

  OtpUiError _verificationError(OtpFailure? failure) {
    return switch (failure) {
      OtpFailure.expired => OtpUiError.expiredCode,
      OtpFailure.tooManyAttempts => OtpUiError.tooManyAttempts,
      _ => OtpUiError.incorrectCode,
    };
  }
}
