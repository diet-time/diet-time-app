import 'package:diet_time/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all Material button families include the metallic finish', () {
    final theme = AppTheme.light(const Locale('en'));

    expect(theme.filledButtonTheme.style?.backgroundBuilder, isNotNull);
    expect(theme.elevatedButtonTheme.style?.backgroundBuilder, isNotNull);
    expect(theme.outlinedButtonTheme.style?.backgroundBuilder, isNotNull);
    expect(theme.textButtonTheme.style?.backgroundBuilder, isNotNull);
  });
}
