import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/app/theme/app_spacing.dart';
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
    context.push(AppRoutes.otp);
  }

  void _back() {
    ref.read(otpAuthControllerProvider.notifier).cancel();
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(otpAuthControllerProvider);
    final error = _hasInteracted && _phoneController.text.isNotEmpty
        ? (_isValidPhone ? null : l10n.otpInvalidPhone)
        : null;
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
                      OtpFlowHeader(onBack: context.canPop() ? _back : null),
                      const Spacer(),
                      const OtpBrandMark(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.otpPhoneTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.otpPhoneSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        l10n.otpPhoneHelper,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.darkGreen.withValues(alpha: .55),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 58,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                border: Border.all(
                                  color: AppColors.darkGreen.withValues(
                                    alpha: .1,
                                  ),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Text('🇶🇦', style: TextStyle(fontSize: 23)),
                                  SizedBox(width: AppSpacing.sm),
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
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextField(
                                key: const ValueKey('phoneNumberInput'),
                                controller: _phoneController,
                                focusNode: _phoneFocusNode,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.telephoneNumberNational,
                                ],
                                inputFormatters: [_QatarPhoneInputFormatter()],
                                onChanged: _onChanged,
                                onSubmitted: (_) => _continue(),
                                decoration: InputDecoration(
                                  hintText: l10n.otpMobileNumber,
                                  errorText: error,
                                  fillColor: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (auth.requestError != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _requestError(l10n, auth.requestError!),
                          key: const ValueKey('otpRequestError'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.jasper),
                        ),
                      ],
                      const Spacer(flex: 2),
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
