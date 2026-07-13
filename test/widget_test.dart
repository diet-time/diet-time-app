import 'package:diet_time/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('launch opens landing page and login panel on demand', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await tester.pump(const Duration(milliseconds: 5700));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Eat Well, Feel Great'), findsOneWidget);
    expect(find.text('The Plans'), findsOneWidget);
    expect(find.text('Welcome Back'), findsNothing);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('wide login layout renders without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await tester.pump(const Duration(milliseconds: 5700));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Eat Well, Feel Great'), findsOneWidget);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('language toggle updates all landing content immediately', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await tester.pump(const Duration(milliseconds: 5700));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('العربية'));
    await tester.pump();

    expect(find.text('صحي'), findsOneWidget);
    expect(find.text('رحلتك تبدأ هنا.'), findsOneWidget);
    expect(find.text('كل جيد، اشعر رائع'), findsOneWidget);
    expect(find.text('الخطط'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
  });
}
