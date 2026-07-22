import 'package:flutter/material.dart';

abstract final class LocalizationService {
  static const supportedLanguageCodes = {'en', 'ar'};

  static bool isSupported(String languageCode) =>
      supportedLanguageCodes.contains(languageCode);

  static Locale localeFor(String languageCode) {
    if (!isSupported(languageCode)) return const Locale('en');
    return Locale(languageCode);
  }
}
