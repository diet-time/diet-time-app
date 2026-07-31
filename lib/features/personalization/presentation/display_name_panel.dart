import 'package:diet_time/app/theme/app_colors.dart';
import 'package:diet_time/app/theme/app_radius.dart';
import 'package:diet_time/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

class DisplayNamePanel extends StatefulWidget {
  const DisplayNamePanel({super.key});

  @override
  State<DisplayNamePanel> createState() => _DisplayNamePanelState();
}

class _DisplayNamePanelState extends State<DisplayNamePanel> {
  final _controller = TextEditingController();
  bool _canContinue = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: false,
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(12, 12, 12, keyboardInset + 52),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                key: const ValueKey('displayNamePanel'),
                constraints: const BoxConstraints(maxWidth: 620),
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
                        isArabic
                            ? 'ماذا تحب أن نناديك؟'
                            : 'What should we call you?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        key: const ValueKey('displayNameInput'),
                        controller: _controller,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.name],
                        onChanged: (value) {
                          final canContinue = value.trim().isNotEmpty;
                          if (canContinue != _canContinue) {
                            setState(() => _canContinue = canContinue);
                          }
                        },
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: isArabic ? 'اسمك' : 'Your name',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppButton(
                        key: const ValueKey('displayNameContinue'),
                        label: isArabic ? 'متابعة' : 'Continue',
                        onPressed: _canContinue ? _submit : null,
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

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }
}
