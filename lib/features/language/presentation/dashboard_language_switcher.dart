import 'package:diet_time/features/language/presentation/language_controller.dart';
import 'package:diet_time/features/language/presentation/language_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardLanguageSwitcher extends ConsumerWidget {
  const DashboardLanguageSwitcher({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => LanguageDropdown(
    keyPrefix: 'dashboard',
    languageCode: ref.watch(languageControllerProvider).languageCode,
    onSelected: (language) => ref
        .read(languageControllerProvider.notifier)
        .setLocale(Locale(language)),
  );
}
