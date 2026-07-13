import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const englishFontFamily = 'Manrope';
  static const arabicFontFamily = 'Almarai';

  static String familyFor(Locale locale) =>
      locale.languageCode == 'ar' ? arabicFontFamily : englishFontFamily;

  static const display = TextStyle(
    fontSize: 34,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
  );
  static const title = TextStyle(
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.35,
  );
  static const body = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const label = TextStyle(
    fontSize: 15,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );
  static const caption = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
}
