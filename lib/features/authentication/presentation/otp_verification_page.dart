import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/app/theme/app_spacing.dart';
import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/features/authentication/data/mock_otp_service.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/authentication/presentation/otp_flow_widgets.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _syncingCells = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((item) => item.text).join();

  void _onCellChanged(int index, String value) {
    if (_syncingCells) return;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      _setCells(digits.substring(0, digits.length > 6 ? 6 : digits.length));
      return;
    }
    if (digits != value) {
      _controllers[index].text = digits;
    }
    ref.read(otpAuthControllerProvider.notifier).setOtpCode(_code);
    if (digits.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    }
    setState(() {});
  }

  void _setCells(String code) {
    _syncingCells = true;
    for (var index = 0; index < 6; index++) {
      _controllers[index].text = index < code.length ? code[index] : '';
    }
    _syncingCells = false;
    ref.read(otpAuthControllerProvider.notifier).setOtpCode(_code);
    if (code.length == 6) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      _focusNodes[code.length > 5 ? 5 : code.length].requestFocus();
    }
    setState(() {});
  }

  KeyEventResult _handleKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      ref.read(otpAuthControllerProvider.notifier).setOtpCode(_code);
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _verify() async {
    final succeeded = await ref
        .read(otpAuthControllerProvider.notifier)
        .verifyOtp();
    if (!mounted || !succeeded) return;
    _setCells('');
    final destination = ref.read(otpAuthControllerProvider).pendingDestination;
    context.go(destination?.route ?? AppRoutes.plans);
  }

  Future<void> _resend() async {
    final succeeded = await ref
        .read(otpAuthControllerProvider.notifier)
        .resendOtp();
    if (succeeded && mounted) _setCells('');
  }

  Future<void> _selectChannel(OtpChannel channel) async {
    final auth = ref.read(otpAuthControllerProvider);
    if (auth.otpChannel == channel || auth.isRequestingOtp) return;
    final controller = ref.read(otpAuthControllerProvider.notifier);
    final succeeded = await controller.requestOtp(
      channel: channel,
      showConfirmation: true,
    );
    if (succeeded && mounted) _setCells('');
  }

  void _back() {
    ref.read(otpAuthControllerProvider.notifier).clearOtpForBackNavigation();
    context.pop();
  }

  String _formattedPhone(String phone) {
    if (phone.length != 12 || !phone.startsWith('+974')) return phone;
    return '${phone.substring(0, 4)} ${phone.substring(4, 8)} '
        '${phone.substring(8)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(otpAuthControllerProvider);
    if (auth.otpCode.isEmpty && _code.isNotEmpty && !auth.isVerifyingOtp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(otpAuthControllerProvider).otpCode.isEmpty) {
          _setCells('');
        }
      });
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EE),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.xl,
                  maxWidth: 560,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      OtpFlowHeader(onBack: _back),
                      const SizedBox(height: AppSpacing.xl),
                      const OtpBrandMark(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.otpCodeTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.otpCodeSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          _formattedPhone(auth.phoneNumber),
                          key: const ValueKey('otpPhoneDisplay'),
                          style: const TextStyle(
                            color: AppColors.darkGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            return Flexible(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: index == 0 ? 0 : 4,
                                  right: index == 5 ? 0 : 4,
                                ),
                                child: Focus(
                                  onKeyEvent: (_, event) =>
                                      _handleKey(index, event),
                                  child: TextField(
                                    key: ValueKey('otpCell$index'),
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textInputAction: index == 5
                                        ? TextInputAction.done
                                        : TextInputAction.next,
                                    textAlign: TextAlign.center,
                                    autofillHints: const [
                                      AutofillHints.oneTimeCode,
                                    ],
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    onChanged: (value) =>
                                        _onCellChanged(index, value),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 17,
                                          ),
                                      fillColor: AppColors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      if (auth.verificationError != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _verificationError(l10n, auth.verificationError!),
                          key: const ValueKey('otpVerificationError'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.jasper),
                        ),
                      ],
                      if (AppEnvironment.useMockOtp) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.otpDevelopmentCode(
                            MockOtpService.developmentCode,
                          ),
                          key: const ValueKey('developmentOtpHint'),
                          style: TextStyle(
                            color: AppColors.emeraldGreen.withValues(alpha: .7),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.xs,
                        children: [
                          ChoiceChip(
                            key: const ValueKey('smsOtpChannel'),
                            label: Text(l10n.otpSendViaSms),
                            selected: auth.otpChannel == OtpChannel.sms,
                            onSelected: (_) => _selectChannel(OtpChannel.sms),
                          ),
                          ChoiceChip(
                            key: const ValueKey('whatsappOtpChannel'),
                            label: Text(l10n.otpSendViaWhatsapp),
                            selected: auth.otpChannel == OtpChannel.whatsapp,
                            onSelected: (_) =>
                                _selectChannel(OtpChannel.whatsapp),
                          ),
                        ],
                      ),
                      if (auth.resendConfirmation) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AppEnvironment.useMockOtp &&
                                  auth.otpChannel == OtpChannel.whatsapp
                              ? l10n.otpWhatsappTestGenerated
                              : l10n.otpResendConfirmation,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.emeraldGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const Spacer(),
                      TextButton(
                        key: const ValueKey('resendOtpButton'),
                        onPressed:
                            auth.resendSecondsRemaining == 0 &&
                                !auth.isRequestingOtp
                            ? _resend
                            : null,
                        child: Text(
                          auth.resendSecondsRemaining > 0
                              ? l10n.otpResendCountdown(
                                  _countdown(auth.resendSecondsRemaining),
                                )
                              : l10n.otpResendCode,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OtpFlowButton(
                        key: const ValueKey('verifyOtpButton'),
                        label: l10n.otpVerifyCode,
                        onPressed:
                            auth.otpCode.length == 6 && !auth.isVerifyingOtp
                            ? _verify
                            : null,
                        isLoading: auth.isVerifyingOtp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _countdown(int seconds) => '00:${seconds.toString().padLeft(2, '0')}';

  String _verificationError(AppLocalizations l10n, OtpUiError error) {
    return switch (error) {
      OtpUiError.expiredCode => l10n.otpExpiredCode,
      OtpUiError.tooManyAttempts => l10n.otpTooManyAttempts,
      _ => l10n.otpIncorrectCode,
    };
  }
}
