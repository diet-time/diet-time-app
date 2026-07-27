import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/authentication/presentation/otp_flow_widgets.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PhoneLoginPage extends ConsumerStatefulWidget {
  const PhoneLoginPage({required this.pendingDestination, super.key});

  final PendingAuthDestination pendingDestination;

  @override
  ConsumerState<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends ConsumerState<PhoneLoginPage> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  bool _hasInteracted = false;
  bool _isSubmitting = false;

  bool get _isValidPhone =>
      RegExp(r'^[3567]\d{7}$').hasMatch(_phoneController.text);

  @override
  void initState() {
    super.initState();
    final auth = ref.read(otpAuthControllerProvider);
    _phoneController.text = _localNumber(auth.phoneNumber);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(otpAuthControllerProvider.notifier)
            .begin(widget.pendingDestination);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  String _localNumber(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('974') ? digits.substring(3) : digits;
  }

  void _onChanged(String value) {
    setState(() => _hasInteracted = true);
    ref
        .read(otpAuthControllerProvider.notifier)
        .setPhoneNumber(value.length == 8 ? '+974$value' : '');
  }

  Future<void> _continue() async {
    if (_isSubmitting) return;
    if (!_isValidPhone) {
      setState(() => _hasInteracted = true);
      return;
    }
    setState(() => _isSubmitting = true);
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = ref.read(otpAuthControllerProvider.notifier);
    controller.setPhoneNumber('+974${_phoneController.text}');
    final succeeded = await controller.requestOtp();
    if (!mounted) return;
    if (!succeeded) {
      setState(() => _isSubmitting = false);
      return;
    }
    await context.push(AppRoutes.otp);
    if (mounted) setState(() => _isSubmitting = false);
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).comingSoon)),
    );
  }

  void _back() {
    ref.read(otpAuthControllerProvider.notifier).cancel();
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(otpAuthControllerProvider);
    final compact = MediaQuery.sizeOf(context).height < 700;
    final error = _hasInteracted && _phoneController.text.isNotEmpty
        ? (_isValidPhone ? null : l10n.otpInvalidPhone)
        : null;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      body: AuthFlowBackground(
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 30,
                    maxWidth: 560,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        OtpFlowHeader(onBack: context.canPop() ? _back : null),
                        Spacer(flex: compact ? 1 : 2),
                        const OtpBrandMark(),
                        const SizedBox(height: 20),
                        Text(
                          l10n.otpPhoneTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: compact ? 30 : 34,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          l10n.otpPhoneSubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.otpPhoneHelper,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.darkGreen.withValues(
                                  alpha: .45,
                                ),
                                fontSize: 11,
                              ),
                        ),
                        SizedBox(height: compact ? 20 : 26),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 58,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: _fieldDecoration(),
                                child: const Row(
                                  children: [
                                    Text(
                                      '🇶🇦',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    SizedBox(width: 9),
                                    Text(
                                      '+974',
                                      style: TextStyle(
                                        color: AppColors.darkGreen,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: error == null ? 58 : null,
                                  child: TextField(
                                    key: const ValueKey('phoneNumberInput'),
                                    controller: _phoneController,
                                    focusNode: _phoneFocusNode,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.telephoneNumberNational,
                                    ],
                                    inputFormatters: [
                                      _QatarPhoneInputFormatter(),
                                    ],
                                    onChanged: _onChanged,
                                    onSubmitted: (_) => _continue(),
                                    decoration: InputDecoration(
                                      hintText: l10n.otpMobileNumber,
                                      errorText: error,
                                      fillColor: AppColors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 17,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (auth.requestError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _requestError(l10n, auth.requestError!),
                            key: const ValueKey('otpRequestError'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.jasper),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _SignInDivider(label: l10n.orSignInWith),
                        const SizedBox(height: 14),
                        _SocialAuthButtons(
                          googleLabel: l10n.continueWithGoogle,
                          appleLabel: l10n.continueWithApple,
                          onPressed: _showComingSoon,
                        ),
                        Spacer(flex: compact ? 1 : 3),
                        OtpFlowButton(
                          key: const ValueKey('phoneContinueButton'),
                          label: l10n.continueLabel,
                          onPressed:
                              _isValidPhone &&
                                  !auth.isRequestingOtp &&
                                  !_isSubmitting
                              ? _continue
                              : null,
                          isLoading: auth.isRequestingOtp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.darkGreen.withValues(alpha: .1)),
      boxShadow: [
        BoxShadow(
          color: AppColors.darkGreen.withValues(alpha: .025),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  String _requestError(AppLocalizations l10n, OtpUiError error) {
    return switch (error) {
      OtpUiError.tooManyAttempts => l10n.otpTooManyAttempts,
      OtpUiError.resendUnavailable => l10n.otpResendUnavailable,
      _ => l10n.otpRequestFailed,
    };
  }
}

class _SignInDivider extends StatelessWidget {
  const _SignInDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.darkGreen.withValues(alpha: .72),
              fontSize: 11,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.black,
          backgroundColor: AppColors.white.withValues(alpha: .8),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: BorderSide(color: AppColors.darkGreen.withValues(alpha: .65)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialAuthButtons extends StatelessWidget {
  const _SocialAuthButtons({
    required this.googleLabel,
    required this.appleLabel,
    required this.onPressed,
  });

  final String googleLabel;
  final String appleLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final stack = MediaQuery.sizeOf(context).width < 380;
    final google = _SocialAuthButton(
      key: const ValueKey('googleSignInButton'),
      label: googleLabel,
      icon: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      onPressed: onPressed,
    );
    final apple = _SocialAuthButton(
      key: const ValueKey('appleSignInButton'),
      label: appleLabel,
      icon: const Icon(Icons.apple, color: AppColors.black, size: 21),
      onPressed: onPressed,
    );
    if (stack) {
      return Column(children: [google, const SizedBox(height: 10), apple]);
    }
    return Row(
      children: [
        Expanded(child: google),
        const SizedBox(width: 10),
        Expanded(child: apple),
      ],
    );
  }
}

class _QatarPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('974') && digits.length > 8) {
      digits = digits.substring(3);
    }
    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
