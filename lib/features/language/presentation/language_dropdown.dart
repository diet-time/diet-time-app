import 'package:flutter/material.dart';
import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/localization/customer_copy.dart';

class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({
    super.key,
    required this.languageCode,
    required this.onSelected,
    this.keyPrefix = "guest",
  });

  final String keyPrefix;
  final String languageCode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isArabic = languageCode == 'ar';
    return Semantics(
      label: context.customerCopy('Language'),
      button: true,
      child: PopupMenuButton<String>(
        key: ValueKey('${keyPrefix}LanguageSelector'),
        tooltip: context.customerCopy('Language'),
        onSelected: onSelected,
        position: PopupMenuPosition.under,
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (context) => [
          CheckedPopupMenuItem(
            key: ValueKey('$keyPrefix-language-en'),
            value: 'en',
            checked: !isArabic,
            child: const Text('English'),
          ),
          CheckedPopupMenuItem(
            key: ValueKey('$keyPrefix-language-ar'),
            value: 'ar',
            checked: isArabic,
            child: const Text('العربية'),
          ),
        ],
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 10, 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: AppColors.emeraldGreen.withValues(alpha: .18),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120B3226),
                blurRadius: 24,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_rounded,
                size: 18,
                color: AppColors.emeraldGreen,
              ),
              const SizedBox(width: 7),
              Text(
                isArabic ? 'العربية' : 'English',
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.emeraldGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
