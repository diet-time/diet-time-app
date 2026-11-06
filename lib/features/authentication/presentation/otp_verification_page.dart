import 'dart:math' as math;

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
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
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refreshFocusStyle);
    _focusNode.addListener(_refreshFocusStyle);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _refreshFocusStyle() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _code => _controller.text;

  void _onCodeChanged(String value) {
    ref.read(otpAuthControllerProvider.notifier).setOtpCode(_code);
    if (_code.length == 6 && _controller.selection.extentOffset == 6) {
      _focusNode.unfocus();
    }
    setState(() {});
  }

  void _setCells(String code) {
    _controller.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
    ref.read(otpAuthControllerProvider.notifier).setOtpCode(_code);
    if (code.length == 6) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
    setState(() {});
  }

  void _selectDigit(int index) {
    _focusNode.requestFocus();
    final start = math.min(index, _code.length);
    _controller.selection = TextSelection(
      baseOffset: start,
      extentOffset: math.min(start + 1, _code.length),
    );
  }

  Future<void> _verify() async {
    final succeeded = await ref
        .read(otpAuthControllerProvider.notifier)
        .verifyOtp();
    if (!mounted || !succeeded) return;
    _setCells('');
    final destination = ref.read(otpAuthControllerProvider).pendingDestination;
    final startNewPlan =
        destination?.route == AppRoutes.startPlan ||
        destination?.route == AppRoutes.checkoutEntry ||
        destination?.route == AppRoutes.planSummary;
    context.go(
      startNewPlan ? AppRoutes.startPlan : AppRoutes.authenticatedLanding,
    );
  }

  Future<void> _resend() async {
    final succeeded = await ref
        .read(otpAuthControllerProvider.notifier)
        .resendOtp();
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
                          controller: _controller,
                          focusNode: _focusNode,
                          onChanged: _onCodeChanged,
                          onSelect: _selectDigit,
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
                        if (auth.verificationError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _verificationError(l10n, auth.verificationError!),
                            key: const ValueKey('otpVerificationError'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.jasper),
                          ),
                        ],
                        if (auth.requestError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            auth.requestError == OtpUiError.tooManyAttempts
                                ? l10n.otpTooManyAttempts
                                : l10n.otpRequestFailed,
                            key: const ValueKey('otpResendError'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.jasper),
                          ),
                        ],
                        SizedBox(height: compact ? 8 : 14),
                        ...[
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
                          TextButton(
                            key: const ValueKey('resendOtpButton'),
                            onPressed:
                                auth.resendSecondsRemaining == 0 &&
                                    !auth.isRequestingOtp &&
                                    !auth.isVerifyingOtp
                                ? _resend
                                : null,
                            child: Text(l10n.otpResendViaWhatsapp),
                          ),
                          if (auth.resendConfirmation)
                            Text(
                              l10n.otpResendConfirmation,
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
                        ],
                        const Spacer(),
                        SizedBox(height: compact ? 10 : 16),
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

class _OtpInputPanel extends StatefulWidget {
  const _OtpInputPanel({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSelect,
    required this.hasError,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<int> onSelect;
  final bool hasError;
  @override
  State<_OtpInputPanel> createState() => _OtpInputPanelState();
}

class _OtpInputPanelState extends State<_OtpInputPanel> {
  int _tappedDigit = 0;
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final focusNode = widget.focusNode;
    final cursor = controller.selection.start.clamp(0, 5);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 62,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              ExcludeSemantics(
                child: Row(
                  children: List.generate(6, (index) {
                    final active = focusNode.hasFocus && cursor == index;
                    final digit = index < controller.text.length
                        ? controller.text[index]
                        : '';
                    final borderColor = widget.hasError
                        ? AppColors.jasper.withValues(alpha: .72)
                        : active
                        ? AppColors.emeraldGreen
                        : AppColors.darkGreen.withValues(alpha: .14);
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: index == 5 ? 0 : 6,
                        ),
                        child: AnimatedContainer(
                          key: ValueKey('otpDigit$index'),
                          duration: const Duration(milliseconds: 160),
                          height: 62,
                          alignment: Alignment.center,
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
                                  color: AppColors.emeraldGreen.withValues(
                                    alpha: .08,
                                  ),
                                  blurRadius: 10,
                                ),
                            ],
                          ),
                          child: Text(
                            digit,
                            style: TextStyle(
                              color: digit.isNotEmpty
                                  ? AppColors.darkGreen
                                  : AppColors.emeraldGreen,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // The real native editor handles software-keyboard deletion, long-press
              // Paste, accessibility and SMS autofill. Boxes only render its value.
              Positioned.fill(
                child: Listener(
                  onPointerDown: (event) => _tappedDigit =
                      (event.localPosition.dx / (constraints.maxWidth / 6))
                          .floor()
                          .clamp(0, 5),
                  child: TextSelectionTheme(
                    data: const TextSelectionThemeData(
                      selectionColor: Colors.transparent,
                    ),
                    child: TextField(
                      key: const ValueKey('otpCell0'),
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      autocorrect: false,
                      enableSuggestions: false,
                      showCursor: false,
                      inputFormatters: [
                        _CompleteOtpPasteFormatter(),
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: const TextStyle(color: Colors.transparent),
                      onTap: () => widget.onSelect(_tappedDigit),
                      onChanged: widget.onChanged,
                      decoration: const InputDecoration(
                        filled: false,
                        counterText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteOtpPasteFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final start = oldValue.selection.start.clamp(0, oldValue.text.length);
    final end = oldValue.selection.end.clamp(start, oldValue.text.length);
    final insertedLength =
        newValue.text.length - (oldValue.text.length - (end - start));
    if (insertedLength > 0 && start + insertedLength <= newValue.text.length) {
      final inserted = newValue.text
          .substring(start, start + insertedLength)
          .replaceAll(RegExp(r'\D'), '');
      if (inserted.length >= 6) {
        return TextEditingValue(
          text: inserted.substring(0, 6),
          selection: const TextSelection.collapsed(offset: 6),
        );
      }
    }
    return newValue;
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.seconds, required this.compact});

  final int seconds;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = (seconds / 60).clamp(0.0, 1.0);
    return SizedBox.square(
      dimension: compact ? 50 : 58,
      child: CustomPaint(
        painter: _CountdownPainter(progress: progress),
        child: Center(
          child: Text(
            '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
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
