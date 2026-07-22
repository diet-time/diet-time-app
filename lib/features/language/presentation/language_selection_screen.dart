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
  late final AnimationController _entranceController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _cardOffset;
  String? _selectedLanguage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _logoScale = Tween<double>(begin: .88, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _cardOffset = Tween<Offset>(begin: const Offset(0, .16), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _entranceController.forward();
  }

  Future<void> _selectLanguage(String languageCode) async {
    if (_isSaving) return;
    setState(() {
      _selectedLanguage = languageCode;
      _isSaving = true;
    });
    try {
      await ref
          .read(languageControllerProvider.notifier)
          .selectLanguage(languageCode);
      if (mounted) context.go(AppRoutes.onboarding);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save language preference.')),
      );
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF004C3A),
              AppColors.emeraldGreen,
              Color(0xFF16815E),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 650;
              final horizontalInset = constraints.maxWidth < 500 ? 20.0 : 40.0;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalInset,
                  compact ? 12 : 24,
                  horizontalInset,
                  mediaQuery.padding.bottom > 0 ? 12 : 20,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: _LanguageHeader(compact: compact, l10n: l10n),
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: _cardOffset,
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: _LanguageCard(
                            englishLabel: l10n.english,
                            arabicLabel: l10n.arabic,
                            languageLabel: l10n.languageLabel,
                            selectedLanguage: _selectedLanguage,
                            enabled: !_isSaving,
                            onSelected: _selectLanguage,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LanguageHeader extends StatelessWidget {
  const _LanguageHeader({required this.compact, required this.l10n});

  final bool compact;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(width: compact ? 150 : 210, color: AppColors.limeGlow),
            SizedBox(height: compact ? 16 : 28),
            Text(
              l10n.chooseLanguage,
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(
                color: AppColors.white,
                fontSize: compact ? 23 : 28,
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                l10n.languageSelectionSubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.white.withValues(alpha: .75),
                  fontSize: compact ? 13 : 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.englishLabel,
    required this.arabicLabel,
    required this.languageLabel,
    required this.selectedLanguage,
    required this.enabled,
    required this.onSelected,
  });

  final String englishLabel;
  final String arabicLabel;
  final String languageLabel;
  final String? selectedLanguage;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: .20),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.language_rounded, color: AppColors.emeraldGreen),
              const SizedBox(width: 10),
              Text(
                languageLabel,
                style: AppTypography.label.copyWith(
                  color: AppColors.darkGreen,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _LanguageButton(
            flag: '🇬🇧',
            label: englishLabel,
            selected: selectedLanguage == 'en',
            enabled: enabled,
            onTap: () => onSelected('en'),
          ),
          const SizedBox(height: 12),
          _LanguageButton(
            flag: '🇶🇦',
            label: arabicLabel,
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
    final selected = widget.selected;
    return AnimatedScale(
      scale: _pressed ? .97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
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
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.emeraldGreen : AppColors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.emeraldGreen, width: 1.4),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.emeraldGreen.withValues(alpha: .18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.flag, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: AppTypography.label.copyWith(
                      color: selected
                          ? AppColors.white
                          : AppColors.emeraldGreen,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
