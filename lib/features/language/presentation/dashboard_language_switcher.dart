import 'package:diet_time/features/language/presentation/language_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardLanguageSwitcher extends ConsumerWidget {
  const DashboardLanguageSwitcher({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageControllerProvider).languageCode;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final item in [('en', 'English'), ('ar', 'العربية')]) ...[
          if (item.$1 == 'ar') const Text('|'),
          TextButton(
            key: ValueKey('dashboardLanguage-${item.$1}'),
            onPressed: () => ref
                .read(languageControllerProvider.notifier)
                .setLocale(Locale(item.$1)),
            child: Text(
              item.$2,
              style: TextStyle(
                fontWeight: language == item.$1
                    ? FontWeight.w800
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
