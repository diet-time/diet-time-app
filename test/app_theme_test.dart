import 'package:diet_time/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all Material button families use a matte finish', () {
    final theme = AppTheme.light(const Locale('en'));

    for (final style in [
      theme.filledButtonTheme.style,
      theme.elevatedButtonTheme.style,
      theme.outlinedButtonTheme.style,
      theme.textButtonTheme.style,
    ]) {
      expect(style?.backgroundBuilder, isNull);
      expect(style?.surfaceTintColor?.resolve({}), Colors.transparent);
      expect(style?.elevation?.resolve({WidgetState.pressed}), 0);
      expect(style?.side?.resolve({})?.color.a, lessThan(1));
    }
  });
}
