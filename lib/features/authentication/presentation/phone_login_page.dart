import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/core/widgets/app_logo.dart';
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
  _CountryOption _country = _countries.first;
  bool _hasInteracted = false;
  bool _isSubmitting = false;

  bool get _isValidPhone => _country.isValid(_phoneController.text);

  @override
  void initState() {
    super.initState();
    final auth = ref.read(otpAuthControllerProvider);
    _country = _countryFor(auth.phoneNumber);
    _phoneController.text = _localNumber(auth.phoneNumber, _country);
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

  _CountryOption _countryFor(String number) => _countries.firstWhere(
    (country) => number.startsWith(country.dialCode),
    orElse: () => _countries.first,
  );

  String _localNumber(String number, _CountryOption country) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    final dialCode = country.dialCode.substring(1);
    return digits.startsWith(dialCode)
        ? digits.substring(dialCode.length)
        : digits;
  }

  void _onChanged(String value) {
    setState(() => _hasInteracted = true);
    ref
        .read(otpAuthControllerProvider.notifier)
        .setPhoneNumber(
          _country.isValid(value) ? '${_country.dialCode}$value' : '',
        );
  }

  void _selectCountry(_CountryOption? country) {
    if (country == null || country == _country) return;
    setState(() {
      _country = country;
      _phoneController.clear();
      _hasInteracted = false;
    });
    ref.read(otpAuthControllerProvider.notifier).setPhoneNumber('');
    _phoneFocusNode.requestFocus();
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
    controller.setPhoneNumber('${_country.dialCode}${_phoneController.text}');
    final succeeded = await controller.requestOtp();
    if (!mounted) return;
    if (!succeeded) {
      setState(() => _isSubmitting = false);
      return;
    }
    await context.push(AppRoutes.otp);
    if (mounted) setState(() => _isSubmitting = false);
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
      backgroundColor: AppColors.emeraldGreen,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroHeight = (constraints.maxHeight * .45).clamp(
              245.0,
              370.0,
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/login_meal_background.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: AppColors.emeraldGreen),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.black.withValues(alpha: .36),
                        AppColors.emeraldGreen.withValues(alpha: .05),
                        AppColors.emeraldGreen.withValues(alpha: .40),
                      ],
                    ),
                  ),
                ),
                SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: heroHeight,
                          child: SafeArea(
                            bottom: false,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const AppLogo(
                                    width: 84,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    l10n.healthy,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 38,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    l10n.journeyStartsHere,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - heroHeight,
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 9, 20, 28),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFCFBF7),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(27),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppColors.darkGreen.withValues(
                                          alpha: .16,
                                        ),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                    if (context.canPop())
                                      Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: IconButton(
                                          onPressed: _back,
                                          icon: const Icon(
                                            Icons.arrow_back_rounded,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  l10n.welcomeBack,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.darkGreen,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.otpPhoneSubtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.darkGreen.withValues(
                                      alpha: .58,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      PopupMenuButton<_CountryOption>(
                                        key: const ValueKey(
                                          'countryCodeSelector',
                                        ),
                                        onSelected: _selectCountry,
                                        itemBuilder: (context) => [
                                          for (final country in _countries)
                                            PopupMenuItem(
                                              value: country,
                                              child: Text(
                                                '${country.isoCode} ${country.dialCode}',
                                              ),
                                            ),
                                        ],
                                        child: Container(
                                          height: 56,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 13,
                                          ),
                                          decoration: _fieldDecoration(),
                                          child: Row(
                                            children: [
                                              if (_country.isoCode == 'QA')
                                                const Text(
                                                  '🇶🇦',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              const SizedBox(width: 7),
                                              Text(
                                                '${_country.isoCode} ${_country.dialCode}',
                                                style: const TextStyle(
                                                  color: AppColors.darkGreen,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: TextField(
                                          key: const ValueKey(
                                            'phoneNumberInput',
                                          ),
                                          controller: _phoneController,
                                          focusNode: _phoneFocusNode,
                                          keyboardType: TextInputType.phone,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints
                                                .telephoneNumberNational,
                                          ],
                                          inputFormatters: [
                                            _PhoneInputFormatter(_country),
                                          ],
                                          onChanged: _onChanged,
                                          onSubmitted: (_) => _continue(),
                                          decoration: InputDecoration(
                                            hintText: l10n.otpMobileNumber,
                                            errorText: error,
                                            fillColor: AppColors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 15,
                                                  vertical: 16,
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
                                    style: const TextStyle(
                                      color: AppColors.jasper,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
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
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Kept temporarily as a private reference while the OTP verification screen
  // continues to share its original reusable widgets.
  // ignore: unused_element
  Widget _buildLegacy(BuildContext context) {
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
                              PopupMenuButton<_CountryOption>(
                                key: const ValueKey('countryCodeSelector'),
                                onSelected: _selectCountry,
                                itemBuilder: (context) => _countries
                                    .map(
                                      (country) => PopupMenuItem(
                                        value: country,
                                        child: Text(
                                          '${country.isoCode} ${country.dialCode}',
                                          textDirection: TextDirection.ltr,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                child: Container(
                                  height: 58,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: _fieldDecoration(),
                                  child: Row(
                                    children: [
                                      if (_country.isoCode == 'QA')
                                        Text(
                                          '🇶🇦',
                                          style: TextStyle(fontSize: 20),
                                        ),
                                      SizedBox(width: 9),
                                      Text(
                                        '${_country.isoCode} ${_country.dialCode}',
                                        style: TextStyle(
                                          color: AppColors.darkGreen,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                      _PhoneInputFormatter(_country),
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

class _PhoneInputFormatter extends TextInputFormatter {
  const _PhoneInputFormatter(this.country);

  final _CountryOption country;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final dialCode = country.dialCode.substring(1);
    if (digits.startsWith(dialCode) && digits.length > country.nationalLength) {
      digits = digits.substring(dialCode.length);
    }
    if (digits.length > country.nationalLength) {
      digits = digits.substring(0, country.nationalLength);
    }
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

class _CountryOption {
  const _CountryOption({
    required this.isoCode,
    required this.dialCode,
    required this.nationalLength,
    this.allowedStartDigits,
  });

  final String isoCode;
  final String dialCode;
  final int nationalLength;
  final String? allowedStartDigits;

  bool isValid(String number) {
    if (!RegExp('^\\d{$nationalLength}\$').hasMatch(number)) return false;
    return allowedStartDigits == null ||
        allowedStartDigits!.contains(number[0]);
  }
}

const _countries = [
  _CountryOption(
    isoCode: 'QA',
    dialCode: '+974',
    nationalLength: 8,
    allowedStartDigits: '3567',
  ),
  _CountryOption(isoCode: 'SA', dialCode: '+966', nationalLength: 9),
  _CountryOption(isoCode: 'AE', dialCode: '+971', nationalLength: 9),
  _CountryOption(isoCode: 'KW', dialCode: '+965', nationalLength: 8),
  _CountryOption(isoCode: 'BH', dialCode: '+973', nationalLength: 8),
  _CountryOption(isoCode: 'OM', dialCode: '+968', nationalLength: 8),
];
