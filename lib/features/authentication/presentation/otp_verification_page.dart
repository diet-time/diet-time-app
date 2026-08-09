import 'dart:math' as math;

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/core/config/app_environment.dart';
import 'package:diet_time/features/authentication/domain/otp_service.dart';
import 'package:diet_time/features/authentication/presentation/otp_auth_controller.dart';
import 'package:diet_time/features/authentication/presentation/otp_flow_widgets.dart';
import 'package:diet_time/features/personalization/data/customer_profile_service.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
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
  bool _isResolvingDestination = false;

  @override
  void initState() {
    super.initState();
    for (final focusNode in _focusNodes) {
      focusNode.addListener(_refreshFocusStyle);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  void _refreshFocusStyle() {
    if (mounted) setState(() {});
  }

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
    if (digits != value) _controllers[index].text = digits;
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
    var route = destination?.route ?? AppRoutes.home;
    if (route == AppRoutes.personalization) {
      setState(() => _isResolvingDestination = true);
      try {
        final profile = await ref.read(customerProfileServiceProvider).load();
        if (profile != null) {
          ref.read(personalizationControllerProvider.notifier).replace(profile);
          if (profile.isCompleted || profile.hasCapturedQuestionnaire) {
            route = AppRoutes.plans;
          }
        }
      } on Object {
        // Fall back to personalization, which has its own retry/error state.
      }
    }
    if (!mounted) return;
    setState(() => _isResolvingDestination = false);
    context.go(route);
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
    final succeeded = await ref
        .read(otpAuthControllerProvider.notifier)
        .requestOtp(channel: channel, showConfirmation: true);
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
    final compact = MediaQuery.sizeOf(context).height < 700;
    if (auth.otpCode.isEmpty && _code.isNotEmpty && !auth.isVerifyingOtp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(otpAuthControllerProvider).otpCode.isEmpty) {
          _setCells('');
        }
      });
    }
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
                  16,
                  10,
                  16,
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
                        OtpFlowHeader(onBack: _back),
                        SizedBox(height: compact ? 18 : 26),
                        const OtpBrandMark(),
                        const SizedBox(height: 18),
                        Text(
                          l10n.otpCodeTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: compact ? 30 : 34,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Text(
                              l10n.otpCodeSentTo,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                _formattedPhone(auth.phoneNumber),
                                key: const ValueKey('otpPhoneDisplay'),
                                style: const TextStyle(
                                  color: Color(0xFF3A9088),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            InkWell(
                              key: const ValueKey('editPhoneButton'),
                              onTap: _back,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 13,
                                      color: Color(0xFF3A9088),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      l10n.otpEditPhone,
                                      style: const TextStyle(
                                        color: Color(0xFF3A9088),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 22 : 30),
                        _OtpInputPanel(
                          controllers: _controllers,
                          focusNodes: _focusNodes,
                          onChanged: _onCellChanged,
                          onKeyEvent: _handleKey,
                          hasError: auth.verificationError != null,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.otpCodeEntryHelper,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 11,
                                  height: 1.35,
                                  color: AppColors.darkGreen.withValues(
                                    alpha: .62,
                                  ),
                                ),
                          ),
                        ),
                        if (AppEnvironment.enableTestOtp) ...[
                          const SizedBox(height: 6),
                          Text(
                            l10n.otpDevelopmentCode(AppEnvironment.testOtp),
                            key: const ValueKey('developmentOtpHint'),
                            style: TextStyle(
                              color: AppColors.emeraldGreen.withValues(
                                alpha: .62,
                              ),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (auth.verificationError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _verificationError(l10n, auth.verificationError!),
                            key: const ValueKey('otpVerificationError'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.jasper),
                          ),
                        ],
                        SizedBox(height: compact ? 8 : 14),
                        if (AppEnvironment.enableRequestOtpApi) ...[
                          Text(
                            l10n.otpDidntGetCode,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.darkGreen.withValues(
                                    alpha: .7,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              TextButton(
                                key: const ValueKey('resendOtpButton'),
                                onPressed:
                                    auth.resendSecondsRemaining == 0 &&
                                        !auth.isRequestingOtp
                                    ? _resend
                                    : null,
                                child: Text(
                                  l10n.otpSendViaSms,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton(
                                key: const ValueKey('whatsappOtpChannel'),
                                onPressed:
                                    auth.isRequestingOtp ||
                                        auth.otpChannel == OtpChannel.whatsapp
                                    ? null
                                    : () => _selectChannel(OtpChannel.whatsapp),
                                child: Text(
                                  l10n.otpResendViaWhatsapp,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (auth.resendConfirmation)
                            Text(
                              AppEnvironment.enableTestOtp &&
                                      auth.otpChannel == OtpChannel.whatsapp
                                  ? l10n.otpWhatsappTestGenerated
                                  : l10n.otpResendConfirmation,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF3A9088),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          SizedBox(height: compact ? 4 : 8),
                          _CountdownRing(
                            seconds: auth.resendSecondsRemaining,
                            compact: compact,
                          ),
                        ] else ...[
                          TextButton(
                            key: const ValueKey('resendOtpButton'),
                            onPressed: null,
                            child: Text(l10n.otpResendTestUnavailable),
                          ),
                        ],
                        const Spacer(),
                        SizedBox(height: compact ? 10 : 16),
                        OtpFlowButton(
                          key: const ValueKey('verifyOtpButton'),
                          label: l10n.otpVerifyCode,
                          onPressed:
                              auth.otpCode.length == 6 &&
                                  !auth.isVerifyingOtp &&
                                  !_isResolvingDestination
                              ? _verify
                              : null,
                          isLoading:
                              auth.isVerifyingOtp || _isResolvingDestination,
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

  String _verificationError(AppLocalizations l10n, OtpUiError error) {
    return switch (error) {
      OtpUiError.validation =>
        ref.read(otpAuthControllerProvider).verificationMessage ??
            l10n.otpInvalidPhone,
      OtpUiError.incorrectCode => l10n.otpInvalidCode,
      OtpUiError.accountConflict => l10n.otpAccountConflict,
      OtpUiError.tooManyAttempts => l10n.otpTooManyAttempts,
      OtpUiError.unavailable => l10n.otpPhoneLoginUnavailable,
      OtpUiError.connection => l10n.otpConnectionError,
      OtpUiError.server => l10n.otpServerError,
      _ => l10n.otpServerError,
    };
  }
}

class _OtpInputPanel extends StatelessWidget {
  const _OtpInputPanel({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onKeyEvent,
    required this.hasError,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final KeyEventResult Function(int index, KeyEvent event) onKeyEvent;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: List.generate(6, (index) {
          final active = focusNodes[index].hasFocus;
          final filled = controllers[index].text.isNotEmpty;
          final borderColor = hasError
              ? AppColors.jasper.withValues(alpha: .72)
              : active
              ? AppColors.emeraldGreen
              : AppColors.darkGreen.withValues(alpha: .14);
          return Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: index == 5 ? 0 : 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: borderColor,
                    width: active ? 1.6 : 1,
                  ),
                  boxShadow: [
                    if (active)
                      BoxShadow(
                        color: AppColors.emeraldGreen.withValues(alpha: .08),
                        blurRadius: 10,
                      ),
                  ],
                ),
                child: Focus(
                  onKeyEvent: (_, event) => onKeyEvent(index, event),
                  child: TextField(
                    key: ValueKey('otpCell$index'),
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    keyboardType: TextInputType.number,
                    textInputAction: index == 5
                        ? TextInputAction.done
                        : TextInputAction.next,
                    textAlign: TextAlign.center,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: TextStyle(
                      color: filled
                          ? AppColors.darkGreen
                          : AppColors.emeraldGreen,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                    onChanged: (value) => onChanged(index, value),
                    decoration: const InputDecoration(
                      counterText: '',
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 17),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.seconds, required this.compact});

  final int seconds;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = (seconds / 30).clamp(0.0, 1.0);
    return SizedBox.square(
      dimension: compact ? 50 : 58,
      child: CustomPaint(
        painter: _CountdownPainter(progress: progress),
        child: Center(
          child: Text(
            '00:${seconds.toString().padLeft(2, '0')}',
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Color(0xFF316C65), fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _CountdownPainter extends CustomPainter {
  const _CountdownPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide / 2) - 3;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFDCE9E2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = const Color(0xFF2B7D6D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CountdownPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
