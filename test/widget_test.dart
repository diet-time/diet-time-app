import 'package:diet_time/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('first launch opens onboarding and Menu reaches landing', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await tester.pump(const Duration(milliseconds: 5700));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Healthy Meals,'), findsOneWidget);
    expect(find.text('Made Simple.'), findsOneWidget);

    for (var index = 0; index < 5; index++) {
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(milliseconds: 700));
    }
    await tester.pump(const Duration(milliseconds: 2200));

    expect(find.text('Better Together,'), findsOneWidget);
    expect(find.text('Start your Plan'), findsOneWidget);

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    expect(find.text('Eat Well, Feel Great'), findsOneWidget);
  });

  testWidgets('wide login layout renders without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: DietTimeApp()));
    await tester.pump(const Duration(milliseconds: 5700));
    await tester.pump(const Duration(milliseconds: 400));

    for (var index = 0; index < 5; index++) {
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(milliseconds: 700));
    }
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

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

    for (var index = 0; index < 5; index++) {
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(milliseconds: 700));
    }
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

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
