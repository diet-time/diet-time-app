import 'package:intl/intl.dart';
import 'package:diet_time/core/network/api_client.dart';
import 'package:diet_time/core/storage/secure_storage_service.dart';
import 'package:diet_time/features/personalization/presentation/personalization_controller.dart';
import 'dart:async';

import 'package:diet_time/app/localization/localization_service.dart';
import 'package:diet_time/features/language/data/language_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final languageControllerProvider = NotifierProvider<LanguageController, Locale>(
  LanguageController.new,
);

class LanguageController extends Notifier<Locale> {
  bool _selected = false;
  Future<void> _pendingSync = Future.value();
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
      if (!_selected &&
          languageCode != null &&
          LocalizationService.isSupported(languageCode)) {
        Intl.defaultLocale = languageCode;
        state = LocalizationService.localeFor(languageCode);
      }
    } catch (_) {
      // The app remains usable with its English fallback.
    }
  }

  Future<void> selectLanguage(String languageCode) async {
    if (!LocalizationService.isSupported(languageCode)) return;
    _selected = true;
    Intl.defaultLocale = languageCode;
    state = LocalizationService.localeFor(languageCode);
    ref
        .read(personalizationControllerProvider.notifier)
        .setPreferredLanguage(languageCode);
    await ref
        .read(languageRepositoryProvider)
        .savePreferredLanguage(languageCode);
    _pendingSync = _pendingSync.catchError((_) {}).then((_) async {
      try {
        final token = await ref
            .read(secureStorageServiceProvider)
            .read(SecureStorageService.accessTokenKey);
        if (token?.isNotEmpty != true) return;
        await ref
            .read(apiClientProvider)
            .request(
              method: "PATCH",
              path: "/api/v1/customer/profile/preferred-language",
              headers: {"Authorization": "Bearer $token"},
              body: {"language": languageCode},
            );
      } catch (_) {
        // The locally saved choice remains effective when offline or signed out.
      }
    });
  }

  void setLocale(Locale locale) {
    unawaited(selectLanguage(locale.languageCode).catchError((_) {}));
  }
}
