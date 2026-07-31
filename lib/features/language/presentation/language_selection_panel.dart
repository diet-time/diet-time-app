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
        child: Material(
          key: const ValueKey('languageSelectionPanel'),
          color: const Color(0xFFFFFEFB),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.darkGreen.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isArabic ? 'اختر لغتك' : 'Choose your language',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    isArabic
                        ? 'يمكنك تغييرها لاحقاً.'
                        : 'You can change this later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.darkGreen.withValues(alpha: .62),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _LanguageAction(
                    key: const ValueKey('languageOption-en'),
                    label: 'English',
                    selected: _selectedLanguage == 'en',
                    onTap: () => setState(() => _selectedLanguage = 'en'),
                  ),
                  const SizedBox(height: 10),
                  _LanguageAction(
                    key: const ValueKey('languageOption-ar'),
                    label: 'العربية',
                    selected: _selectedLanguage == 'ar',
                    onTap: () => setState(() => _selectedLanguage = 'ar'),
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
    return Material(
      color: selected ? const Color(0xFFEAF6EC) : Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? AppColors.emeraldGreen
                  : AppColors.darkGreen.withValues(alpha: .12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('selected'),
                        color: AppColors.emeraldGreen,
                        size: 22,
                      )
                    : Icon(
                        Icons.circle_outlined,
                        key: const ValueKey('unselected'),
                        color: AppColors.darkGreen.withValues(alpha: .28),
                        size: 22,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
