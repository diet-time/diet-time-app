import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

class LanguageSelectionPanel extends StatefulWidget {
  const LanguageSelectionPanel({super.key});

  @override
  State<LanguageSelectionPanel> createState() => _LanguageSelectionPanelState();
}

class _LanguageSelectionPanelState extends State<LanguageSelectionPanel> {
  String? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final isArabic = _selectedLanguage == 'ar';
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: PopScope(
        canPop: false,
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              key: const ValueKey('languageSelectionPanel'),
              constraints: const BoxConstraints(maxWidth: 620),
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 52),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEFB),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkGreen.withValues(alpha: .18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.darkGreen.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isArabic ? 'اختر لغتك' : 'Choose your language',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _LanguageAction(
                            key: const ValueKey('languageOption-en'),
                            label: 'English',
                            selected: _selectedLanguage == 'en',
                            onTap: () =>
                                setState(() => _selectedLanguage = 'en'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LanguageAction(
                            key: const ValueKey('languageOption-ar'),
                            label: 'العربية',
                            selected: _selectedLanguage == 'ar',
                            onTap: () =>
                                setState(() => _selectedLanguage = 'ar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      key: const ValueKey('languageSelectionContinue'),
                      label: isArabic ? 'متابعة' : 'Continue',
                      onPressed: _selectedLanguage == null
                          ? null
                          : () => Navigator.of(context).pop(_selectedLanguage),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageAction extends StatelessWidget {
  const _LanguageAction({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppButton.height,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkGreen,
          backgroundColor: selected ? const Color(0xFFEAF6EC) : Colors.white,
          side: BorderSide(
            color: selected
                ? AppColors.emeraldGreen
                : AppColors.darkGreen.withValues(alpha: .14),
            width: selected ? 1.5 : 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 7),
              const Icon(
                Icons.check_circle_rounded,
                key: ValueKey('selected'),
                color: AppColors.emeraldGreen,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
