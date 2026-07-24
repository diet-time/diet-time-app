import 'dart:ui';

import 'package:diet_time/app/router/app_router.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_typography.dart';
import 'package:diet_time/core/widgets/app_logo.dart';
import 'package:diet_time/features/language/presentation/language_controller.dart';
import 'package:diet_time/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheetController;
  late final Animation<Offset> _sheetOffset;
  late final Animation<double> _backdropOpacity;
  String? _selectedLanguage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _sheetOffset = Tween<Offset>(begin: const Offset(0, 1.04), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _sheetController,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    _backdropOpacity = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOut,
    );
    _sheetController.forward();
  }

  Future<void> _selectLanguage(String languageCode) async {
    if (_isSaving) return;
    setState(() {
      _selectedLanguage = languageCode;
      _isSaving = true;
    });
    try {
      // Leave enough time for the check and scale animations to be perceived.
      await Future.wait([
        ref
            .read(languageControllerProvider.notifier)
            .selectLanguage(languageCode),
        Future<void>.delayed(const Duration(milliseconds: 260)),
      ]);
      if (!mounted) return;
      await _sheetController.reverse();
      if (mounted) context.go(AppRoutes.onboarding);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).languageSaveError)),
      );
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.emeraldGreen,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/onboarding_1.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            FadeTransition(
              opacity: _backdropOpacity,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
                child: ColoredBox(
                  color: AppColors.darkGreen.withValues(alpha: .62),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: _sheetOffset,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: _LanguageSheet(
                      l10n: l10n,
                      selectedLanguage: _selectedLanguage,
                      enabled: !_isSaving,
                      onSelected: _selectLanguage,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({
    required this.l10n,
    required this.selectedLanguage,
    required this.enabled,
    required this.onSelected,
  });

  final AppLocalizations l10n;
  final String? selectedLanguage;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 650;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: EdgeInsets.fromLTRB(22, compact ? 12 : 16, 22, 22),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.white.withValues(alpha: .75)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: .28),
            blurRadius: 38,
            spreadRadius: 2,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.darkGreen.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          SizedBox(height: compact ? 11 : 16),
          AppLogo(width: compact ? 112 : 140),
          SizedBox(height: compact ? 10 : 16),
          Text(
            l10n.chooseLanguage,
            textAlign: TextAlign.center,
            style: AppTypography.title.copyWith(
              color: AppColors.darkGreen,
              fontSize: compact ? 23 : 27,
            ),
          ),
          const SizedBox(height: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Text(
              l10n.languageSelectionSubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.darkGreen.withValues(alpha: .62),
                fontSize: compact ? 12 : 14,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: compact ? 14 : 20),
          _LanguageButton(
            flag: '🇬🇧',
            label: l10n.english,
            selected: selectedLanguage == 'en',
            enabled: enabled,
            onTap: () => onSelected('en'),
          ),
          const SizedBox(height: 11),
          _LanguageButton(
            flag: '🇶🇦',
            label: l10n.arabic,
            selected: selectedLanguage == 'ar',
            enabled: enabled,
            onTap: () => onSelected('ar'),
          ),
        ],
      ),
    );
  }
}

class _LanguageButton extends StatefulWidget {
  const _LanguageButton({
    required this.flag,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_LanguageButton> createState() => _LanguageButtonState();
}

class _LanguageButtonState extends State<_LanguageButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? .97 : (widget.selected ? 1.015 : 1),
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutBack,
      child: Semantics(
        button: true,
        selected: widget.selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: widget.enabled
              ? () => setState(() => _pressed = false)
              : null,
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.teaGreen.withValues(alpha: .30)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: widget.selected
                    ? AppColors.emeraldGreen
                    : AppColors.darkGreen.withValues(alpha: .11),
                width: widget.selected ? 1.7 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkGreen.withValues(
                    alpha: widget.selected ? .10 : .04,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(widget.flag, style: const TextStyle(fontSize: 27)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.label,
                    style: AppTypography.label.copyWith(
                      color: AppColors.darkGreen,
                      fontSize: 16,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 230),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: widget.selected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('checked'),
                          color: AppColors.emeraldGreen,
                          size: 26,
                        )
                      : const SizedBox(key: ValueKey('unchecked'), width: 26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
