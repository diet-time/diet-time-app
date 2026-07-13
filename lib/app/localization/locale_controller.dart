import 'dart:async';

import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  static const _localeStorageKey = 'selected_locale';

  @override
  Locale build() {
    unawaited(_restoreLocale());
    return const Locale('en');
  }

  Future<void> _restoreLocale() async {
    try {
      final languageCode = await ref
          .read(secureStorageServiceProvider)
          .read(_localeStorageKey);
      if (languageCode == 'en' || languageCode == 'ar') {
        state = Locale(languageCode!);
      }
    } catch (_) {
      // Keep the default locale when secure storage is unavailable.
    }
  }

  void setLocale(Locale locale) {
    if (locale.languageCode == 'en' || locale.languageCode == 'ar') {
      state = locale;
      unawaited(_persistLocale(locale.languageCode));
    }
  }

  Future<void> _persistLocale(String languageCode) async {
    try {
      await ref
          .read(secureStorageServiceProvider)
          .write(_localeStorageKey, languageCode);
    } catch (_) {
      // The in-memory locale still changes immediately.
    }
  }
}
