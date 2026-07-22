import 'dart:async';

import 'package:diet_time/app/localization/localization_service.dart';
import 'package:diet_time/features/language/data/language_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final languageControllerProvider = NotifierProvider<LanguageController, Locale>(
  LanguageController.new,
);

class LanguageController extends Notifier<Locale> {
  @override
  Locale build() {
    unawaited(_restoreLanguage());
    return const Locale('en');
  }

  Future<void> _restoreLanguage() async {
    try {
      final languageCode = await ref
          .read(languageRepositoryProvider)
          .loadPreferredLanguage();
      if (languageCode != null &&
          LocalizationService.isSupported(languageCode)) {
        state = LocalizationService.localeFor(languageCode);
      }
    } catch (_) {
      // The app remains usable with its English fallback.
    }
  }

  Future<void> selectLanguage(String languageCode) async {
    if (!LocalizationService.isSupported(languageCode)) return;
    state = LocalizationService.localeFor(languageCode);
    await ref
        .read(languageRepositoryProvider)
        .savePreferredLanguage(languageCode);
  }

  void setLocale(Locale locale) {
    unawaited(selectLanguage(locale.languageCode).catchError((_) {}));
  }
}
